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
    internal var addButton: UIButton? // 툴팁에서 접근하기 위해 internal로 변경
    
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
        view.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 16
        return view
    }()

    private let savedLinksIconView = {
        let view = UIView()
        view.backgroundColor = .systemBlue.withAlphaComponent(0.2)
        view.layer.cornerRadius = 20
        return view
    }()

    private let savedLinksIcon = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView.image = UIImage(systemName: "link", withConfiguration: config)
        imageView.tintColor = .systemBlue
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
        button.tintColor = .systemBlue
        return button
    }()

    private let categoryContainerView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 16
        return view
    }()

    private let categoryCollectionView = {
        let layout = UICollectionViewFlowLayout()
        let totalWidth = UIScreen.main.bounds.width - 40 - 32
        let itemWidth = (totalWidth - 24) / 3
        layout.itemSize = CGSize(width: itemWidth, height: 130)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
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
    private func loadCategories() {
        let realmCategories = repository.readCategoryList()
        let categoryItems = realmCategories.map {
            CategoryItem(title: $0.name, count: $0.category.count, iconName: $0.iconName, iconColor: CategoryColor.color(index: $0.colorIndex), backgroundColor: CategoryColor.color(index: $0.colorIndex).withAlphaComponent(0.1))
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
            .bind(to: categoryCollectionView.rx.items(cellIdentifier: CategoryCollectionViewCell.identifier, cellType: CategoryCollectionViewCell.self)) { _, category, cell in
                cell.configure(with: category)
            }
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.categoryDidCreate)
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
            .subscribe(onNext: { link in
                if UIApplication.shared.canOpenURL(link.url) {
                    UIApplication.shared.open(link.url, options: [:], completionHandler: nil)
                }
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
            make.height.equalTo(100)
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
            make.top.equalToSuperview().offset(20)
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
            make.top.equalToSuperview().offset(20)
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
        
        // 순차 툴팁 시작 (더미링크는 스와이프 안내 시점에 생성)
        
        TooltipManager.shared.startSequentialTooltips(in: self)
        
        categoryTitleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        addCategoryButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        
        categoryContainerView.snp.makeConstraints { make in
            make.top.equalTo(categoryHeaderView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(280)
        }
        
        categoryCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        recentLinksLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryContainerView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        linksTableView.snp.makeConstraints { make in
            make.top.equalTo(recentLinksLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
            make.bottom.equalToSuperview().offset(-100)
        }
        
    }
    
    override func configureView() {
        super.configureView()
        
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
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 18
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 3
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        
        // 툴팁에서 접근할 수 있도록 저장
        self.addButton = button
        
        let addButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = addButton
        
        button.rx.tap
            .bind(with: self) { owner, _ in
                owner.present(UINavigationController(rootViewController: EditLinkViewController()), animated: true)
            }
            .disposed(by: disposeBag)
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
        editAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [editAction])
    }
}
