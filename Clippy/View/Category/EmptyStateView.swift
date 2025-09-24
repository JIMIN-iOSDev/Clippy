//
//  EmptyStateView.swift
//  Clippy
//
//  Created by Jimin on 9/24/25.
//

import UIKit
import SnapKit

final class EmptyStateView: UIView {
    
    private let logoImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.image = UIImage(systemName: "star")
        return image
    }()
    
    private let addCategoryButton = {
        let button = UIButton(type: .system)
        button.setTitle("카테고리 추가하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
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
        addSubview(logoImageView)
        addSubview(addCategoryButton)
        
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.size.equalTo(100)
        }
        
        addCategoryButton.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }
    }
}
