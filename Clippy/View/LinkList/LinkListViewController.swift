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
    var categoryName: String = "업무"
    
    private let mockData: [LinkMetadata] = [
        LinkMetadata(
            url: URL(string: "https://notion.so")!, title: "프로젝트 관리 도구",
            description: "팀 프로젝트 일정 관리",
            thumbnailImage: nil, category: "업무",
            createdAt: Date(),
            isLiked: false
        ),
        LinkMetadata(
            url: URL(string: "https://figma.com")!, title: "디자인 시스템",
            description: "UI/UX 디자인 협업 도구",
            thumbnailImage: nil, category: "업무",
            createdAt: Date(),
            isLiked: true
        ),
        LinkMetadata(
            url: URL(string: "https://github.com")!, title: "개발 문서",
            description: "프로젝트 레포지토리",
            thumbnailImage: nil, category: "업무",
            createdAt: Date(),
            isLiked: false
        )
    ]
    
    // MARK: - UI Components
    private let tableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 156
        tableView.register(LinkTableViewCell.self, forCellReuseIdentifier: LinkTableViewCell.identifier)
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
        floatingAddButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.present(UINavigationController(rootViewController: EditLinkViewController()), animated: true)
            }
            .disposed(by: disposeBag)
        
        Observable.just(mockData)
            .bind(to: tableView.rx.items(cellIdentifier: LinkTableViewCell.identifier, cellType: LinkTableViewCell.self)) { index, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)
    }
    
    override func configureHierarchy() {
        [tableView, floatingAddButton].forEach { view.addSubview($0) }
    }
    
    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        floatingAddButton.snp.makeConstraints { make in
            make.size.equalTo(56)
            make.trailing.equalToSuperview().offset(-26)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-38)
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.title = categoryName
    }
}
