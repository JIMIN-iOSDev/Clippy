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

final class LinkManager {
    
    static let shared = LinkManager()
    private init() {
        loadLinksFromRealm()
    }
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let repository = CategoryRepository()
    
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
        
        categories.forEach { category in
            category.category.forEach { linkList in
                // 이미 추가된 URL 중복 방지
                if allLinks.contains(where: { $0.url.absoluteString == linkList.url }) { return }
                
                guard let url = URL(string: linkList.url),
                      let categoryInfos = urlToCategories[linkList.url] else { return }
                
                // 캐시된 이미지가 있으면 바로 사용
                let cachedImage = getCachedImage(for: linkList.url)
                let metadata = LinkMetadata(url: url, title: linkList.title, description: linkList.memo, thumbnailImage: cachedImage, categories: categoryInfos, dueDate: linkList.deadline, createdAt: linkList.date, isLiked: linkList.likeStatus)
                
                allLinks.append(metadata)
                linkCache[linkList.url] = metadata
                
                // 캐시된 이미지가 없으면 백그라운드에서 썸네일 로드
                if cachedImage == nil {
                    fetchLinkMetadata(for: url)
                        .bind(with: self) { owner, fetchedMetadata in
                            // 썸네일만 업데이트
                            let updatedMetadata = LinkMetadata(url: url, title: linkList.title, description: linkList.memo, thumbnailImage: fetchedMetadata.thumbnailImage, categories: categoryInfos, dueDate: linkList.deadline, createdAt: linkList.date, isLiked: linkList.likeStatus)
                            
                            owner.linkCache[linkList.url] = updatedMetadata
                            owner.updateLinksArray(with: updatedMetadata)
                        }
                        .disposed(by: disposeBag)
                }
            }
        }
        
        linksSubject.accept(allLinks)
    }
    
    func addLink(url: URL, title: String? = nil, descrpition: String? = nil, categories: [(name: String, colorIndex: Int)]? = nil, dueDate: Date? = nil, thumbnailImage: UIImage? = nil, isLiked: Bool = false) -> Observable<LinkMetadata> {
        
        let cacheKey = url.absoluteString
        
        // 메타데이터 생성
        let linkMetadata = LinkMetadata(
            url: url,
            title: title ?? url.absoluteString,
            description: descrpition,
            thumbnailImage: thumbnailImage,
            categories: categories,
            dueDate: dueDate,
            createdAt: Date(),
            isLiked: isLiked
        )
        
        // 캐시에 저장
        linkCache[cacheKey] = linkMetadata
        updateLinksArray(with: linkMetadata)
        
        return Observable.just(linkMetadata)
    }
    
    func toggleLike(for url: URL) -> Observable<LinkMetadata?> {
        let cacheKey = url.absoluteString
        
        guard let linkMetadata = linkCache[cacheKey] else {
            return Observable.just(nil)
        }
        
        repository.toggleLikeStatus(url: cacheKey)
        
        let updatedLink = LinkMetadata(url: linkMetadata.url, title: linkMetadata.title, description: linkMetadata.description, thumbnailImage: linkMetadata.thumbnailImage, categories: linkMetadata.categories, dueDate: linkMetadata.dueDate, createdAt: linkMetadata.createdAt, isLiked: !linkMetadata.isLiked)
        
        linkCache[cacheKey] = updatedLink
        updateLinksArray(with: updatedLink)
        
        return Observable.just(updatedLink)
    }
    
    func deleteLink(url: URL) -> Observable<Bool> {
        let cacheKey = url.absoluteString
        linkCache.removeValue(forKey: cacheKey)
        
        var currentLinks = linksSubject.value
        currentLinks.removeAll { $0.url.absoluteString == cacheKey }
        linksSubject.accept(currentLinks)
        
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
            description: "좌우 스와이프 기능",
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
    }
    
    private func createDummyThumbnail() -> UIImage {
        let size = CGSize(width: 80, height: 80)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 그라데이션 배경
            let colors = [
                UIColor.systemBlue.cgColor,
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
                let cachedMetadata = LinkMetadata(url: url, title: url.absoluteString, thumbnailImage: cachedImage)
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
                    // 에러가 있어도 기본 링크 메타데이터는 제공
                    let basicMetadata = LinkMetadata(url: url, title: url.absoluteString)
                    observer.onNext(basicMetadata)
                    observer.onCompleted()
                    return
                }
                
                guard let metadata else {
                    let basicMetadata = LinkMetadata(url: url, title: url.absoluteString)
                    observer.onNext(basicMetadata)
                    observer.onCompleted()
                    return
                }
                
                // 이미지 로드
                if let imageProvider = metadata.imageProvider {
                    imageProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        if let image = image as? UIImage {
                            // 이미지 캐시에 저장
                            self.cacheImage(image, for: urlString)
                        }
                        let linkMetadata = LinkMetadata(url: url, title: metadata.title ?? url.absoluteString, description: metadata.value(forKey: "summary") as? String, thumbnailImage: image as? UIImage)
                        observer.onNext(linkMetadata)
                        observer.onCompleted()
                    }
                } else {
                    let linkMetadata = LinkMetadata(url: url, title: metadata.title ?? url.absoluteString, description: metadata.value(forKey: "summary") as? String, thumbnailImage: nil)
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
}
