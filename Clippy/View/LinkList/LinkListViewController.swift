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
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let repository = CategoryRepository()
    private let links = BehaviorRelay<[LinkMetadata]>(value: [])
    var categoryName: String
    
    init(categoryName: String) {
        self.categoryName = categoryName
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
        guard let category = repository.readCategory(name: categoryName) else {
            links.accept([])
            return
        }
        
        let categoryName = self.categoryName
        let colorIndex = category.colorIndex
        
        let sortedLinks = category.category.sorted(by: { $0.date > $1.date })
        
        // 먼저 썸네일 없는 버전으로 초기화
        var linkMetadataList: [LinkMetadata] = []
        
        for linkItem in sortedLinks {
            guard let url = URL(string: linkItem.url) else { continue }
            
            let metadata = LinkMetadata(url: url, title: linkItem.title, description: linkItem.memo, thumbnailImage: nil, categories: [(name: categoryName, colorIndex: colorIndex)], dueDate: linkItem.deadline, createdAt: linkItem.date, isLiked: linkItem.likeStatus)
            
            linkMetadataList.append(metadata)
            
            // 백그라운드에서 썸네일 로드
            LinkManager.shared.fetchLinkMetadata(for: url)
                .subscribe(onNext: { [weak self] fetchedMetadata in
                    guard let self = self else { return }
                    
                    let updatedMetadata = LinkMetadata(url: url, title: linkItem.title, description: linkItem.memo, thumbnailImage: fetchedMetadata.thumbnailImage, categories: [(name: categoryName, colorIndex: colorIndex)], dueDate: linkItem.deadline, createdAt: linkItem.date, isLiked: linkItem.likeStatus)
                    
                    var currentLinks = self.links.value
                    if let index = currentLinks.firstIndex(where: { $0.url == url }) {
                        currentLinks[index] = updatedMetadata
                        self.links.accept(currentLinks)
                    }
                })
                .disposed(by: disposeBag)
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
