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
    
    private let linksSubject = BehaviorRelay<[LinkMetadata]>(value: []) // 링크 목록
    private let isLoadingSubject = BehaviorRelay<Bool>(value: false)    // 로딩 상태
    
    var links: Observable<[LinkMetadata]> {
        return linksSubject.asObservable()
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
            let now = Date()
            let threeDaysLater = Calendar.current.date(byAdding: .day, value: 3, to: now)!
            
            return links.filter { link in
                guard let dueDate = link.dueDate else { return false }
                return dueDate >= now && dueDate <= threeDaysLater
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
                
                let metadata = LinkMetadata(url: url, title: linkList.title, description: linkList.memo, thumbnailImage: nil, categories: categoryInfos, dueDate: linkList.deadline, createdAt: linkList.date, isLiked: linkList.likeStatus)
                
                allLinks.append(metadata)
                linkCache[linkList.url] = metadata
                
                // 백그라운드에서 썸네일 로드
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
        
        linksSubject.accept(allLinks)
    }
    
    func addLink(url: URL, title: String? = nil, descrpition: String? = nil, categories: [(name: String, colorIndex: Int)]? = nil, dueDate: Date? = nil) -> Observable<LinkMetadata> {
        
        let cacheKey = url.absoluteString
        
        // 캐시에서 확인
        if let cachedLink = linkCache[cacheKey] {
            var updatedLink = cachedLink
            if let title = title, !title.isEmpty {
                updatedLink = LinkMetadata(url: updatedLink.url, title: title, description: updatedLink.description, thumbnailImage: updatedLink.thumbnailImage, categories: categories ?? updatedLink.categories, dueDate: dueDate ?? updatedLink.dueDate, createdAt: updatedLink.createdAt, isLiked: updatedLink.isLiked)
                linkCache[cacheKey] = updatedLink
            }
            
            updateLinksArray(with: updatedLink)
            return Observable.just(updatedLink)
        }
        
        // 새로운 링크 메타데이터 가져오기
        return fetchLinkMetadata(for: url)
            .do(onNext: { [weak self] metadata in
                guard let self = self else { return }
                
                let linkMetadata = LinkMetadata(url: url, title: title ?? metadata.title, description: descrpition ?? metadata.description, thumbnailImage: metadata.thumbnailImage, categories: categories, dueDate: dueDate, createdAt: Date(), isLiked: false)
                
                // 캐시에 저장
                self.linkCache[cacheKey] = linkMetadata
                self.updateLinksArray(with: linkMetadata)
            })
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
    
    func fetchLinkMetadata(for url: URL) -> Observable<LinkMetadata> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
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
                // provider 작업 취소 로직 (필요시)
            }
        }
        .observe(on: MainScheduler.instance)
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
