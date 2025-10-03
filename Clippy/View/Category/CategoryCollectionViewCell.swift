//
//  CategoryCollectionViewCell.swift
//  Clippy
//
//  Created by Jimin on 9/27/25.
//

import UIKit
import SnapKit

final class CategoryCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Callback
    var onEditTapped: (() -> Void)?
    
    private let containerView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        return view
    }()
    
    private let iconBackgroundView = {
        let view = UIView()
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let iconImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let countLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let editButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        contentView.addSubview(containerView)
        iconBackgroundView.addSubview(iconImageView)
        [iconBackgroundView, titleLabel, countLabel, editButton].forEach { containerView.addSubview($0) }
        
        // 버튼 액션 설정
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconBackgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.size.equalTo(48)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.equalTo(iconBackgroundView.snp.bottom).offset(12)
        }
        
        countLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
        
        editButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
            make.size.equalTo(28)
        }
    }
    
    func configure(with item: CategoryItem) {
        titleLabel.text = item.title
        countLabel.text = "\(item.count)개"
        iconBackgroundView.backgroundColor = item.backgroundColor
        
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconImageView.image = UIImage(systemName: item.iconName, withConfiguration: config)
        iconImageView.tintColor = item.iconColor
        
        // 일반 카테고리는 편집 불가
        editButton.isHidden = (item.title == "일반")
    }
    
    // MARK: - Actions
    @objc private func editButtonTapped() {
        print("🔧 편집 버튼 탭됨!")
        onEditTapped?()
    }
}
