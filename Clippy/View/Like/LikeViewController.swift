//
//  LikeViewController.swift
//  Clippy
//
//  Created by Jimin on 9/25/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class LikeViewController: BaseViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let repository = CategoryRepository()
    private let sortType = BehaviorRelay<LinkSortType>(value: .latest)
    
    // LinkSortType을 사용하도록 변경
    
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
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.register(LinkTableViewCell.self, forCellReuseIdentifier: LinkTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 156
        return tableView
    }()
    
    private let emptyStateLabel = {
        let label = UILabel()
        label.text = "즐겨찾기한 링크가 없습니다"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Configuration
    override func bind() {
        // 정렬 버튼 탭 이벤트
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
        
        // LinkManager에서 즐겨찾기 링크만 필터링하고 정렬
        let sortedFavoriteLinks = Observable.combineLatest(
            LinkManager.shared.links,
            sortType.asObservable()
        )
        .map { [weak self] (links, sortType) -> [LinkMetadata] in
            guard let self = self else { return [] }
            
            // 즐겨찾기만 필터링
            let favoriteLinks = links.filter { $0.isLiked }
            
            // 정렬
            return self.sortLinks(favoriteLinks, by: sortType)
        }
        
        // Empty state 처리
        sortedFavoriteLinks
            .map { !$0.isEmpty }
            .bind(to: emptyStateLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        sortedFavoriteLinks
            .map { $0.isEmpty }
            .bind(to: tableView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // 네비게이션 타이틀에 즐겨찾기 전체 수 표시 (필터/정렬과 무관)
        LinkManager.shared.links
            .map { links in
                let count = links.filter { $0.isLiked }.count
                return count > 0 ? "즐겨찾기 (\(count))" : "즐겨찾기"
            }
            .bind(to: navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        // 테이블뷰 바인딩
        sortedFavoriteLinks
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
        
        // 테이블뷰 delegate 설정 (스와이프 액션)
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        // 셀 클릭 시 Safari에서 링크 열기
        tableView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .withLatestFrom(sortedFavoriteLinks) { indexPath, links in
                links[indexPath.row]
            }
            .subscribe(onNext: { [weak self] link in
                guard let self = self else { return }
                let detailVC = LinkDetailViewController(link: link)
                let navController = UINavigationController(rootViewController: detailVC)
                navController.modalPresentationStyle = .formSheet
                self.present(navController, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    override func configureHierarchy() {
        [scrollView, tableView, emptyStateLabel].forEach { view.addSubview($0) }
        scrollView.addSubview(sortButtonsStackView)
        
        [latestButton, titleSortButton, deadlineSortButton, readSortButton, unreadSortButton].forEach { sortButtonsStackView.addArrangedSubview($0) }
    }
    
    override func configureLayout() {
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
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        
        
    }
    
    private func updateSortButtonStyles(selectedType: LinkSortType) {
        let buttons: [(UIButton, LinkSortType)] = [(latestButton, .latest), (titleSortButton, .title), (deadlineSortButton, .deadline), (readSortButton, .read), (unreadSortButton, .unread)]
        
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
    
    private func scrollToTop() {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}

// MARK: - UITableViewDelegate (스와이프 액션)
extension LikeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            // RX를 사용해서 현재 정렬된 즐겨찾기 링크를 가져오기
            Observable.combineLatest(
                LinkManager.shared.links,
                self.sortType.asObservable()
            )
            .take(1)
            .subscribe(onNext: { links, sortType in
                let favoriteLinks = links.filter { $0.isLiked }
                let sortedLinks = self.sortLinks(favoriteLinks, by: sortType)
                
                guard indexPath.row < sortedLinks.count else {
                    completionHandler(false)
                    return
                }
                
                let link = sortedLinks[indexPath.row]
                
                let alert = UIAlertController(title: "링크 삭제", message: "이 링크를 삭제하시겠습니까?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
                    completionHandler(false)
                })
                alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
                    // 데이터베이스에서 실제 삭제
                    self.repository.deleteLink(url: link.url.absoluteString)
                    LinkManager.shared.deleteLink(url: link.url)
                        .subscribe(onNext: { _ in
                            // 삭제 후 자동으로 UI 업데이트됨 (RX 바인딩으로)
                        })
                        .disposed(by: self.disposeBag)
                    completionHandler(true)
                })
                self.present(alert, animated: true)
            })
            .disposed(by: self.disposeBag)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "수정") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            // RX를 사용해서 현재 정렬된 즐겨찾기 링크를 가져오기
            Observable.combineLatest(
                LinkManager.shared.links,
                self.sortType.asObservable()
            )
            .take(1)
            .subscribe(onNext: { links, sortType in
                let favoriteLinks = links.filter { $0.isLiked }
                let sortedLinks = self.sortLinks(favoriteLinks, by: sortType)
                
                guard indexPath.row < sortedLinks.count else {
                    completionHandler(false)
                    return
                }
                
                let link = sortedLinks[indexPath.row]
                
                let editVC = EditLinkViewController()
                editVC.editingLink = link
                editVC.onLinkUpdated = { [weak self] in
                    LinkManager.shared.reloadFromRealm()
                }
                self.present(UINavigationController(rootViewController: editVC), animated: true)
            })
            .disposed(by: self.disposeBag)
            
            completionHandler(true)
        }
        editAction.backgroundColor = .clippyBlue
        
        return UISwipeActionsConfiguration(actions: [editAction])
    }
}
