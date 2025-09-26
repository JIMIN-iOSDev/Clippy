//
//  LinkListTableViewCell.swift
//  Clippy
//
//  Created by Jimin on 9/26/25.
//

import UIKit
import SnapKit

class LinkListTableViewCell: UITableViewCell {
    
    // MARK: - UI Components
    private let thumbnailImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    let titleLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let memoLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.text = "memo"
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let deadlineLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.text = "deadline"
        label.textColor = .systemRed
        return label
    }()
    
    private let urlLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.text = "url"
        label.textColor = .systemBlue
        return label
    }()
    
    private let ellipsisButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        button.tintColor = .black
        return button
    }()
    
    private let favoriteButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "star", withConfiguration: config), for: .normal)
        button.setImage(UIImage(systemName: "star.fill", withConfiguration: config), for: .selected)
        button.tintColor = .systemYellow
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureHierarchy()
        configureLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureHierarchy() {
        [thumbnailImageView, titleLabel, memoLabel, deadlineLabel, urlLabel, ellipsisButton, favoriteButton]
            .forEach { contentView.addSubview($0) }
    }
    
    private func configureLayout() {
        thumbnailImageView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(12)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(80)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            make.trailing.equalTo(ellipsisButton.snp.leading).offset(-8)
        }
        
        memoLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
        }
        
        deadlineLabel.snp.makeConstraints { make in
            make.top.equalTo(memoLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
        }
        
        urlLabel.snp.makeConstraints { make in
            make.top.equalTo(deadlineLabel.snp.bottom).offset(2)
            make.leading.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        
        ellipsisButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(20)
        }
        
        favoriteButton.snp.makeConstraints { make in
            make.centerX.equalTo(ellipsisButton)
            make.centerY.equalToSuperview()
            make.size.equalTo(25)
        }
    }
}
