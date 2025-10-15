//
//  CategoryViewController.swift
//  Clippy
//
//  Created by Jimin on 9/24/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import UserNotifications

struct CategoryItem {
    let title: String
    let count: Int
    let iconName: String
    let iconColor: UIColor
    let backgroundColor: UIColor
}

final class CategoryViewController: BaseViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let repository = CategoryRepository()
    
    private let categories = BehaviorRelay<[CategoryItem]>(value: [])
    private let recentLinks = BehaviorRelay<[LinkMetadata]>(value: [])
    
    // MARK: - UI Components
    internal var addButton: UIBarButtonItem? // 툴팁에서 접근하기 위해 internal로 변경
    
    private let scrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let statsStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        return stackView
    }()

    let savedLinksView = {
        let view = UIView()
        view.backgroundColor = .clippyBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 16
        return view
    }()

    private let savedLinksIconView = {
        let view = UIView()
        view.backgroundColor = .clippyBlue.withAlphaComponent(0.2)
        view.layer.cornerRadius = 20
        return view
    }()

    private let savedLinksIcon = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView.image = UIImage(systemName: "link", withConfiguration: config)
        imageView.tintColor = .clippyBlue
        return imageView
    }()

    private let savedLinksCountLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        return label
    }()

    private let savedLinksTextLabel = {
        let label = UILabel()
        label.text = "저장된 링크"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    let expiredLinksView = {
        let view = UIView()
        view.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        view.layer.cornerRadius = 16
        return view
    }()

    private let expiredLinksIconView = {
        let view = UIView()
        view.backgroundColor = .systemOrange.withAlphaComponent(0.2)
        view.layer.cornerRadius = 20
        return view
    }()

    private let expiredLinksIcon = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView.image = UIImage(systemName: "clock", withConfiguration: config)
        imageView.tintColor = .systemOrange
        return imageView
    }()

    private let expiredLinksCountLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        return label
    }()

    private let expiredLinksTextLabel = {
        let label = UILabel()
        label.text = "마감 임박"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let categoryHeaderView = UIView()

    let categoryTitleLabel = {
        let label = UILabel()
        label.text = "카테고리"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let addCategoryButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ 추가", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.tintColor = .clippyBlue
        return button
    }()

    private let categoryContainerView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let categoryCollectionView = {
        let layout = UICollectionViewFlowLayout()
        
        // 가로 스크롤을 위한 설정
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        // 카드 크기 설정 (한 행에 맞게, 높이 증가)
        let screenHeight = UIScreen.main.bounds.height
        let itemHeight: CGFloat = screenHeight < 700 ? 110 : 130
        let itemWidth: CGFloat = screenHeight < 700 ? 100 : 120
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CategoryCollectionViewCell.self, forCellWithReuseIdentifier: CategoryCollectionViewCell.identifier)
        return collectionView
    }()

    private let recentLinksLabel = {
        let label = UILabel()
        label.text = "최근 링크"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    let linksTableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(LinkTableViewCell.self, forCellReuseIdentifier: LinkTableViewCell.identifier)
        tableView.isScrollEnabled = false
        return tableView
    }()

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LinkManager.shared.reloadFromRealm()
        loadCategories()
    }
    
    // MARK: - Configuration
    
    /// 기기별 카테고리 컨테이너 높이 계산 (한 행에 맞게 조정, 높이 증가)
    private func getCategoryContainerHeight() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        switch screenHeight {
        case 0..<700: // iPhone 13 mini, SE 등
            return 142 // 110 + 16*2 (패딩)
        case 700..<800: // iPhone 13, 14 등
            return 162 // 130 + 16*2 (패딩)
        default: // iPhone 14 Pro Max 등
            return 162 // 130 + 16*2 (패딩)
        }
    }
    
    private func loadCategories() {
        let realmCategories = repository.readCategoryList()
        let categoryItems = realmCategories.map {
            CategoryItem(title: $0.name, count: repository.getUniqueLinkCount(for: $0.name), iconName: $0.iconName, iconColor: CategoryColor.color(index: $0.colorIndex), backgroundColor: CategoryColor.color(index: $0.colorIndex).withAlphaComponent(0.1))
        }
        
        categories.accept(categoryItems)
    }
    
    override func bind() {
        linksTableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        addCategoryButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.present(UINavigationController(rootViewController: EditCategoryViewController()), animated: true)
            }
            .disposed(by: disposeBag)

        
        // 저장된 링크 카드 탭
        let savedTapGesture = UITapGestureRecognizer()
        savedLinksView.addGestureRecognizer(savedTapGesture)
        savedLinksView.isUserInteractionEnabled = true
        
        savedTapGesture.rx.event
            .bind(with: self) { owner, _ in
                let linkListVC = LinkListViewController(mode: .allLinks)
                owner.navigationController?.pushViewController(linkListVC, animated: true)
                owner.navigationItem.backButtonTitle = ""
            }
            .disposed(by: disposeBag)
        
        // 마감 임박 카드 탭
        let expiredTapGesture = UITapGestureRecognizer()
        expiredLinksView.addGestureRecognizer(expiredTapGesture)
        expiredLinksView.isUserInteractionEnabled = true
        
        expiredTapGesture.rx.event
            .bind(with: self) { owner, _ in
                let linkListVC = LinkListViewController(mode: .expiring)
                owner.navigationController?.pushViewController(linkListVC, animated: true)
                owner.navigationItem.backButtonTitle = ""
            }
            .disposed(by: disposeBag)

        LinkManager.shared.savedLinksCount
            .map { "\($0)" }
            .bind(to: savedLinksCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        LinkManager.shared.expiredLinksCount
            .map { "\($0)" }
            .bind(to: expiredLinksCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        categories
            .bind(to: categoryCollectionView.rx.items(cellIdentifier: CategoryCollectionViewCell.identifier, cellType: CategoryCollectionViewCell.self)) { [weak self] index, category, cell in
                cell.configure(with: category)
                
                // 편집 버튼 콜백 설정
                cell.onEditTapped = {
                    self?.showCategoryEditMenu(for: category, at: index)
                }
            }
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.categoryDidCreate)
            .bind(with: self) { owner, _ in
                owner.loadCategories()
            }
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.categoryDidUpdate)
            .bind(with: self) { owner, _ in
                owner.loadCategories()
            }
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.categoryDidDelete)
            .bind(with: self) { owner, _ in
                owner.loadCategories()
            }
            .disposed(by: disposeBag)
    
        categoryCollectionView.rx.itemSelected
            .withLatestFrom(categories) { indexPath, categories in
                categories[indexPath.row]
            }
            .asDriver(onErrorJustReturn: CategoryItem(title: "", count: 0, iconName: "", iconColor: .clear, backgroundColor: .clear))
            .drive(with: self) { owner, category in
                let linkListVC = LinkListViewController(categoryName: category.title)
                owner.navigationController?.pushViewController(linkListVC, animated: true)
                owner.navigationItem.backButtonTitle = ""
            }
            .disposed(by: disposeBag)
        
        LinkManager.shared.recentLinks
            .bind(to: recentLinks) // 먼저 로컬에 저장
            .disposed(by: disposeBag)

        recentLinks
            .bind(to: linksTableView.rx.items(cellIdentifier: LinkTableViewCell.identifier, cellType: LinkTableViewCell.self)) { [weak self] _, link, cell in
                cell.configure(with: link)
                cell.removeShadow() // 최근 링크 셀의 그림자 제거
                
                cell.readTapHandler = {
                    LinkManager.shared.toggleOpened(for: link.url)
                        .subscribe()
                        .disposed(by: cell.disposeBag)
                }
                
                cell.heartTapHandler = {
                    LinkManager.shared.toggleLike(for: link.url)
                        .subscribe()
                        .disposed(by: cell.disposeBag)
                }
                
                cell.shareTapHandler = { [weak self] in
                    let activityViewController = UIActivityViewController(activityItems: [link.url], applicationActivities: nil)
                    self?.present(activityViewController, animated: true)
                }
            }
            .disposed(by: disposeBag)

        linksTableView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.linksTableView.deselectRow(at: indexPath, animated: true)
            })
            .withLatestFrom(recentLinks) { indexPath, links in
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

        // 테이블뷰 높이 자동 업데이트
        recentLinks
            .map { CGFloat($0.count * 156) }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] height in
                self?.linksTableView.snp.updateConstraints { make in
                    make.height.equalTo(height)
                }
                UIView.animate(withDuration: 0.3) {
                    self?.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.linkDidCreate)
            .bind(with: self) { owner, _ in
                owner.loadCategories()
            }
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.linkDidDelete)
            .bind(with: self) { owner, _ in
                owner.loadCategories()
            }
            .disposed(by: disposeBag)
    }
    

    override func configureHierarchy() {
        [scrollView].forEach { view.addSubview($0) }
        scrollView.addSubview(contentView)
        [statsStackView, categoryHeaderView, categoryContainerView, recentLinksLabel, linksTableView].forEach { contentView.addSubview($0) }
        [savedLinksView, expiredLinksView].forEach { statsStackView.addArrangedSubview($0) }
        savedLinksIconView.addSubview(savedLinksIcon)
        [savedLinksIconView, savedLinksCountLabel, savedLinksTextLabel].forEach { savedLinksView.addSubview($0) }
        expiredLinksIconView.addSubview(expiredLinksIcon)
        [expiredLinksIconView, expiredLinksCountLabel, expiredLinksTextLabel].forEach { expiredLinksView.addSubview($0) }
        [categoryTitleLabel, addCategoryButton].forEach { categoryHeaderView.addSubview($0) }
        categoryContainerView.addSubview(categoryCollectionView)
    }
    
    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        statsStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(80)
        }
        
        savedLinksIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        
        savedLinksIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        savedLinksCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(savedLinksIconView.snp.trailing).offset(12)
            make.centerY.equalToSuperview().offset(-10)
        }
        
        savedLinksTextLabel.snp.makeConstraints { make in
            make.leading.equalTo(savedLinksCountLabel)
            make.top.equalTo(savedLinksCountLabel.snp.bottom).offset(4)
        }
        
        expiredLinksIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        
        expiredLinksIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        expiredLinksCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(expiredLinksIconView.snp.trailing).offset(12)
            make.centerY.equalToSuperview().offset(-10)
        }
        
        expiredLinksTextLabel.snp.makeConstraints { make in
            make.leading.equalTo(expiredLinksCountLabel)
            make.top.equalTo(expiredLinksCountLabel.snp.bottom).offset(4)
        }
        
        categoryHeaderView.snp.makeConstraints { make in
            make.top.equalTo(statsStackView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(24)
        }
        
        // 알림 권한 요청 후 안내 시작
        requestNotificationPermissionAndStartGuide()
        
        categoryTitleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        addCategoryButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        
        categoryContainerView.snp.makeConstraints { make in
            make.top.equalTo(categoryHeaderView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(getCategoryContainerHeight())
        }
        
        categoryCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        recentLinksLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryContainerView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        linksTableView.snp.makeConstraints { make in
            make.top.equalTo(recentLinksLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
            make.bottom.equalToSuperview().offset(-100)
        }
        
    }
    
    override func configureView() {
        super.configureView()
        
        // 홈화면만 옅은 회색 배경으로 설정
        view.backgroundColor = .systemGray6
        
        repository.createDefaultCategory()  // "일반" 카테고리 기본 제공
        loadCategories()
        
        navigationItem.title = "Clippy"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.label]
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        // 네비게이션바 오른쪽에 + 버튼 추가
        let button = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: nil,
            action: nil
        )
        button.tintColor = .clippyBlue
        
        // 툴팁에서 접근할 수 있도록 저장
        self.addButton = button
        
        navigationItem.rightBarButtonItem = button
        
        button.rx.tap
            .bind(with: self) { owner, _ in
                owner.present(UINavigationController(rootViewController: EditLinkViewController()), animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Notification Permission & Guide
    
    private func requestNotificationPermissionAndStartGuide() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 알림 권한 요청 실패: \(error.localizedDescription)")
                    // 권한 요청 실패해도 안내는 시작
                    self?.startTooltipsAfterPermission()
                    return
                }
                
                if granted {
                    print("✅ 알림 권한 허용됨")
                    // 백그라운드에서 알림 설정 (딜레이 없이)
                    DispatchQueue.global(qos: .background).async {
                        NotificationManager.shared.setupNotificationsForAllLinks()
                    }
                } else {
                    print("❌ 알림 권한 거부됨")
                }
                
                // 딜레이 없이 즉시 안내 시작
                self?.startTooltipsAfterPermission()
            }
        }
    }
    
    private func startTooltipsAfterPermission() {
        // 툴팁 시작
        TooltipManager.shared.startSequentialTooltips(in: self)
    }
    
    // MARK: - Category Edit Menu
    
    private func showCategoryEditMenu(for category: CategoryItem, at index: Int) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 카테고리명을 커스텀 제목으로 설정
        alert.setValue(NSAttributedString(string: category.title, attributes: [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor.label
        ]), forKey: "attributedTitle")
        
        // 수정 액션
        let editAction = UIAlertAction(title: "카테고리 수정", style: .default) { [weak self] _ in
            self?.editCategory(at: index)
        }
        
        // 삭제 액션 (링크가 있어도 일반 카테고리로 이동시키고 삭제)
        let deleteAction = UIAlertAction(title: "카테고리 삭제", style: .destructive) { [weak self] _ in
            self?.deleteCategory(at: index)
        }
        
        // 취소 액션
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(editAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // iPad 지원
        if let popover = alert.popoverPresentationController {
            if let cell = categoryCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
        }
        
        present(alert, animated: true)
    }
    
    private func editCategory(at index: Int) {
        guard index < categories.value.count else { return }
        let categoryItem = categories.value[index]
        
        // 해당 카테고리의 Realm 객체 가져오기
        guard let realmCategory = repository.readCategory(name: categoryItem.title) else {
            print("카테고리 없음: \(categoryItem.title)")
            return
        }
        
        let editVC = EditCategoryViewController()
        editVC.setupEditMode(with: realmCategory)
        editVC.onCategoryUpdated = { [weak self] in
            self?.loadCategories()
        }
        
        let navController = UINavigationController(rootViewController: editVC)
        present(navController, animated: true)
    }
    
    
    private func deleteCategory(at index: Int) {
        guard index < categories.value.count else { return }
        let categoryItem = categories.value[index]
        
        guard categoryItem.title != "일반" else {
            showToast(message: "일반 카테고리는 삭제할 수 없습니다")
            return
        }
        
        let alert = UIAlertController(title: "카테고리 삭제", 
                                     message: "'\(categoryItem.title)' 카테고리를 삭제하시겠습니까?\n\n해당 카테고리의 모든 링크는\n'일반' 카테고리로 이동됩니다.", 
                                     preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.performCategoryDeletion(for: categoryItem.title, at: index)
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func performCategoryDeletion(for categoryName: String, at index: Int) {
        let success = repository.deleteCategory(name: categoryName)
        
        if success {
            NotificationCenter.default.post(name: .categoryDidDelete, object: nil)
            loadCategories()
            showToast(message: "'\(categoryName)' 카테고리가 삭제되었습니다")
        } else {
            showToast(message: "카테고리 삭제에 실패했습니다")
        }
    }
    
    // MARK: - Toast Message
    private func showToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textAlignment = .center
        toast.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.alpha = 0
        
        view.addSubview(toast)
        view.bringSubviewToFront(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(36)
            make.width.greaterThanOrEqualTo(message.count * 12 + 40)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                UIView.animate(withDuration: 0.3, animations: {
                    toast.alpha = 0
                }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }
}

extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let link = self.recentLinks.value[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            // 더미링크인 경우 그냥 삭제 가능
            if link.url.absoluteString == "https://clippy.dummy.swipe.guide" {
                LinkManager.shared.deleteDummyLinkForSwipeGuide()
                completionHandler(true)
                return
            }
            
            let alert = UIAlertController(title: "링크 삭제", message: "이 링크를 삭제하시겠습니까?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
                self.repository.deleteLink(url: link.url.absoluteString)
                LinkManager.shared.deleteLink(url: link.url)
                    .subscribe()
                    .disposed(by: self.disposeBag)
                completionHandler(true)
            })
            self.present(alert, animated: true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let link = self.recentLinks.value[indexPath.row]
        
        // 더미링크인 경우 수정 액션 없음
        if link.url.absoluteString == "https://clippy.dummy.swipe.guide" {
            return UISwipeActionsConfiguration(actions: [])
        }
        
        let editAction = UIContextualAction(style: .normal, title: "수정") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            let editVC = EditLinkViewController()
            editVC.editingLink = link
            editVC.onLinkUpdated = { [weak self] in
                LinkManager.shared.reloadFromRealm()
            }
            self.present(UINavigationController(rootViewController: editVC), animated: true)
            
            completionHandler(true)
        }
        editAction.backgroundColor = .clippyBlue
        
        return UISwipeActionsConfiguration(actions: [editAction])
    }
}
