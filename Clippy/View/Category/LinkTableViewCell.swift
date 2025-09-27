//
//  LinkTableViewCell.swift
//  Clippy
//
//  Created by Jimin on 9/27/25.
//

import UIKit
import SnapKit

final class LinkTableViewCell: UITableViewCell {
    
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
        imageView.backgroundColor = .systemBlue
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
        label.numberOfLines = 2
        return label
    }()
    
    private let categoryTag = {
        let view = UIView()
        view.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let categoryLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemGreen
        return label
    }()
    
    private let dateLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let heartButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor.label.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2
        return button
    }()
    
    private let shareButton = {
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
    
    private let arrowIcon = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        imageView.tintColor = .systemGray3
        return imageView
    }()
    
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
    
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        categoryTag.addSubview(categoryLabel)
        
        [thumbnailImageView, titleLabel, urlLabel, descriptionLabel, categoryTag, dateLabel, arrowIcon, heartButton, shareButton]
            .forEach { containerView.addSubview($0) }
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20))
            make.height.equalTo(140)
        }
        
        thumbnailImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.size.equalTo(80)
        }
        
        heartButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalTo(shareButton.snp.leading).offset(-8)
            make.size.equalTo(32)
        }
        
        shareButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.size.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.trailing.equalTo(heartButton.snp.leading).offset(-16)
        }
        
        urlLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.trailing.equalTo(heartButton.snp.leading).offset(-16)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(urlLabel.snp.bottom).offset(8)
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.trailing.equalTo(heartButton.snp.leading).offset(-16)
        }
        
        categoryTag.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.height.equalTo(24)
        }
        
        categoryLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalTo(arrowIcon.snp.leading).offset(-8)
        }
        
        arrowIcon.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
    }
    
    @objc private func heartButtonTapped() {
        heartTapHandler?()
    }
    
    @objc private func shareButtonTapped() {
        shareTapHandler?()
    }
    
    func configure(with link: LinkMetadata) {
        titleLabel.text = link.title
        urlLabel.text = link.url.absoluteString
        descriptionLabel.text = link.description ?? ""
        categoryLabel.text = link.category ?? "일반"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M월 d일"
        dateLabel.text = dateFormatter.string(from: link.createdAt)
        
        if let thumbnailImage = link.thumbnailImage {
            thumbnailImageView.image = thumbnailImage
            thumbnailImageView.backgroundColor = .clear
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
            thumbnailImageView.image = UIImage(systemName: "link", withConfiguration: config)
            thumbnailImageView.backgroundColor = .systemBlue
            thumbnailImageView.tintColor = .systemCyan
        }
        
        let heartImageName = link.isLiked ? "heart.fill" : "heart"
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        heartButton.setImage(UIImage(systemName: heartImageName, withConfiguration: config), for: .normal)
        heartButton.tintColor = link.isLiked ? .systemPink : .systemGray3
    }
}
