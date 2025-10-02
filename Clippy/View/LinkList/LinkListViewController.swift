//
//  LinkListViewController.swift
//  Clippy
//
//  Created by Jimin on 9/26/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class LinkListViewController: BaseViewController {
    
    enum Mode {
        case category(String)
        case expiring
    }
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var loadDisposeBag = DisposeBag()
    private let repository = CategoryRepository()
    private let links = BehaviorRelay<[LinkMetadata]>(value: [])
    var categoryName: String
    private let mode: Mode
    
    init(categoryName: String) {
        self.categoryName = categoryName
        self.mode = .category(categoryName)
        super.init(nibName: nil, bundle: nil)
    }
    
    init(mode: Mode) {
        switch mode {
        case .category(let name):
            self.categoryName = name
        case .expiring:
            self.categoryName = "마감 임박"
        }
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Components
    private let tableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 156
        tableView.register(LinkTableViewCell.self, forCellReuseIdentifier: LinkTableViewCell.identifier)
        return tableView
    }()
    
    private let floatingAddButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 8
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let emptyView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private let emptyLabel = {
        let label = UILabel()
        label.text = "저장된 링크가 없습니다"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLinks()
    }
    
    // MARK: - Configuration
    private func loadLinks() {
        // 기존 구독 정리
        loadDisposeBag = DisposeBag()
        
        switch mode {
        case .category(let categoryName):
            loadCategoryLinks(categoryName: categoryName)
        case .expiring:
            loadExpiringLinks()
        }
    }
    
    private func loadCategoryLinks(categoryName: String) {
        guard let category = repository.readCategory(name: categoryName) else {
            links.accept([])
            return
        }
        
        let colorIndex = category.colorIndex
        let sortedLinks = category.category.sorted(by: { $0.date > $1.date })
        
        var linkMetadataList: [LinkMetadata] = []
        
        for linkItem in sortedLinks {
            guard let url = URL(string: linkItem.url) else { continue }
            
            // 일단 기본 메타데이터 추가
            let metadata = LinkMetadata(
                url: url,
                title: linkItem.title,
                description: linkItem.memo,
                thumbnailImage: nil,
                categories: [(name: categoryName, colorIndex: colorIndex)],
                dueDate: linkItem.deadline,
                createdAt: linkItem.date,
                isLiked: linkItem.likeStatus
            )
            linkMetadataList.append(metadata)
            
            // 썸네일 로드 (캐시된 이미지가 있으면 즉시 반환됨)
            LinkManager.shared.fetchLinkMetadata(for: url)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] fetchedMetadata in
                    guard let self = self else { return }
                    
                    let updatedMetadata = LinkMetadata(
                        url: url,
                        title: linkItem.title,
                        description: linkItem.memo,
                        thumbnailImage: fetchedMetadata.thumbnailImage,
                        categories: [(name: categoryName, colorIndex: colorIndex)],
                        dueDate: linkItem.deadline,
                        createdAt: linkItem.date,
                        isLiked: linkItem.likeStatus
                    )
                    
                    var currentLinks = self.links.value
                    if let index = currentLinks.firstIndex(where: { $0.url == url }) {
                        currentLinks[index] = updatedMetadata
                        self.links.accept(currentLinks)
                    }
                })
                .disposed(by: loadDisposeBag)
        }
        
        links.accept(linkMetadataList)
    }
    
    private func loadExpiringLinks() {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let threeDaysLater = calendar.date(byAdding: .day, value: 3, to: startOfToday)!
        
        let categories = repository.readCategoryList()
        var linkMetadataList: [LinkMetadata] = []
        var processedURLs = Set<String>()
        
        for category in categories {
            for linkItem in category.category {
                guard let url = URL(string: linkItem.url),
                      !processedURLs.contains(linkItem.url) else { continue }
                
                // 마감일 필터링
                if let deadline = linkItem.deadline {
                    let startOfDeadline = calendar.startOfDay(for: deadline)
                    guard startOfDeadline >= startOfToday && startOfDeadline <= threeDaysLater else { continue }
                } else {
                    continue // 마감일 없으면 제외
                }
                
                processedURLs.insert(linkItem.url)
                
                let categoryInfos = linkItem.parentCategory.map { (name: $0.name, colorIndex: $0.colorIndex) }
                
                // 일단 기본 메타데이터 추가
                let metadata = LinkMetadata(
                    url: url,
                    title: linkItem.title,
                    description: linkItem.memo,
                    thumbnailImage: nil,
                    categories: Array(categoryInfos),
                    dueDate: linkItem.deadline,
                    createdAt: linkItem.date,
                    isLiked: linkItem.likeStatus
                )
                linkMetadataList.append(metadata)
                
                // 썸네일 로드 (캐시된 이미지가 있으면 즉시 반환됨)
                LinkManager.shared.fetchLinkMetadata(for: url)
                    .observe(on: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] fetchedMetadata in
                        guard let self = self else { return }
                        
                        let updatedMetadata = LinkMetadata(
                            url: url,
                            title: linkItem.title,
                            description: linkItem.memo,
                            thumbnailImage: fetchedMetadata.thumbnailImage,
                            categories: Array(categoryInfos),
                            dueDate: linkItem.deadline,
                            createdAt: linkItem.date,
                            isLiked: linkItem.likeStatus
                        )
                        
                        var currentLinks = self.links.value
                        if let index = currentLinks.firstIndex(where: { $0.url == url }) {
                            currentLinks[index] = updatedMetadata
                            self.links.accept(currentLinks)
                        }
                    })
                    .disposed(by: loadDisposeBag)
            }
        }
        
        // 마감일 빠른 순으로 정렬
        linkMetadataList.sort { link1, link2 in
            guard let date1 = link1.dueDate, let date2 = link2.dueDate else { return false }
            return date1 < date2
        }
        
        links.accept(linkMetadataList)
    }
    
    override func bind() {
        floatingAddButton.rx.tap
            .bind(with: self) { owner, _ in
                let editVC = EditLinkViewController()
                editVC.defaultCategoryName = owner.categoryName
                editVC.onLinkCreated = { [weak owner] in
                    owner?.loadLinks()
                }
                owner.present(UINavigationController(rootViewController: editVC), animated: true)
            }
            .disposed(by: disposeBag)
        
        links
            .bind(to: tableView.rx.items(cellIdentifier: LinkTableViewCell.identifier, cellType: LinkTableViewCell.self)) { [weak self] _, item, cell in
                guard let self = self else { return }
                cell.configure(with: item)
                
                cell.heartTapHandler = {
                    LinkManager.shared.toggleLike(for: item.url)
                        .bind(with: self) { owner, _ in
                            var currentLinks = owner.links.value
                            if let index = currentLinks.firstIndex(where: { $0.url == item.url }) {
                                // 좋아요 상태만 토글
                                let updatedItem = currentLinks[index]
                                let newMetadata = LinkMetadata(url: updatedItem.url, title: updatedItem.title, description: updatedItem.description, thumbnailImage: updatedItem.thumbnailImage, categories: updatedItem.categories, dueDate: updatedItem.dueDate, createdAt: updatedItem.createdAt, isLiked: !updatedItem.isLiked)
                                currentLinks[index] = newMetadata
                                owner.links.accept(currentLinks)
                            }
                        }
                        .disposed(by: cell.disposeBag)
                }
                
                cell.shareTapHandler = { [weak self] in
                    let activityViewController = UIActivityViewController(activityItems: [item.url], applicationActivities: nil)
                    self?.present(activityViewController, animated: true)
                }
            }
            .disposed(by: disposeBag)
        
        // 빈 상태 처리
        links
            .map { !$0.isEmpty }
            .bind(to: emptyView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // 링크 선택 시 Safari에서 열기
        tableView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .withLatestFrom(links) { indexPath, links in
                links[indexPath.row]
            }
            .bind(with: self) { owner, link in
                if UIApplication.shared.canOpenURL(link.url) {
                    UIApplication.shared.open(link.url, options: [:], completionHandler: nil)
                }
            }
            .disposed(by: disposeBag)
        
        // 링크 생성 알림 받기
        NotificationCenter.default.rx
            .notification(.linkDidCreate)
            .bind(with: self) { owner, _ in
                owner.loadLinks()
            }
            .disposed(by: disposeBag)
    }
    
    override func configureHierarchy() {
        [tableView, emptyView, floatingAddButton].forEach { view.addSubview($0) }
        emptyView.addSubview(emptyLabel)
    }
    
    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        floatingAddButton.snp.makeConstraints { make in
            make.size.equalTo(56)
            make.trailing.equalToSuperview().offset(-26)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-38)
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.title = categoryName
        navigationController?.navigationBar.tintColor = .black
        loadLinks()
    }
}
