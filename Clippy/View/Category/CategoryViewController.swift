//
//  CategoryViewController.swift
//  Clippy
//
//  Created by Jimin on 9/24/25.
//

import UIKit
import SnapKit

final class CategoryViewController: BaseViewController {
    // MARK: - Properties
    
    // MARK: - UI Components
    private let sortButton = UIButton.makeSortToggleButton()
    private let emptyView = EmptyStateView()
    private let floatingAddButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 28
        button.clipsToBounds = true
        return button
    }()
    
    // MARK: - Configuration
    override func configureBind() {
        
    }
    
    override func configureHierarchy() {
        view.addSubview(emptyView)
        view.addSubview(floatingAddButton)
    }
    
    override func configureLayout() {
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
        sortButton.sizeToFit()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sortButton)
    }
}
