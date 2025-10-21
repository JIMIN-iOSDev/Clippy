//
//  LinkManager.swift
//  Clippy
//
//  Created by Jimin on 9/27/25.
//

import Foundation
import RxSwift
import RxCocoa
import LinkPresentation
import UserNotifications

final class LinkManager {

    static let shared = LinkManager()

    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let repository: CategoryRepositoryProtocol

    /// DI를 위한 Initializer
    /// - Parameter repository: CategoryRepositoryProtocol을 구현한 객체 (기본값: CategoryRepository)
    init(repository: CategoryRepositoryProtocol = CategoryRepository()) {
        self.repository = repository
        loadLinksFromRealm()
        setupCategoryNotifications()
    }
    
    private var linkCache: [String: LinkMetadata] = [:] // 캐시
    private var imageCache: [String: UIImage] = [:] // 이미지 캐시
    private let imageCacheQueue = DispatchQueue(label: "com.clippy.imageCache", attributes: .concurrent)
    
    private let linksSubject = BehaviorRelay<[LinkMetadata]>(value: []) // 링크 목록
    private let isLoadingSubject = BehaviorRelay<Bool>(value: false)    // 로딩 상태
    
    var links: Observable<[LinkMetadata]> {
        return linksSubject.asObservable()
    }
    
    var currentLinks: [LinkMetadata] {
        return linksSubject.value
    }
    
    var recentLinks: Observable<[LinkMetadata]> {
        return links.map { links in
            Array(links.sorted { $0.createdAt > $1.createdAt }.prefix(10))
        }
    }
    
    var savedLinksCount: Observable<Int> {
        return links.map { $0.count }
    }
    
    var expiredLinksCount: Observable<Int> {    // 마감 3일 남은 거부터 임박
        return links.map { links in
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let threeDaysLater = calendar.date(byAdding: .day, value: 3, to: startOfToday)!
            
            return links.filter { link in
                guard let dueDate = link.dueDate else { return false }
                let startOfDueDate = calendar.startOfDay(for: dueDate)
                // 오늘부터 3일 후까지 포함
                return startOfDueDate >= startOfToday && startOfDueDate <= threeDaysLater
            }.count
        }
    }
    
    var isLoading: Observable<Bool> {
        return isLoadingSubject.asObservable()
    }
    
    // MARK: - Methods
    
    func refreshLinks() {
        // 캐시 클리어
        linkCache.removeAll()
        imageCache.removeAll()
        
        // Realm에서 다시 로드
        loadLinksFromRealm()
    }
    
    private func loadLinksFromRealm() {
        let categories = repository.readCategoryList()
        var allLinks: [LinkMetadata] = []
        var urlToCategories: [String : [(name: String, colorIndex: Int)]] = [:]
        
        categories.forEach { category in
            category.category.forEach { linkList in
                let urlString = linkList.url
                if urlToCategories[urlString] == nil {
                    urlToCategories[urlString] = []
                }
                urlToCategories[urlString]?.append((name: category.name, colorIndex: category.colorIndex))
            }
        }
        
        // URL별로 고유한 링크만 처리 (중복 제거)
        var processedURLs = Set<String>()
        
        categories.forEach { category in
            category.category.forEach { linkList in
                // 이미 처리된 URL인지 확인
                if processedURLs.contains(linkList.url) { return }
                
                guard let url = URL(string: linkList.url),
                      let categoryInfos = urlToCategories[linkList.url] else { return }
                
                // 캐시된 이미지가 있으면 바로 사용, 없으면 기본 앱 로고 사용
                let cachedImage = getCachedImage(for: linkList.url)
                let thumbnailImage = cachedImage ?? UIImage(named: "AppLogo")
                let metadata = LinkMetadata(url: url, title: linkList.title, userMemo: linkList.userMemo, metadataDescription: linkList.metadataDescription, thumbnailImage: thumbnailImage, categories: categoryInfos, dueDate: linkList.deadline, createdAt: linkList.date, isLiked: linkList.likeStatus, isOpened: linkList.isOpened)
                
                allLinks.append(metadata)
                linkCache[linkList.url] = metadata
                processedURLs.insert(linkList.url)
                
                // 캐시된 이미지가 없으면 백그라운드에서 썸네일 로드
                if cachedImage == nil {
                    fetchLinkMetadata(for: url)
                        .bind(with: self) { owner, fetchedMetadata in
                            // 썸네일만 업데이트
                            let updatedMetadata = LinkMetadata(url: url, title: linkList.title, userMemo: linkList.userMemo, metadataDescription: linkList.metadataDescription, thumbnailImage: fetchedMetadata.thumbnailImage, categories: categoryInfos, dueDate: linkList.deadline, createdAt: linkList.date, isLiked: linkList.likeStatus, isOpened: linkList.isOpened)

                            owner.linkCache[linkList.url] = updatedMetadata
                            owner.updateLinksArray(with: updatedMetadata)
                        }
                        .disposed(by: disposeBag)
                }
            }
        }
        
        linksSubject.accept(allLinks)
    }
    
    func addLink(url: URL, title: String? = nil, userMemo: String? = nil, metadataDescription: String? = nil, categories: [(name: String, colorIndex: Int)]? = nil, dueDate: Date? = nil, thumbnailImage: UIImage? = nil, isLiked: Bool = false, isOpened: Bool = false, openCount: Int = 0, createdAt: Date? = nil) -> Observable<LinkMetadata> {

        let cacheKey = url.absoluteString

        // 메타데이터 생성
        let linkMetadata = LinkMetadata(
            url: url,
            title: title ?? url.absoluteString,
            userMemo: userMemo,
            metadataDescription: metadataDescription,
            thumbnailImage: thumbnailImage,
            categories: categories,
            dueDate: dueDate,
            createdAt: createdAt ?? Date(),
            isLiked: isLiked,
            isOpened: isOpened
        )
        
        // 캐시에 저장
        linkCache[cacheKey] = linkMetadata
        updateLinksArray(with: linkMetadata)
        
        // 마감일이 있으면 알림 설정
        if let dueDate = dueDate {
            NotificationManager.shared.scheduleNotificationForLink(
                title: linkMetadata.title,
                dueDate: dueDate,
                linkId: cacheKey
            )
        }
        
        return Observable.just(linkMetadata)
    }
    
    func toggleLike(for url: URL) -> Observable<LinkMetadata?> {
        let cacheKey = url.absoluteString

        guard let linkMetadata = linkCache[cacheKey] else {
            return Observable.just(nil)
        }

        repository.toggleLikeStatus(url: cacheKey)

        let updatedLink = LinkMetadata(url: linkMetadata.url, title: linkMetadata.title, userMemo: linkMetadata.userMemo, metadataDescription: linkMetadata.metadataDescription, thumbnailImage: linkMetadata.thumbnailImage, categories: linkMetadata.categories, dueDate: linkMetadata.dueDate, createdAt: linkMetadata.createdAt, isLiked: !linkMetadata.isLiked, isOpened: linkMetadata.isOpened)

        linkCache[cacheKey] = updatedLink
        updateLinksArray(with: updatedLink)

        return Observable.just(updatedLink)
    }
    
    func toggleOpened(for url: URL) -> Observable<LinkMetadata?> {
        let cacheKey = url.absoluteString

        guard let linkMetadata = linkCache[cacheKey] else {
            return Observable.just(nil)
        }

        repository.toggleOpenedStatus(url: cacheKey)

        let updatedLink = LinkMetadata(url: linkMetadata.url, title: linkMetadata.title, userMemo: linkMetadata.userMemo, metadataDescription: linkMetadata.metadataDescription, thumbnailImage: linkMetadata.thumbnailImage, categories: linkMetadata.categories, dueDate: linkMetadata.dueDate, createdAt: linkMetadata.createdAt, isLiked: linkMetadata.isLiked, isOpened: !linkMetadata.isOpened)

        linkCache[cacheKey] = updatedLink
        updateLinksArray(with: updatedLink)

        return Observable.just(updatedLink)
    }
    
    func deleteLink(url: URL) -> Observable<Bool> {
        let cacheKey = url.absoluteString
        
        // 관련 알림 취소
        NotificationManager.shared.cancelNotificationForLink(linkId: cacheKey)
        
        // 링크 캐시와 이미지 캐시 모두 삭제
        linkCache.removeValue(forKey: cacheKey)
        imageCacheQueue.async(flags: .barrier) { [weak self] in
            self?.imageCache.removeValue(forKey: cacheKey)
        }
        
        var currentLinks = linksSubject.value
        currentLinks.removeAll { $0.url.absoluteString == cacheKey }
        linksSubject.accept(currentLinks)
        
        // 링크 삭제 알림 발생
        NotificationCenter.default.post(name: .linkDidDelete, object: nil)
        
        return Observable.just(true)
    }
    
    // MARK: - 더미링크 관리 (스와이프 안내용)
    func createDummyLinkForSwipeGuide() -> Observable<LinkMetadata> {
        // 더미 URL 생성
        let dummyURL = URL(string: "https://clippy.dummy.swipe.guide")!
        
        // 더미 이미지 생성 (나중에 로고 이미지로 교체)
        let dummyImage = createDummyThumbnail()
        
        // 더미링크 메타데이터 생성
        let dummyLink = LinkMetadata(
            url: dummyURL,
            title: "📝 스와이프 가이드",
            userMemo: nil,
            metadataDescription: "좌우 스와이프 기능",
            thumbnailImage: dummyImage,
            categories: [("일반", 0)],
            dueDate: nil,
            createdAt: Date(),
            isLiked: false
        )
        
        // 캐시에 저장하고 링크 목록 업데이트
        linkCache[dummyURL.absoluteString] = dummyLink
        updateLinksArray(with: dummyLink)
        
        return Observable.just(dummyLink)
    }
    
    func deleteDummyLinkForSwipeGuide() {
        let dummyURL = URL(string: "https://clippy.dummy.swipe.guide")!
        let cacheKey = dummyURL.absoluteString
        
        linkCache.removeValue(forKey: cacheKey)
        
        var currentLinks = linksSubject.value
        currentLinks.removeAll { $0.url.absoluteString == cacheKey }
        linksSubject.accept(currentLinks)
        
        // 더미링크 삭제 알림 발생
        NotificationCenter.default.post(name: .linkDidDelete, object: nil)
    }
    
    private func createDummyThumbnail() -> UIImage {
        let size = CGSize(width: 80, height: 80)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 그라데이션 배경
            let colors = [
                UIColor.clippyBlue.cgColor,
                UIColor.systemPurple.cgColor
            ]
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: colors as CFArray,
                locations: [0.0, 1.0]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // 클립 아이콘 추가
            let clipIcon = UIImage(systemName: "paperclip")!
            let iconSize = CGSize(width: 30, height: 30)
            let iconRect = CGRect(
                x: (size.width - iconSize.width) / 2,
                y: (size.height - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            )
            
            clipIcon.draw(in: iconRect)
        }
    }
    
    func fetchLinkMetadata(for url: URL) -> Observable<LinkMetadata> {
        let urlString = url.absoluteString
        
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 이미지 캐시 확인
            if let cachedImage = self.getCachedImage(for: urlString) {
                let cachedMetadata = LinkMetadata(url: url, title: url.absoluteString, userMemo: nil, metadataDescription: nil, thumbnailImage: cachedImage)
                observer.onNext(cachedMetadata)
                observer.onCompleted()
                return Disposables.create()
            }
            
            self.isLoadingSubject.accept(true)
            
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metadata, error in
                defer {
                    self.isLoadingSubject.accept(false)
                }
                
                if let error {
                    // LPMetadataProvider 실패 시 대안 방법: URL에서 도메인 추출하여 제목 생성
                    let fallbackTitle = self.generateFallbackTitle(from: url)
                    let defaultImage = UIImage(named: "AppLogo")
                    let fallbackMetadata = LinkMetadata(url: url, title: fallbackTitle, userMemo: nil, metadataDescription: nil, thumbnailImage: defaultImage)

                    observer.onNext(fallbackMetadata)
                    observer.onCompleted()
                    return
                }

                guard let metadata else {
                    // 메타데이터가 없어도 기본 앱 로고와 함께 제공
                    let defaultImage = UIImage(named: "AppLogo")
                    let basicMetadata = LinkMetadata(url: url, title: url.absoluteString, userMemo: nil, metadataDescription: nil, thumbnailImage: defaultImage)
                    observer.onNext(basicMetadata)
                    observer.onCompleted()
                    return
                }

                let extractedTitle = metadata.title ?? url.absoluteString
                let extractedDescription = metadata.value(forKey: "summary") as? String
                
                // 이미지 로드
                if let imageProvider = metadata.imageProvider {
                    imageProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        let finalImage: UIImage?
                        if let image = image as? UIImage {
                            // 이미지 캐시에 저장
                            self.cacheImage(image, for: urlString)
                            finalImage = image
                        } else {
                            // 이미지 로드 실패시 기본 앱 로고 사용
                            finalImage = UIImage(named: "AppLogo")
                        }
                        let linkMetadata = LinkMetadata(url: url, title: extractedTitle, userMemo: nil, metadataDescription: extractedDescription, thumbnailImage: finalImage)
                        observer.onNext(linkMetadata)
                        observer.onCompleted()
                    }
                } else {
                    // 썸네일 이미지가 없으면 기본 앱 로고 사용
                    let defaultImage = UIImage(named: "AppLogo")
                    let linkMetadata = LinkMetadata(url: url, title: extractedTitle, userMemo: nil, metadataDescription: extractedDescription, thumbnailImage: defaultImage)
                    observer.onNext(linkMetadata)
                    observer.onCompleted()
                }
            }
            
            return Disposables.create {
                provider.cancel()
            }
        }
        .observe(on: MainScheduler.instance)
    }
    
    // MARK: - Fallback Methods
    
    private func generateFallbackTitle(from url: URL) -> String {
        let host = url.host ?? "알 수 없는 사이트"
        
        // 주요 사이트별 한글 이름 매핑
        let siteNames: [String: String] = [
            "www.naver.com": "네이버",
            "m.naver.com": "네이버",
            "naver.com": "네이버",
            "www.daum.net": "다음",
            "m.daum.net": "다음",
            "daum.net": "다음",
            "www.google.com": "구글",
            "google.com": "구글",
            "www.youtube.com": "유튜브",
            "youtube.com": "유튜브",
            "m.youtube.com": "유튜브",
            "www.facebook.com": "페이스북",
            "facebook.com": "페이스북",
            "m.facebook.com": "페이스북",
            "www.instagram.com": "인스타그램",
            "instagram.com": "인스타그램",
            "www.twitter.com": "트위터",
            "twitter.com": "트위터",
            "x.com": "X (트위터)",
            "www.github.com": "깃허브",
            "github.com": "깃허브"
        ]
        
        // 도메인에서 www. 제거
        let cleanHost = host.replacingOccurrences(of: "www.", with: "")
        
        if let koreanName = siteNames[cleanHost] {
            return koreanName
        } else {
            // 도메인 이름에서 첫 번째 부분만 사용 (예: example.com -> example)
            let components = cleanHost.components(separatedBy: ".")
            if let firstComponent = components.first, !firstComponent.isEmpty {
                return firstComponent.capitalized
            } else {
                return "링크"
            }
        }
    }
    
    // MARK: - Image Cache Methods
    private func cacheImage(_ image: UIImage, for urlString: String) {
        imageCacheQueue.async(flags: .barrier) { [weak self] in
            self?.imageCache[urlString] = image
        }
    }
    
    
    private func getCachedImage(for urlString: String) -> UIImage? {
        var cachedImage: UIImage?
        imageCacheQueue.sync {
            cachedImage = imageCache[urlString]
        }
        return cachedImage
    }
    
    func reloadFromRealm() {
        linkCache.removeAll()
        loadLinksFromRealm()
    }
    
    private func updateLinksArray(with linkMetadata: LinkMetadata) {
        var currentLinks = linksSubject.value
        
        // 기존 링크 업데이트 또는 새 링크 추가
        if let index = currentLinks.firstIndex(where: { $0.url.absoluteString == linkMetadata.url.absoluteString }) {
            currentLinks[index] = linkMetadata
        } else {
            currentLinks.append(linkMetadata)
        }
        
        // 날짜순으로 정렬
        currentLinks.sort { $0.createdAt > $1.createdAt }
        linksSubject.accept(currentLinks)
    }
    
    // MARK: - Category Notification Setup
    private func setupCategoryNotifications() {
        NotificationCenter.default.rx
            .notification(.categoryDidUpdate)
            .bind(with: self) { owner, _ in
                owner.loadLinksFromRealm() // 카테고리 정보가 변경되면 링크 데이터도 새로고침
            }
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.categoryDidDelete)
            .bind(with: self) { owner, _ in
                owner.loadLinksFromRealm() // 카테고리 삭제 시 링크 데이터도 새로고침
            }
            .disposed(by: disposeBag)
    }
}
