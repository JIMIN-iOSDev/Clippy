//
//  LinkListViewController.swift
//  Clippy
//
//  Created by Jimin on 9/26/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class LinkListViewController: BaseViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    var list = BehaviorRelay(value: ["rfkdls", "fdsfjsl", "fdsfsdl"])
    
    // MARK: - UI Components
    private let tableView = {
        let tv = UITableView()
        tv.register(LinkListTableViewCell.self, forCellReuseIdentifier: LinkListTableViewCell.identifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 100
        tv.backgroundColor = .clear
        return tv
    }()
    
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
    override func bind() {
        list
            .bind(to: tableView.rx.items(cellIdentifier: LinkListTableViewCell.identifier, cellType: LinkListTableViewCell.self)) { (row, item, cell) in
                cell.titleLabel.text = item
            }
            .disposed(by: disposeBag)
        
        floatingAddButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                let vc = UINavigationController(rootViewController: EditLinkViewController())
                owner.present(vc, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    override func configureHierarchy() {
        view.addSubview(tableView)
        view.addSubview(floatingAddButton)
    }
    
    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        floatingAddButton.snp.makeConstraints { make in
            make.size.equalTo(56)
            make.trailing.equalToSuperview().offset(-26)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-38)
        }
    }
    
    override func configureView() {
        super.configureView()
    }
}
