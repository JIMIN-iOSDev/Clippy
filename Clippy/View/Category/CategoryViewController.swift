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
    
    private let categories = [
        CategoryItem(title: "업무", count: 2, iconName: "briefcase.fill", iconColor: .systemBlue, backgroundColor: .systemBlue.withAlphaComponent(0.1)),
        CategoryItem(title: "학습", count: 3, iconName: "book.fill", iconColor: .systemTeal, backgroundColor: .systemTeal.withAlphaComponent(0.1)),
        CategoryItem(title: "쇼핑", count: 1, iconName: "cart.fill", iconColor: .systemOrange, backgroundColor: .systemOrange.withAlphaComponent(0.1)),
        CategoryItem(title: "개인", count: 2, iconName: "heart.fill", iconColor: .systemPurple, backgroundColor: .systemPurple.withAlphaComponent(0.1)),
        CategoryItem(title: "엔터테인먼트", count: 0, iconName: "tv.fill", iconColor: .systemPink, backgroundColor: .systemPink.withAlphaComponent(0.1)),
        CategoryItem(title: "뉴스", count: 0, iconName: "newspaper.fill", iconColor: .systemCyan, backgroundColor: .systemCyan.withAlphaComponent(0.1)),
        CategoryItem(title: "뉴스1", count: 0, iconName: "newspaper.fill", iconColor: .systemCyan, backgroundColor: .systemCyan.withAlphaComponent(0.1)),
        CategoryItem(title: "뉴스2", count: 0, iconName: "newspaper.fill", iconColor: .systemCyan, backgroundColor: .systemCyan.withAlphaComponent(0.1))
    ]
    
    // MARK: - UI Components
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

    private let savedLinksView = {
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

    private let expiredLinksView = {
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

    private let categoryTitleLabel = {
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

    private let linksTableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(LinkTableViewCell.self, forCellReuseIdentifier: LinkTableViewCell.identifier)
        tableView.isScrollEnabled = false
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
    
    // MARK: - Configuration
    override func bind() {
        addCategoryButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.present(UINavigationController(rootViewController: EditLinkViewController()), animated: true)
            }
            .disposed(by: disposeBag)

        floatingAddButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.present(UINavigationController(rootViewController: EditLinkViewController()), animated: true)
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
        
        // 카테고리 컬렉션뷰 바인딩
        Observable.just(categories)
            .bind(to: categoryCollectionView.rx.items(cellIdentifier: CategoryCollectionViewCell.identifier, cellType: CategoryCollectionViewCell.self)) { _, category, cell in
                cell.configure(with: category)
            }
            .disposed(by: disposeBag)
        
        categoryCollectionView.rx.itemSelected
            .asDriver()
            .drive(with: self) { owner, indexPath in
                // TODO: 해당 카테고리 링크 화면으로 전환
            }
            .disposed(by: disposeBag)
        
        // 링크 테이블뷰 바인딩
        LinkManager.shared.recentLinks
            .bind(to: linksTableView.rx.items(cellIdentifier: LinkTableViewCell.identifier, cellType: LinkTableViewCell.self)) { [weak self] _, link, cell in
                cell.configure(with: link)
                
                cell.heartTapHandler = {
                    LinkManager.shared.toggleLike(for: link.url)
                        .subscribe()
                        .disposed(by: self?.disposeBag ?? DisposeBag())
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
            .withLatestFrom(LinkManager.shared.recentLinks) { indexPath, links in
                links[indexPath.row]
            }
            .subscribe(onNext: { link in
                if UIApplication.shared.canOpenURL(link.url) {
                    // 사파리에서 창 띄우기
                    UIApplication.shared.open(link.url, options: [:], completionHandler: nil)
                }
            })
            .disposed(by: disposeBag)
        
        // 테이블뷰 높이 자동 업데이트
        LinkManager.shared.recentLinks
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
    }
    
    override func configureHierarchy() {
        [scrollView, floatingAddButton].forEach { view.addSubview($0) }
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
        
        floatingAddButton.snp.makeConstraints { make in
            make.size.equalTo(56)
            make.trailing.equalToSuperview().offset(-26)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-38)
        }
    }
    
    override func configureView() {
        super.configureView()
        
        navigationItem.title = "Clippy"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.label]
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
}

