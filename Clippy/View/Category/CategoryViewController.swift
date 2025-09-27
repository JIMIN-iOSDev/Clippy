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

final class CategoryViewController: BaseViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
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
        label.text = "3"
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
        label.text = "0"
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
    
    private let categoryScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .systemGray6
        scrollView.layer.cornerRadius = 16
        return scrollView
    }()
    
    private let categoryContentView = UIView()
    
    private let categoryStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fill
        return stackView
    }()
    
    private let firstRowStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()
    
    private let secondRowStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()
    
    private let workCategoryView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        return view
    }()
    
    private let workCategoryIconBg = {
        let view = UIView()
        view.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let workCategoryIcon = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        imageView.image = UIImage(systemName: "briefcase.fill", withConfiguration: config)
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let workCategoryLabel = {
        let label = UILabel()
        label.text = "업무"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let workCategoryCountLabel = {
        let label = UILabel()
        label.text = "2개"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let studyCategoryView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        return view
    }()
    
    private let studyCategoryIconBg = {
        let view = UIView()
        view.backgroundColor = .systemTeal.withAlphaComponent(0.1)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let studyCategoryIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        imageView.image = UIImage(systemName: "book.fill", withConfiguration: config)
        imageView.tintColor = .systemTeal
        return imageView
    }()
    
    private let studyCategoryLabel: UILabel = {
        let label = UILabel()
        label.text = "학습"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let studyCategoryCountLabel: UILabel = {
        let label = UILabel()
        label.text = "3개"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let shoppingCategoryView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        return view
    }()
    
    private let shoppingCategoryIconBg = {
        let view = UIView()
        view.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let shoppingCategoryIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        imageView.image = UIImage(systemName: "cart.fill", withConfiguration: config)
        imageView.tintColor = .systemOrange
        return imageView
    }()
    
    private let shoppingCategoryLabel: UILabel = {
        let label = UILabel()
        label.text = "쇼핑"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let shoppingCategoryCountLabel: UILabel = {
        let label = UILabel()
        label.text = "1개"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let personalCategoryView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        return view
    }()
    
    private let personalCategoryIconBg = {
        let view = UIView()
        view.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let personalCategoryIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        imageView.image = UIImage(systemName: "heart.fill", withConfiguration: config)
        imageView.tintColor = .systemPurple
        return imageView
    }()
    
    private let personalCategoryLabel: UILabel = {
        let label = UILabel()
        label.text = "개인"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let personalCategoryCountLabel: UILabel = {
        let label = UILabel()
        label.text = "2개"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let entertainmentCategoryView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        return view
    }()
    
    private let entertainmentCategoryIconBg = {
        let view = UIView()
        view.backgroundColor = .systemPink.withAlphaComponent(0.1)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let entertainmentCategoryIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        imageView.image = UIImage(systemName: "tv.fill", withConfiguration: config)
        imageView.tintColor = .systemPink
        return imageView
    }()
    
    private let entertainmentCategoryLabel: UILabel = {
        let label = UILabel()
        label.text = "엔터테인먼트"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let entertainmentCategoryCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0개"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let newsCategoryView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        return view
    }()
    
    private let newsCategoryIconBg = {
        let view = UIView()
        view.backgroundColor = .systemCyan.withAlphaComponent(0.1)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let newsCategoryIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        imageView.image = UIImage(systemName: "newspaper.fill", withConfiguration: config)
        imageView.tintColor = .systemCyan
        return imageView
    }()
    
    private let newsCategoryLabel: UILabel = {
        let label = UILabel()
        label.text = "뉴스"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let newsCategoryCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0개"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let recentLinksLabel: UILabel = {
        let label = UILabel()
        label.text = "최근 링크"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let reactLinkView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let reactImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let reactLogoImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        imageView.image = UIImage(systemName: "atom", withConfiguration: config)
        imageView.tintColor = .systemCyan
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let reactHeartButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor.label.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "heart", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray3
        return button
    }()
    
    private let reactShareButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor.label.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray3
        return button
    }()
    
    private let reactTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "React 공식 문서"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let reactUrlLabel: UILabel = {
        let label = UILabel()
        label.text = "https://react.dev"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let reactDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "React 18 새로운 기능들 학습하기"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let reactCategoryTag: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let reactCategoryLabel: UILabel = {
        let label = UILabel()
        label.text = "학습"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemGreen
        return label
    }()
    
    private let reactDateLabel: UILabel = {
        let label = UILabel()
        label.text = "1월 20일"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let reactArrowIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        imageView.tintColor = .systemGray3
        return imageView
    }()
    
    private let notionLinkView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let notionImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemIndigo
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let notionLogoImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        imageView.image = UIImage(systemName: "chart.bar.fill", withConfiguration: config)
        imageView.tintColor = .systemCyan
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let notionHeartButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor.label.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "heart.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemPink
        return button
    }()
    
    private let notionShareButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor.label.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray3
        return button
    }()
    
    private let notionTitleLabel = {
        let label = UILabel()
        label.text = "프로젝트 관리 도구"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let notionUrlLabel = {
        let label = UILabel()
        label.text = "https://notion.so"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let notionDescriptionLabel = {
        let label = UILabel()
        label.text = "팀 프로젝트 일정 관리"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private let notionCategoryTag = {
        let view = UIView()
        view.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let notionCategoryLabel = {
        let label = UILabel()
        label.text = "업무"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        return label
    }()
    
    private let notionDateLabel = {
        let label = UILabel()
        label.text = "1월 15일"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let notionArrowIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        imageView.tintColor = .systemGray3
        return imageView
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
        
    }
    
    override func configureHierarchy() {
        [scrollView, floatingAddButton]
            .forEach { view.addSubview($0) }
        
        scrollView.addSubview(contentView)
        
        [statsStackView, categoryHeaderView, categoryScrollView, recentLinksLabel, reactLinkView, notionLinkView]
            .forEach { contentView.addSubview($0) }
        
        [savedLinksView, expiredLinksView]
            .forEach { statsStackView.addArrangedSubview($0) }
        
        savedLinksIconView.addSubview(savedLinksIcon)
        [savedLinksIconView, savedLinksCountLabel, savedLinksTextLabel]
            .forEach { savedLinksView.addSubview($0) }
        
        expiredLinksIconView.addSubview(expiredLinksIcon)
        [expiredLinksIconView, expiredLinksCountLabel, expiredLinksTextLabel]
            .forEach { expiredLinksView.addSubview($0) }
        
        [categoryTitleLabel, addCategoryButton]
            .forEach { categoryHeaderView.addSubview($0) }
        
        categoryScrollView.addSubview(categoryContentView)
        categoryContentView.addSubview(categoryStackView)
        
        [firstRowStackView, secondRowStackView]
            .forEach { categoryStackView.addArrangedSubview($0) }
        
        [workCategoryView, studyCategoryView, shoppingCategoryView]
            .forEach { firstRowStackView.addArrangedSubview($0) }
        
        [personalCategoryView, entertainmentCategoryView, newsCategoryView]
            .forEach { secondRowStackView.addArrangedSubview($0) }
        
        workCategoryIconBg.addSubview(workCategoryIcon)
        [workCategoryIconBg, workCategoryLabel, workCategoryCountLabel]
            .forEach { workCategoryView.addSubview($0) }
        
        studyCategoryIconBg.addSubview(studyCategoryIcon)
        [studyCategoryIconBg, studyCategoryLabel, studyCategoryCountLabel]
            .forEach { studyCategoryView.addSubview($0) }
        
        shoppingCategoryIconBg.addSubview(shoppingCategoryIcon)
        [shoppingCategoryIconBg, shoppingCategoryLabel, shoppingCategoryCountLabel]
            .forEach { shoppingCategoryView.addSubview($0) }
        
        personalCategoryIconBg.addSubview(personalCategoryIcon)
        [personalCategoryIconBg, personalCategoryLabel, personalCategoryCountLabel]
            .forEach { personalCategoryView.addSubview($0) }
        
        entertainmentCategoryIconBg.addSubview(entertainmentCategoryIcon)
        [entertainmentCategoryIconBg, entertainmentCategoryLabel, entertainmentCategoryCountLabel]
            .forEach { entertainmentCategoryView.addSubview($0) }
        
        newsCategoryIconBg.addSubview(newsCategoryIcon)
        [newsCategoryIconBg, newsCategoryLabel, newsCategoryCountLabel]
            .forEach { newsCategoryView.addSubview($0) }
        
        [reactImageView, reactTitleLabel, reactUrlLabel, reactDescriptionLabel, reactCategoryTag, reactDateLabel, reactArrowIcon, reactHeartButton, reactShareButton]
            .forEach { reactLinkView.addSubview($0) }
        
        reactImageView.addSubview(reactLogoImageView)
        reactCategoryTag.addSubview(reactCategoryLabel)
        
        [notionImageView, notionTitleLabel, notionUrlLabel, notionDescriptionLabel, notionCategoryTag, notionDateLabel, notionArrowIcon, notionHeartButton, notionShareButton]
            .forEach { notionLinkView.addSubview($0) }
        
        notionImageView.addSubview(notionLogoImageView)
        notionCategoryTag.addSubview(notionCategoryLabel)
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
        
        categoryScrollView.snp.makeConstraints { make in
            make.top.equalTo(categoryHeaderView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(280)
        }
        
        categoryContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        categoryStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        [firstRowStackView, secondRowStackView].forEach { stackView in
            stackView.snp.makeConstraints { make in
                make.height.equalTo(120)
            }
        }
        
        let categoryViews = [workCategoryView, studyCategoryView, shoppingCategoryView, personalCategoryView, entertainmentCategoryView, newsCategoryView]
        let categoryIconBgs = [workCategoryIconBg, studyCategoryIconBg, shoppingCategoryIconBg, personalCategoryIconBg, entertainmentCategoryIconBg, newsCategoryIconBg]
        let categoryIcons = [workCategoryIcon, studyCategoryIcon, shoppingCategoryIcon, personalCategoryIcon, entertainmentCategoryIcon, newsCategoryIcon]
        let categoryLabels = [workCategoryLabel, studyCategoryLabel, shoppingCategoryLabel, personalCategoryLabel, entertainmentCategoryLabel, newsCategoryLabel]
        let categoryCountLabels = [workCategoryCountLabel, studyCategoryCountLabel, shoppingCategoryCountLabel, personalCategoryCountLabel, entertainmentCategoryCountLabel, newsCategoryCountLabel]
        
        for (index, view) in categoryViews.enumerated() {
            categoryIconBgs[index].snp.makeConstraints { make in
                make.top.equalToSuperview().offset(16)
                make.centerX.equalToSuperview()
                make.size.equalTo(48)
            }
            
            categoryIcons[index].snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            
            categoryLabels[index].snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(categoryIconBgs[index].snp.bottom).offset(12)
            }
            
            categoryCountLabels[index].snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(categoryLabels[index].snp.bottom).offset(4)
            }
        }
        
        recentLinksLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryScrollView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        reactLinkView.snp.makeConstraints { make in
            make.top.equalTo(recentLinksLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(140)
        }
        
        reactImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.size.equalTo(80)
        }
        
        reactLogoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        reactHeartButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalTo(reactShareButton.snp.leading).offset(-8)
            make.size.equalTo(32)
        }
        
        reactShareButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.size.equalTo(32)
        }
        
        reactTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalTo(reactImageView.snp.trailing).offset(16)
            make.trailing.equalTo(reactHeartButton.snp.leading).offset(-16)
        }
        
        reactUrlLabel.snp.makeConstraints { make in
            make.top.equalTo(reactTitleLabel.snp.bottom).offset(4)
            make.leading.equalTo(reactImageView.snp.trailing).offset(16)
            make.trailing.equalTo(reactHeartButton.snp.leading).offset(-16)
        }
        
        reactDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(reactUrlLabel.snp.bottom).offset(8)
            make.leading.equalTo(reactImageView.snp.trailing).offset(16)
            make.trailing.equalTo(reactHeartButton.snp.leading).offset(-16)
        }
        
        reactCategoryTag.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.leading.equalTo(reactImageView.snp.trailing).offset(16)
            make.height.equalTo(24)
        }
        
        reactCategoryLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        
        reactDateLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalTo(reactArrowIcon.snp.leading).offset(-8)
        }
        
        reactArrowIcon.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        notionLinkView.snp.makeConstraints { make in
            make.top.equalTo(reactLinkView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(140)
            make.bottom.equalToSuperview().offset(-100)
        }
        
        notionImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.size.equalTo(80)
        }
        
        notionLogoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        notionHeartButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalTo(notionShareButton.snp.leading).offset(-8)
            make.size.equalTo(32)
        }
        
        notionShareButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.size.equalTo(32)
        }
        
        notionTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalTo(notionImageView.snp.trailing).offset(16)
            make.trailing.equalTo(notionHeartButton.snp.leading).offset(-16)
        }
        
        notionUrlLabel.snp.makeConstraints { make in
            make.top.equalTo(notionTitleLabel.snp.bottom).offset(4)
            make.leading.equalTo(notionImageView.snp.trailing).offset(16)
            make.trailing.equalTo(notionHeartButton.snp.leading).offset(-16)
        }
        
        notionDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(notionUrlLabel.snp.bottom).offset(8)
            make.leading.equalTo(notionImageView.snp.trailing).offset(16)
            make.trailing.equalTo(notionHeartButton.snp.leading).offset(-16)
        }
        
        notionCategoryTag.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.leading.equalTo(notionImageView.snp.trailing).offset(16)
            make.height.equalTo(24)
        }
        
        notionCategoryLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        
        notionDateLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalTo(notionArrowIcon.snp.leading).offset(-8)
        }
        
        notionArrowIcon.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalToSuperview().offset(-16)
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
        
        // 네비게이션 바 배경색을 뷰 배경색과 동일하게 설정
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
}
