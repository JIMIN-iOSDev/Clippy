//
//  LinkTableViewCell.swift
//  Clippy
//
//  Created by Jimin on 9/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class LinkTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    private let containerView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let thumbnailImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let titleLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let urlLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let descriptionLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 1
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
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()

    
    private let dateLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let readButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "circle", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray3
        return button
    }()
    
    private let heartButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "star", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray3
        return button
    }()
    
    private let shareButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        let image = UIImage(named: "share-icon")
        button.setImage(image, for: .normal)
        button.tintColor = .systemGray3
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    private let arrowIcon = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        imageView.tintColor = .systemGray3
        return imageView
    }()
    
    var readTapHandler: (() -> Void)?
    var heartTapHandler: (() -> Void)?
    var shareTapHandler: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        
        [thumbnailImageView, titleLabel, urlLabel, descriptionLabel, dateLabel, readButton, heartButton, shareButton, categoryTagsScrollView]
            .forEach { containerView.addSubview($0) }
        
        categoryTagsScrollView.addSubview(categoryTagsStackView)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20))
            make.height.equalTo(136)
        }
        
        thumbnailImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.size.equalTo(80)
        }
        
        readButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalTo(heartButton.snp.leading).offset(-8)
            make.size.equalTo(24)
        }
        
        heartButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalTo(shareButton.snp.leading).offset(-5)
            make.size.equalTo(24)
        }
        
        shareButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-12)
            make.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.trailing.equalTo(readButton.snp.leading).offset(-16)
        }
        
        urlLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(urlLabel.snp.bottom).offset(8)
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        // 카테고리 태그 ScrollView는 남은 공간에만 표시
        categoryTagsScrollView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.height.equalTo(24)
        }
        
        // 마감일과 화살표를 먼저 배치하고 centerY를 카테고리와 맞춤
        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(categoryTagsScrollView)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        // ScrollView의 trailing을 dateLabel 기준으로 설정
        categoryTagsScrollView.snp.makeConstraints { make in
            make.trailing.equalTo(dateLabel.snp.leading).offset(-8)
        }
        
        categoryTagsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        readButton.addTarget(self, action: #selector(readButtonTapped), for: .touchUpInside)
    }
    
    @objc private func readButtonTapped() {
        readTapHandler?()
    }
    
    @objc private func heartButtonTapped() {
        heartTapHandler?()
    }
    
    @objc private func shareButtonTapped() {
        shareTapHandler?()
    }
    
    // MARK: - Animation and Tooltip Methods
    
    func showSwipeHint() {
        // 왼쪽으로 천천히 슬라이드하는 애니메이션
        UIView.animate(withDuration: 1.0, delay: 0, options: [.curveEaseInOut], animations: {
            self.transform = CGAffineTransform(translationX: -50, y: 0)
        }) { _ in
            // 원위치로 돌아오기
            UIView.animate(withDuration: 0.5) {
                self.transform = .identity
            }
        }
    }
    
    func removeShadow() {
        containerView.layer.shadowOpacity = 0
    }
    
    func restoreShadow() {
        containerView.layer.shadowOpacity = 0.1
    }
    
    func configure(with link: LinkMetadata) {
        titleLabel.text = link.title
        urlLabel.text = link.url.absoluteString

        // 설명 표시 우선순위: userMemo > metadataDescription
        if let userMemo = link.userMemo, !userMemo.isEmpty {
            descriptionLabel.text = userMemo
            descriptionLabel.isHidden = false
        } else if let metadataDescription = link.metadataDescription, !metadataDescription.isEmpty {
            descriptionLabel.text = metadataDescription
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }
        
        // 마감일 표시 로직
        if let dueDate = link.dueDate {
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let startOfDueDate = calendar.startOfDay(for: dueDate)
            
            let daysDifference = calendar.dateComponents([.day], from: startOfToday, to: startOfDueDate).day ?? 0
            
            let clockIcon = "clock"
            let clockConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            let clockImage = UIImage(systemName: clockIcon, withConfiguration: clockConfig)
            
            let attachment = NSTextAttachment()
            attachment.image = clockImage
            
            let attributedString = NSMutableAttributedString()
            
            if daysDifference < 0 {
                // 마감일 지남
                attachment.image = clockImage?.withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
                attributedString.append(NSAttributedString(attachment: attachment))
                attributedString.append(NSAttributedString(string: " 마감"))
                dateLabel.textColor = .secondaryLabel
            } else if daysDifference == 0 {
                // 오늘 마감
                attachment.image = clockImage?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
                attributedString.append(NSAttributedString(attachment: attachment))
                attributedString.append(NSAttributedString(string: " 오늘"))
                dateLabel.textColor = .systemRed
            } else if daysDifference <= 3 {
                // 3일 이내 - 빨간색으로 표시
                attachment.image = clockImage?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
                attributedString.append(NSAttributedString(attachment: attachment))
                attributedString.append(NSAttributedString(string: " \(daysDifference)일 남음"))
                dateLabel.textColor = .systemRed
            } else {
                // 3일 이후 - 기본 색상으로 날짜 표시
                attachment.image = clockImage?.withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
                attributedString.append(NSAttributedString(attachment: attachment))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "M월 d일"
                attributedString.append(NSAttributedString(string: " \(dateFormatter.string(from: dueDate))"))
                dateLabel.textColor = .secondaryLabel
            }
            
            dateLabel.attributedText = attributedString
        } else {
            // 마감일 없음에도 clock 아이콘 추가
            let clockIcon = "clock"
            let clockConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            let clockImage = UIImage(systemName: clockIcon, withConfiguration: clockConfig)
            
            let attachment = NSTextAttachment()
            attachment.image = clockImage?.withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
            
            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(attachment: attachment))
            attributedString.append(NSAttributedString(string: " 마감일 없음"))
            
            dateLabel.attributedText = attributedString
            dateLabel.textColor = .secondaryLabel
        }
        
        // 썸네일 이미지 - 이미지가 있으면 표시, 없으면 기본 앱 로고 표시
        if let thumbnailImage = link.thumbnailImage {
            thumbnailImageView.image = thumbnailImage
            thumbnailImageView.backgroundColor = .clear
            thumbnailImageView.contentMode = .scaleAspectFill
        } else {
            // 이미지가 없으면 기본 앱 로고 표시
            thumbnailImageView.image = UIImage(named: "AppLogo")
            thumbnailImageView.backgroundColor = .clear
            thumbnailImageView.contentMode = .scaleAspectFit
        }
        
        // 즐겨찾기 (별 모양)
        let starImageName = link.isLiked ? "star.fill" : "star"
        let starConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        heartButton.setImage(UIImage(systemName: starImageName, withConfiguration: starConfig), for: .normal)
        heartButton.tintColor = link.isLiked ? .systemYellow : .systemGray3
        
        // 읽음 상태 표시
        let readConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let readImageName = link.isOpened ? "checkmark.circle.fill" : "circle"
        readButton.setImage(UIImage(systemName: readImageName, withConfiguration: readConfig), for: .normal)
        readButton.tintColor = link.isOpened ? .clippyBlue : .systemGray3
        
        // 카테고리 태그들 (여러 개 표시)
        categoryTagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let categories = link.categories, !categories.isEmpty {
            categories.forEach { categoryInfo in
                let tagView = createCategoryTag(name: categoryInfo.name, color: CategoryColor.color(index: categoryInfo.colorIndex))
                categoryTagsStackView.addArrangedSubview(tagView)
            }
        } else {
            // 카테고리 정보 설정 안하면 "일반"
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
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        }
        
        return containerView
    }
}
