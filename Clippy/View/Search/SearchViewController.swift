//
//  SearchViewController.swift
//  Clippy
//
//  Created by Jimin on 9/25/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RealmSwift

final class SearchViewController: BaseViewController {

    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let repository = CategoryRepository()

    private let allLinks = BehaviorRelay<[LinkList]>(value: []) // 전체 링크 데이터
    private let filteredLinks = BehaviorRelay<[LinkMetadata]>(value: []) // 검색 결과

    // MARK: - UI Components
    private let searchBar = {
        let sb = UISearchBar()
        sb.placeholder = "검색어를 입력하세요"
        sb.searchBarStyle = .minimal
        sb.searchTextField.font = UIFont.systemFont(ofSize: 16)
        sb.searchTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return sb
    }()

    private let tableView = {
        let table = UITableView()
        table.separatorStyle = .none
        table.backgroundColor = .systemBackground
        table.register(LinkTableViewCell.self, forCellReuseIdentifier: "LinkTableViewCell")
        return table
    }()

    private let emptyLabel = {
        let label = UILabel()
        label.text = "검색 결과가 없습니다"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.isHidden = true
        return label
    }()

    // MARK: - Configuration
    override func bind() {
        // 검색어 입력 대소문자 구분 없이
        searchBar.rx.text.orEmpty
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .withLatestFrom(allLinks) { query, links -> [LinkList] in
                guard !query.isEmpty else { return Array(links.prefix(20)) }
                return links.filter {
                    $0.title.range(of: query, options: .caseInsensitive) != nil || $0.url.range(of: query, options: .caseInsensitive) != nil
                }
                .prefix(20)
                .map { $0 }
            }
            .subscribe(onNext: { [weak self] linkListItems in
                guard let self = self else { return }
                self.convertToLinkMetadata(linkListItems: linkListItems)
            })
            .disposed(by: disposeBag)

        // 테이블뷰에 데이터 바인딩
        filteredLinks
            .observe(on: MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: "LinkTableViewCell", cellType: LinkTableViewCell.self)) { [weak self] row, linkMetadata, cell in
                guard let self = self else { return }

                cell.configure(with: linkMetadata)

                // 즐겨찾기 버튼
                cell.heartTapHandler = {
                    self.toggleLikeStatus(url: linkMetadata.url.absoluteString)
                }

                // 공유 버튼
                cell.shareTapHandler = {
                    self.shareLink(url: linkMetadata.url)
                }
            }
            .disposed(by: disposeBag)

        // 검색 결과 없을 때
        filteredLinks
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] links in
                self?.emptyLabel.isHidden = !links.isEmpty
            })
            .disposed(by: disposeBag)

        // 테이블뷰 스크롤 시 키보드 숨김
        tableView.rx.contentOffset
            .bind(with: self) { owner, _ in
                owner.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)
        
        // 링크 추가/수정 알림 받기
        NotificationCenter.default.rx
            .notification(.linkDidCreate)
            .bind(with: self) { owner, _ in
                owner.loadLinks()
            }
            .disposed(by: disposeBag)

        loadLinks()
    }

    override func configureHierarchy() {
        [searchBar, tableView, emptyLabel].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.horizontalEdges.equalToSuperview().inset(10)
            make.height.equalTo(60)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func configureView() {
        super.configureView()
    }

    private func loadLinks() {
        let categories = repository.readCategoryList()
        let allLinksArray = categories
            .flatMap { $0.category } // 모든 링크 합치기
            .sorted(by: { $0.date > $1.date })
        allLinks.accept(allLinksArray)
        convertToLinkMetadata(linkListItems: Array(allLinksArray.prefix(20)))
    }
    
    private func convertToLinkMetadata(linkListItems: [LinkList]) {
        var linkMetadataList: [LinkMetadata] = []
        
        for linkItem in linkListItems {
            guard let url = URL(string: linkItem.url) else { continue }
            
            let categories = Array(linkItem.parentCategory.map { (name: $0.name, colorIndex: $0.colorIndex) })
            
            // 일단 기본 메타데이터 추가
            let metadata = LinkMetadata(
                url: url,
                title: linkItem.title,
                description: linkItem.memo,
                thumbnailImage: nil,
                categories: categories,
                dueDate: linkItem.deadline,
                createdAt: linkItem.date,
                isLiked: linkItem.likeStatus
            )
            linkMetadataList.append(metadata)
            
            // 썸네일 로드 (캐시된 이미지가 있으면 즉시 반환됨)
            LinkManager.shared.fetchLinkMetadata(for: url)
                .subscribe(onNext: { [weak self] fetchedMetadata in
                    guard let self = self else { return }
                    
                    let updatedMetadata = LinkMetadata(
                        url: url,
                        title: linkItem.title,
                        description: linkItem.memo,
                        thumbnailImage: fetchedMetadata.thumbnailImage,
                        categories: categories,
                        dueDate: linkItem.deadline,
                        createdAt: linkItem.date,
                        isLiked: linkItem.likeStatus
                    )
                    
                    var currentLinks = self.filteredLinks.value
                    if let index = currentLinks.firstIndex(where: { $0.url == url }) {
                        currentLinks[index] = updatedMetadata
                        self.filteredLinks.accept(currentLinks)
                    }
                })
                .disposed(by: disposeBag)
        }
        
        filteredLinks.accept(linkMetadataList)
    }

    private func toggleLikeStatus(url: String) {
        guard let linkItem = allLinks.value.first(where: { $0.url == url }) else { return }
        
        do {
            let realm = try Realm()
            try realm.write {
                linkItem.likeStatus.toggle()
            }
            
            // 현재 필터링된 결과 업데이트
            var currentFiltered = filteredLinks.value
            if let index = currentFiltered.firstIndex(where: { $0.url.absoluteString == url }) {
                let oldMetadata = currentFiltered[index]
                let updatedMetadata = LinkMetadata(url: oldMetadata.url, title: oldMetadata.title, description: oldMetadata.description, thumbnailImage: oldMetadata.thumbnailImage, categories: oldMetadata.categories, dueDate: oldMetadata.dueDate, createdAt: oldMetadata.createdAt, isLiked: !oldMetadata.isLiked)
                currentFiltered[index] = updatedMetadata
                filteredLinks.accept(currentFiltered)
            }
        } catch {
            print("즐겨찾기 상태 변경 실패: \(error.localizedDescription)")
        }
    }

    private func shareLink(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = view
        present(activityVC, animated: true)
    }
}
