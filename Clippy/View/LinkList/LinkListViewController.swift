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
    
    // LinkSortType을 사용하도록 변경
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var loadDisposeBag = DisposeBag()
    private let repository = CategoryRepository()
    private let links = BehaviorRelay<[LinkMetadata]>(value: [])
    private let allLinksCache = BehaviorRelay<[LinkMetadata]>(value: [])
    private let sortType = BehaviorRelay<LinkSortType>(value: .latest)
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
    private let scrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
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
        button.backgroundColor = .clippyBlue
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
    
    private let allExpiringButton = {
        let button = UIButton(type: .system)
        button.setTitle("전체", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return button
    }()
    
    private let readSortButton = {
        let button = UIButton(type: .system)
        button.setTitle("열람", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return button
    }()
    
    private let unreadSortButton = {
        let button = UIButton(type: .system)
        button.setTitle("미열람", for: .normal)
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
            }
            .bind(to: allLinksCache)
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
            }
            .bind(to: allLinksCache)
            .disposed(by: loadDisposeBag)
    }
    
    private func loadAllLinks() {
        LinkManager.shared.links
            .bind(to: allLinksCache)
            .disposed(by: loadDisposeBag)
    }
    
    private func sortLinks(_ links: [LinkMetadata], by sortType: LinkSortType) -> [LinkMetadata] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch sortType {
        case .latest:
            return links.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return links.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .deadline:
            return links.sorted { link1, link2 in
                // 1. 미래 마감일, 2. 마감일 없음, 3. 마감일 지난 링크 순
                let d1 = link1.dueDate
                let d2 = link2.dueDate

                let isPast1 = d1 != nil && calendar.startOfDay(for: d1!) < today
                let isPast2 = d2 != nil && calendar.startOfDay(for: d2!) < today
                let isNil1 = d1 == nil
                let isNil2 = d2 == nil

                // 마감된 링크는 항상 뒤에
                if isPast1 != isPast2 {
                    return !isPast1 && isPast2
                }

                // 둘 다 마감됨 -> 최근 마감 먼저
                if isPast1 && isPast2 {
                    return d1! > d2!
                }

                // 둘 다 미래(오늘 포함) or 마감일 없음인 경우
                if isNil1 != isNil2 {
                    return !isNil1 && isNil2 // nil이 더 아래
                }

                // 둘 다 날짜 있음(미래, 오늘) -> 날짜 빠른게 위
                if let d1 = d1, let d2 = d2 {
                    let sd1 = calendar.startOfDay(for: d1)
                    let sd2 = calendar.startOfDay(for: d2)
                    if sd1 != sd2 {
                        return sd1 < sd2
                    }
                    // 같은 날이면 최근 생성된 게 위
                    return link1.createdAt > link2.createdAt
                }

                // 둘 다 마감일 없음 -> 최근 생성일이 위
                return link1.createdAt > link2.createdAt
            }
        case .read:
            return links.filter { $0.isOpened }.sorted { $0.createdAt > $1.createdAt }
        case .unread:
            return links.filter { !$0.isOpened }.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    private func updateSortButtonStyles(selectedType: LinkSortType) {
        let buttons: [(UIButton, LinkSortType)] = [
            (latestButton, .latest),
            (titleSortButton, .title),
            (deadlineSortButton, .deadline),
            (allExpiringButton, .deadline),
            (readSortButton, .read),
            (unreadSortButton, .unread)
        ]
        
        buttons.forEach { button, type in
            if type == selectedType {
                button.backgroundColor = .clippyBlue
                button.setTitleColor(.white, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            } else {
                button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
                button.setTitleColor(.label, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            }
        }
    }
    
    private func scrollToTop() {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    override func bind() {
        // 모든 모드에 테이블뷰 delegate 설정 (스와이프 액션)
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        // allLinks 모드, expiring 모드, category 모드에서 정렬 버튼 바인딩
        if case .allLinks = mode {
            latestButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.latest }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            
            titleSortButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.title }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            
            deadlineSortButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.deadline }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            
            readSortButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.read }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            
            unreadSortButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.unread }
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
                    guard let self = self else { return links }
                    return self.sortLinks(links, by: sortType)
                }
                .bind(to: links)
                .disposed(by: disposeBag)
        }
        
        // expiring 모드에서도 정렬 버튼 바인딩
        if case .expiring = mode {
            allExpiringButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.deadline }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            readSortButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.read }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            
            unreadSortButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.unread }
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
                    guard let self = self else { return links }
                    return self.sortLinks(links, by: sortType)
                }
                .bind(to: links)
                .disposed(by: disposeBag)
            
            // 기본 선택: 전체(마감일순)
            sortType.accept(.deadline)
        }
        
        // category 모드에서도 정렬 버튼 바인딩
        if case .category = mode {
            latestButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.latest }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            
            titleSortButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.title }
                .bind(to: sortType)
                .disposed(by: disposeBag)
            
            deadlineSortButton.rx.tap
                .do(onNext: { [weak self] _ in
                    self?.scrollToTop()
                })
                .map { LinkSortType.deadline }
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
                    guard let self = self else { return links }
                    return self.sortLinks(links, by: sortType)
                }
                .bind(to: links)
                .disposed(by: disposeBag)
            
            // 기본 선택: 최신순
            sortType.accept(.latest)
        }
        
        // category 모드가 아닌 경우에만 기존 links 바인딩 사용
        if case .category = mode {
            // category 모드는 위에서 이미 바인딩됨
        } else {
            // allLinks와 expiring 모드는 위에서 이미 바인딩됨
        }
        
        links
            .bind(to: tableView.rx.items(cellIdentifier: LinkTableViewCell.identifier, cellType: LinkTableViewCell.self)) { [weak self] _, item, cell in
                guard let self = self else { return }
                cell.configure(with: item)
                
                cell.readTapHandler = {
                    LinkManager.shared.toggleOpened(for: item.url)
                        .subscribe()
                        .disposed(by: cell.disposeBag)
                }
                
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
        
        // 링크 선택 시 상세 화면으로 이동
        tableView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .withLatestFrom(links) { indexPath, links in
                links[indexPath.row]
            }
            .bind(with: self) { owner, link in
                let detailVC = LinkDetailViewController(link: link)
                let navController = UINavigationController(rootViewController: detailVC)
                navController.modalPresentationStyle = .formSheet
                owner.present(navController, animated: true)
            }
            .disposed(by: disposeBag)
        
        // 링크 생성 알림 받기
        NotificationCenter.default.rx
            .notification(.linkDidCreate)
            .bind(with: self) { owner, _ in
                owner.loadLinks()
            }
            .disposed(by: disposeBag)
        
        // 마감 임박 링크 하이라이트 알림 받기
        NotificationCenter.default.rx
            .notification(NSNotification.Name("HighlightExpiringLink"))
            .bind(with: self) { owner, notification in
                if let userInfo = notification.userInfo,
                   let linkId = userInfo["linkId"] as? String {
                    owner.highlightLink(with: linkId)
                }
            }
            .disposed(by: disposeBag)
    }
    
    override func configureHierarchy() {
        if case .allLinks = mode {
            [scrollView, tableView, emptyView].forEach { view.addSubview($0) }
            scrollView.addSubview(sortButtonsStackView)
            [latestButton, titleSortButton, deadlineSortButton, readSortButton, unreadSortButton].forEach { sortButtonsStackView.addArrangedSubview($0) }
        } else if case .expiring = mode {
            [sortButtonsStackView, tableView, emptyView].forEach { view.addSubview($0) }
            [allExpiringButton, readSortButton, unreadSortButton].forEach { sortButtonsStackView.addArrangedSubview($0) }
        } else if case .category = mode {
            [scrollView, tableView, emptyView].forEach { view.addSubview($0) }
            scrollView.addSubview(sortButtonsStackView)
            [latestButton, titleSortButton, deadlineSortButton].forEach { sortButtonsStackView.addArrangedSubview($0) }
        } else {
            [tableView, emptyView].forEach { view.addSubview($0) }
        }
        emptyView.addSubview(emptyLabel)
    }
    
    override func configureLayout() {
        if case .allLinks = mode {
            scrollView.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(36)
            }
            
            sortButtonsStackView.snp.makeConstraints { make in
                // 좌우 패딩을 주어 첫 버튼이 가장자리와 붙지 않도록 함
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
                make.height.equalToSuperview()
            }
            
            tableView.snp.makeConstraints { make in
                make.top.equalTo(scrollView.snp.bottom).offset(16)
                make.horizontalEdges.bottom.equalToSuperview()
            }
        } else if case .expiring = mode {
            sortButtonsStackView.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
                make.leading.equalToSuperview().offset(20)
                make.height.equalTo(36)
            }
            
            tableView.snp.makeConstraints { make in
                make.top.equalTo(sortButtonsStackView.snp.bottom).offset(16)
                make.horizontalEdges.bottom.equalToSuperview()
            }
        } else if case .category = mode {
            scrollView.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(36)
            }
            
            sortButtonsStackView.snp.makeConstraints { make in
                // 좌우 패딩을 주어 첫 버튼이 가장자리와 붙지 않도록 함
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
                make.height.equalToSuperview()
            }
            
            tableView.snp.makeConstraints { make in
                make.top.equalTo(scrollView.snp.bottom).offset(16)
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
        
    }
    
    override func configureView() {
        super.configureView()
        
        
        navigationItem.title = categoryName
        navigationController?.navigationBar.tintColor = .black
        
        // 네비게이션바 오른쪽에 + 버튼 추가 (카테고리 모드와 전체 링크 모드에만)
        switch mode {
        case .category(_), .allLinks:
            let button = UIBarButtonItem(
                image: UIImage(systemName: "plus"),
                style: .plain,
                target: nil,
                action: nil
            )
            button.tintColor = .clippyBlue
            
            navigationItem.rightBarButtonItem = button
            
            button.rx.tap
                .bind(with: self) { owner, _ in
                    let editVC = EditLinkViewController()
                    if case .category(let categoryName) = owner.mode {
                        editVC.defaultCategoryName = categoryName
                    }
                    editVC.onLinkCreated = { [weak owner] in
                        owner?.loadLinks()
                    }
                    owner.present(UINavigationController(rootViewController: editVC), animated: true)
                }
                .disposed(by: disposeBag)
        case .expiring:
            break
        }
        
        loadLinks()
    }
    
    // MARK: - Highlight Methods
    
    private func highlightLink(with linkId: String) {
        // 마감 임박 모드일 때만 하이라이트 실행
        guard case .expiring = mode else {
            print("❌ 마감 임박 모드가 아니므로 하이라이트하지 않습니다")
            return
        }
        
        let currentLinks = links.value
        
        // linkId로 해당 링크 찾기 (URL 기반 매칭)
        guard let targetIndex = currentLinks.firstIndex(where: { link in
            let normalizedUrl = link.url.absoluteString.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
            return normalizedUrl == linkId
        }) else {
            print("❌ 하이라이트할 링크를 찾을 수 없습니다: \(linkId)")
            return
        }
        
        print("✅ 하이라이트할 링크 찾음: \(currentLinks[targetIndex].title)")
        
        // 해당 위치로 스크롤
        let indexPath = IndexPath(row: targetIndex, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        
        // 하이라이트 애니메이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performHighlightAnimation(at: indexPath)
        }
    }
    
    private func performHighlightAnimation(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? LinkTableViewCell else { return }
        
        // 원래 배경색 저장
        let originalBackgroundColor = cell.backgroundColor
        
        // 하이라이트 애니메이션
        UIView.animate(withDuration: 0.3, animations: {
            cell.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.0, options: [], animations: {
                cell.backgroundColor = originalBackgroundColor
            })
        }
        
        // 펄스 효과
        UIView.animate(withDuration: 0.6, delay: 0.0, options: [.repeat, .autoreverse], animations: {
            cell.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                cell.transform = .identity
            }
        }
        
        // 2초 후 애니메이션 중지
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            cell.layer.removeAllAnimations()
            cell.transform = .identity
        }
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
        editAction.backgroundColor = .clippyBlue
        
        return UISwipeActionsConfiguration(actions: [editAction])
    }
}
