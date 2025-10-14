//
//  LinkDetailViewController.swift
//  Clippy
//
//  Created by Jimin on 10/19/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class LinkDetailViewController: BaseViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let link: LinkMetadata
    private let repository = CategoryRepository()
    
    // MARK: - UI Components
    private let scrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView = {
        let view = UIView()
        return view
    }()
    
    private let containerView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let thumbnailImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let descriptionLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private let urlButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.systemBlue, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return button
    }()
    
    private let categorySectionLabel = {
        let label = UILabel()
        label.text = "카테고리"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let categoryTagsScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let categoryTagsStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    private let memoSectionLabel = {
        let label = UILabel()
        label.text = "메모"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let memoLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let memoContainerView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let deadlineSectionLabel = {
        let label = UILabel()
        label.text = "마감일"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let deadlineLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        return label
    }()
    
    private let actionButtonsStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let unreadButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        return button
    }()
    
    private let favoriteButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        return button
    }()
    
    private let deleteButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        return button
    }()
    
    // MARK: - Initialization
    init(link: LinkMetadata) {
        self.link = link
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureWithLink()
    }
    
    // MARK: - Configuration
    private func configureUI() {
        view.backgroundColor = .white
        
        // 네비게이션 설정
        navigationItem.title = "링크 상세"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .black
        
        // UI 계층 구조 설정
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(containerView)
        
        [thumbnailImageView, titleLabel, descriptionLabel, urlButton, 
         categorySectionLabel, categoryTagsScrollView,
         memoSectionLabel, memoContainerView,
         deadlineSectionLabel, deadlineLabel,
         actionButtonsStackView].forEach { containerView.addSubview($0) }
        
        memoContainerView.addSubview(memoLabel)
        categoryTagsScrollView.addSubview(categoryTagsStackView)
        
        [unreadButton, favoriteButton, deleteButton].forEach { actionButtonsStackView.addArrangedSubview($0) }
        
        // 레이아웃 설정
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        thumbnailImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(100)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnailImageView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        urlButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        categorySectionLabel.snp.makeConstraints { make in
            make.top.equalTo(urlButton.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        categoryTagsScrollView.snp.makeConstraints { make in
            make.top.equalTo(categorySectionLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(32)
        }
        
        categoryTagsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        memoSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryTagsScrollView.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        memoContainerView.snp.makeConstraints { make in
            make.top.equalTo(memoSectionLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        memoLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        
        deadlineSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(memoContainerView.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        deadlineLabel.snp.makeConstraints { make in
            make.top.equalTo(deadlineSectionLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        actionButtonsStackView.snp.makeConstraints { make in
            make.top.equalTo(deadlineLabel.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    override func bind() {
        // URL 버튼 클릭 시 사파리로 이동
        urlButton.rx.tap
            .bind(with: self) { owner, _ in
                if UIApplication.shared.canOpenURL(owner.link.url) {
                    UIApplication.shared.open(owner.link.url, options: [:], completionHandler: nil)
                }
            }
            .disposed(by: disposeBag)
        
        // 즐겨찾기 버튼 클릭
        favoriteButton.rx.tap
            .bind(with: self) { owner, _ in
                LinkManager.shared.toggleLike(for: owner.link.url)
                    .subscribe(onNext: { updatedLink in
                        if let updatedLink = updatedLink {
                            // UI 즉시 업데이트
                            let starImageName = updatedLink.isLiked ? "star.fill" : "star"
                            owner.favoriteButton.setImage(UIImage(systemName: starImageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)), for: .normal)
                            owner.favoriteButton.tintColor = updatedLink.isLiked ? .systemYellow : .systemGray3
                        }
                    })
                    .disposed(by: owner.disposeBag)
            }
            .disposed(by: disposeBag)
        
        // 삭제 버튼 클릭
        deleteButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.showDeleteAlert()
            }
            .disposed(by: disposeBag)
        
        // 읽음 상태 버튼 클릭 (임시로 구현)
        unreadButton.rx.tap
            .bind(with: self) { owner, _ in
                // 읽음 상태 토글 로직 (추후 구현)
                print("읽음 상태 토글")
            }
            .disposed(by: disposeBag)
    }
    
    private func configureWithLink() {
        // 제목 설정
        titleLabel.text = link.title
        
        // 설명 설정 - 메타데이터 설명 표시
        if let description = link.description, !description.isEmpty {
            descriptionLabel.text = description
            descriptionLabel.textColor = .secondaryLabel
        } else {
            descriptionLabel.text = "설명이 없습니다"
            descriptionLabel.textColor = .secondaryLabel
        }
        
        // URL 버튼 설정
        let urlString = link.url.absoluteString
        urlButton.setTitle(urlString, for: .normal)
        
        // 섹션 타이틀에 아이콘 추가
        configureSectionLabels()
        
        // 썸네일 이미지 설정
        if let thumbnailImage = link.thumbnailImage {
            thumbnailImageView.image = thumbnailImage
            thumbnailImageView.backgroundColor = .clear
            thumbnailImageView.contentMode = .scaleAspectFit
        } else {
            // 이미지가 없으면 기본 앱 로고 표시
            thumbnailImageView.image = UIImage(named: "AppLogo")
            thumbnailImageView.backgroundColor = .systemGray6
            thumbnailImageView.contentMode = .scaleAspectFit
        }
        
        // 카테고리 태그 설정
        configureCategoryTags()
        
        // 메모 설정
        configureMemo()
        
        // 마감일 설정
        configureDeadline()
        
        // 액션 버튼 설정
        configureActionButtons()
    }
    
    private func configureCategoryTags() {
        // 기존 태그들 제거
        categoryTagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let categories = link.categories, !categories.isEmpty {
            categories.forEach { categoryInfo in
                let tagView = createCategoryTag(name: categoryInfo.name, color: CategoryColor.color(index: categoryInfo.colorIndex))
                categoryTagsStackView.addArrangedSubview(tagView)
            }
        } else {
            // 카테고리 정보가 없으면 "일반" 표시
            let tagView = createCategoryTag(name: "일반", color: CategoryColor.color(index: 0))
            categoryTagsStackView.addArrangedSubview(tagView)
        }
    }
    
    private func createCategoryTag(name: String, color: UIColor) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = color.withAlphaComponent(0.15)
        containerView.layer.cornerRadius = 8
        
        let label = UILabel()
        label.text = name
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = color
        
        containerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        }
        
        return containerView
    }
    
    private func configureMemo() {
        // 메모 표시 로직: 사용자 입력 메모만 표시, 없으면 placeholder
        var memoText = ""
        
        // 사용자가 입력한 메모가 있는지 확인 (Realm에서 가져와야 함)
        if let realmLink = repository.getLinkByURL(link.url.absoluteString),
           let userMemo = realmLink.memo, !userMemo.isEmpty {
            memoText = userMemo
        } else {
            // 사용자 메모가 없으면 placeholder 표시
            memoText = "메모가 없습니다"
        }
        
        memoLabel.text = memoText
        memoLabel.textColor = memoText == "메모가 없습니다" ? .secondaryLabel : .label
    }
    
    private func configureDeadline() {
        if let dueDate = link.dueDate {
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let startOfDueDate = calendar.startOfDay(for: dueDate)
            
            let daysDifference = calendar.dateComponents([.day], from: startOfToday, to: startOfDueDate).day ?? 0
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy년 M월 d일"
            
            if daysDifference < 0 {
                deadlineLabel.text = "\(dateFormatter.string(from: dueDate)) (마감)"
                deadlineLabel.textColor = .secondaryLabel
            } else if daysDifference == 0 {
                deadlineLabel.text = "\(dateFormatter.string(from: dueDate)) (오늘)"
                deadlineLabel.textColor = .systemRed
            } else if daysDifference <= 3 {
                deadlineLabel.text = "\(dateFormatter.string(from: dueDate)) (\(daysDifference)일 남음)"
                deadlineLabel.textColor = .systemRed
            } else {
                deadlineLabel.text = dateFormatter.string(from: dueDate)
                deadlineLabel.textColor = .label
            }
        } else {
            deadlineLabel.text = "마감일 없음"
            deadlineLabel.textColor = .secondaryLabel
        }
    }
    
    private func configureActionButtons() {
        // 읽음 상태 버튼
        let unreadConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        unreadButton.setImage(UIImage(systemName: "circle", withConfiguration: unreadConfig), for: .normal)
        unreadButton.setTitle("안읽음", for: .normal)
        
        // 즐겨찾기 버튼
        let favoriteConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let starImageName = link.isLiked ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: starImageName, withConfiguration: favoriteConfig), for: .normal)
        favoriteButton.setTitle("즐겨찾기", for: .normal)
        favoriteButton.tintColor = link.isLiked ? .systemYellow : .systemGray3
        
        // 삭제 버튼
        let deleteConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        deleteButton.setImage(UIImage(systemName: "trash", withConfiguration: deleteConfig), for: .normal)
        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.tintColor = .systemRed
    }
    
    private func showDeleteAlert() {
        let alert = UIAlertController(title: "링크 삭제", message: "이 링크를 삭제하시겠습니까?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            self.repository.deleteLink(url: self.link.url.absoluteString)
            LinkManager.shared.deleteLink(url: self.link.url)
                .subscribe(onNext: { [weak self] _ in
                    self?.dismiss(animated: true)
                })
                .disposed(by: self.disposeBag)
        })
        
        present(alert, animated: true)
    }
    
    private func configureSectionLabels() {
        // 카테고리 섹션에 북마크 아이콘 추가
        let bookmarkIcon = UIImage(systemName: "bookmark")
        let bookmarkAttachment = NSTextAttachment()
        bookmarkAttachment.image = bookmarkIcon?.withTintColor(.label, renderingMode: .alwaysOriginal)
        bookmarkAttachment.bounds = CGRect(x: 0, y: -2, width: 16, height: 16)
        
        let bookmarkAttributedString = NSMutableAttributedString()
        bookmarkAttributedString.append(NSAttributedString(attachment: bookmarkAttachment))
        bookmarkAttributedString.append(NSAttributedString(string: " 카테고리"))
        categorySectionLabel.attributedText = bookmarkAttributedString
        
        // 메모 섹션에 문서 아이콘 추가
        let documentIcon = UIImage(systemName: "doc.text")
        let documentAttachment = NSTextAttachment()
        documentAttachment.image = documentIcon?.withTintColor(.label, renderingMode: .alwaysOriginal)
        documentAttachment.bounds = CGRect(x: 0, y: -2, width: 16, height: 16)
        
        let documentAttributedString = NSMutableAttributedString()
        documentAttributedString.append(NSAttributedString(attachment: documentAttachment))
        documentAttributedString.append(NSAttributedString(string: " 메모"))
        memoSectionLabel.attributedText = documentAttributedString
        
        // 마감일 섹션에 시계 아이콘 추가
        let clockIcon = UIImage(systemName: "clock")
        let clockAttachment = NSTextAttachment()
        clockAttachment.image = clockIcon?.withTintColor(.label, renderingMode: .alwaysOriginal)
        clockAttachment.bounds = CGRect(x: 0, y: -2, width: 16, height: 16)
        
        let clockAttributedString = NSMutableAttributedString()
        clockAttributedString.append(NSAttributedString(attachment: clockAttachment))
        clockAttributedString.append(NSAttributedString(string: " 마감일"))
        deadlineSectionLabel.attributedText = clockAttributedString
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
