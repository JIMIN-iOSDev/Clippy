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
        case allLinks
    }
    
    enum SortType {
        case latest, title, deadline
    }
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var loadDisposeBag = DisposeBag()
    private let repository = CategoryRepository()
    private let links = BehaviorRelay<[LinkMetadata]>(value: [])
    private let allLinksCache = BehaviorRelay<[LinkMetadata]>(value: [])
    private let sortType = BehaviorRelay<SortType>(value: .latest)
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
        case .allLinks:
            self.categoryName = "저장된 링크"
        }
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Components
    private let sortButtonsStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    private let latestButton = {
        let button = UIButton(type: .system)
        button.setTitle("최근 추가순", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return button
    }()
    
    private let titleSortButton = {
        let button = UIButton(type: .system)
        button.setTitle("제목순", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return button
    }()
    
    private let deadlineSortButton = {
        let button = UIButton(type: .system)
        button.setTitle("마감일순", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return button
    }()
    
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
        case .allLinks:
            loadAllLinks()
        }
    }
    
    private func loadCategoryLinks(categoryName: String) {
        LinkManager.shared.links
            .map { allLinks in
                // 해당 카테고리에 속한 링크들만 필터링
                return allLinks.filter { link in
                    guard let categories = link.categories else { return false }
                    return categories.contains { $0.name == categoryName }
                }
                .sorted { $0.createdAt > $1.createdAt }
            }
            .bind(to: links)
            .disposed(by: loadDisposeBag)
    }
    
    private func loadExpiringLinks() {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let threeDaysLater = calendar.date(byAdding: .day, value: 3, to: startOfToday)!
        
        LinkManager.shared.links
            .map { allLinks in
                return allLinks.filter { link in
                    guard let dueDate = link.dueDate else { return false }
                    let startOfDueDate = calendar.startOfDay(for: dueDate)
                    return startOfDueDate >= startOfToday && startOfDueDate <= threeDaysLater
                }
                .sorted { link1, link2 in
                    guard let date1 = link1.dueDate, let date2 = link2.dueDate else { return false }
                    return date1 < date2
                }
            }
            .bind(to: links)
            .disposed(by: loadDisposeBag)
    }
    
    private func loadAllLinks() {
        LinkManager.shared.links
            .bind(to: allLinksCache)
            .disposed(by: loadDisposeBag)
    }
    
    private func sortLinks(_ links: [LinkMetadata], by sortType: SortType) -> [LinkMetadata] {
        switch sortType {
        case .latest:
            return links.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return links.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .deadline:
            return links.sorted { link1, link2 in
                // 마감일이 없는 링크는 뒤로
                guard let date1 = link1.dueDate else { return false }
                guard let date2 = link2.dueDate else { return true }
                return date1 < date2
            }
        }
    }
    
    private func updateSortButtonStyles(selectedType: SortType) {
        let buttons: [(UIButton, SortType)] = [(latestButton, .latest), (titleSortButton, .title), (deadlineSortButton, .deadline)]
        
        buttons.forEach { button, type in
            if type == selectedType {
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            } else {
                button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
                button.setTitleColor(.label, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            }
        }
    }
    
    override func bind() {
        // 모든 모드에 테이블뷰 delegate 설정 (스와이프 액션)
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        // allLinks 모드일 때만 정렬 버튼 바인딩
        if case .allLinks = mode {
            latestButton.rx.tap
                .map { SortType.latest }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            
            titleSortButton.rx.tap
                .map { SortType.title }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            
            deadlineSortButton.rx.tap
                .map { SortType.deadline }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            
            // 정렬 타입에 따른 버튼 스타일 변경
            sortType
                .subscribe(onNext: { [weak self] type in
                    self?.updateSortButtonStyles(selectedType: type)
                })
                .disposed(by: disposeBag)
            
            // 정렬 적용
            Observable.combineLatest(allLinksCache, sortType)
                .map { [weak self] (links, sortType) -> [LinkMetadata] in
                    guard let self = self else { return [] }
                    return self.sortLinks(links, by: sortType)
                }
                .bind(to: links)
                .disposed(by: disposeBag)
        }
        
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
                        .subscribe()
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
        if case .allLinks = mode {
            [sortButtonsStackView, tableView, emptyView, floatingAddButton].forEach { view.addSubview($0) }
            [latestButton, titleSortButton, deadlineSortButton].forEach { sortButtonsStackView.addArrangedSubview($0) }
        } else {
            [tableView, emptyView, floatingAddButton].forEach { view.addSubview($0) }
        }
        emptyView.addSubview(emptyLabel)
    }
    
    override func configureLayout() {
        if case .allLinks = mode {
            sortButtonsStackView.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
                make.leading.equalToSuperview().offset(20)
                make.height.equalTo(36)
            }
            
            tableView.snp.makeConstraints { make in
                make.top.equalTo(sortButtonsStackView.snp.bottom).offset(16)
                make.horizontalEdges.bottom.equalToSuperview()
            }
        } else {
            tableView.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide)
                make.horizontalEdges.bottom.equalToSuperview()
            }
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

// MARK: - UITableViewDelegate (스와이프 액션)
extension LinkListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            let link = self.links.value[indexPath.row]
            
            let alert = UIAlertController(title: "링크 삭제", message: "이 링크를 삭제하시겠습니까?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
                self.repository.deleteLink(url: link.url.absoluteString)
                LinkManager.shared.deleteLink(url: link.url)
                    .subscribe(onNext: { [weak self] _ in
                        self?.loadLinks()
                    })
                    .disposed(by: self.disposeBag)
                completionHandler(true)
            })
            self.present(alert, animated: true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "수정") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            let link = self.links.value[indexPath.row]
            
            let editVC = EditLinkViewController()
            editVC.editingLink = link
            editVC.onLinkUpdated = { [weak self] in
                LinkManager.shared.reloadFromRealm()
                self?.loadLinks()
            }
            self.present(UINavigationController(rootViewController: editVC), animated: true)
            
            completionHandler(true)
        }
        editAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [editAction])
    }
}
