//
//  LikeViewController.swift
//  Clippy
//
//  Created by Jimin on 9/25/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class LikeViewController: BaseViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let sortType = BehaviorRelay<SortType>(value: .latest)
    private let mockLinks = BehaviorRelay<[LinkMetadata]>(value: [])
    
    enum SortType {
        case latest, title, deadline
    }
    
    // MARK: - UI Components
    private let sortButtonsStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    private let latestButton = {
        let button = UIButton(type: .system)
        button.setTitle("최근 추가순", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return button
    }()
    
    private let titleSortButton = {
        let button = UIButton(type: .system)
        button.setTitle("제목순", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return button
    }()
    
    private let deadlineSortButton = {
        let button = UIButton(type: .system)
        button.setTitle("마감일순", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        return button
    }()
    
    private let tableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.register(LinkTableViewCell.self, forCellReuseIdentifier: LinkTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 156
        return tableView
    }()
    
    // MARK: - Configuration
    override func bind() {
        // Mock 데이터 생성
        createMockData()
        
        // 정렬 버튼 탭 이벤트
        latestButton.rx.tap
            .map { SortType.latest }
            .bind(to: sortType)
            .disposed(by: disposeBag)
        
        titleSortButton.rx.tap
            .map { SortType.title }
            .bind(to: sortType)
            .disposed(by: disposeBag)
        
        deadlineSortButton.rx.tap
            .map { SortType.deadline }
            .bind(to: sortType)
            .disposed(by: disposeBag)
        
        // 정렬 타입에 따른 버튼 스타일 변경
        sortType
            .subscribe(onNext: { [weak self] type in
                self?.updateSortButtonStyles(selectedType: type)
            })
            .disposed(by: disposeBag)
        
        // 테이블뷰 바인딩
        mockLinks
            .bind(to: tableView.rx.items(cellIdentifier: LinkTableViewCell.identifier, cellType: LinkTableViewCell.self)) { [weak self] _, item, cell in
                guard let self = self else { return }
                cell.configure(with: item)
                
                cell.heartTapHandler = {
                    var currentLinks = self.mockLinks.value
                    if let index = currentLinks.firstIndex(where: { $0.url == item.url }) {
                        var updatedItem = currentLinks[index]
                        // LinkMetadata의 isLiked를 토글 (struct라면 새로 생성)
                        currentLinks[index] = LinkMetadata(
                            url: updatedItem.url,
                            title: updatedItem.title,
                            description: updatedItem.description,
                            thumbnailImage: updatedItem.thumbnailImage,
                            categories: updatedItem.categories,
                            dueDate: updatedItem.dueDate,
                            createdAt: updatedItem.createdAt,
                            isLiked: !updatedItem.isLiked
                        )
                        self.mockLinks.accept(currentLinks)
                    }
                }
                
                cell.shareTapHandler = { [weak self] in
                    let activityViewController = UIActivityViewController(activityItems: [item.url], applicationActivities: nil)
                    self?.present(activityViewController, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
    
    override func configureHierarchy() {
        [sortButtonsStackView, tableView].forEach { view.addSubview($0) }
        
        [latestButton, titleSortButton, deadlineSortButton].forEach { sortButtonsStackView.addArrangedSubview($0) }
    }
    
    override func configureLayout() {
        sortButtonsStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(36)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(sortButtonsStackView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    override func configureView() {
        super.configureView()
        title = "즐겨찾기"
    }
    
    // MARK: - Private Methods
    private func updateSortButtonStyles(selectedType: SortType) {
        let buttons: [(UIButton, SortType)] = [(latestButton, .latest), (titleSortButton, .title), (deadlineSortButton, .deadline)]
        
        buttons.forEach { button, type in
            if type == selectedType {
                button.backgroundColor = .systemRed
                button.setTitleColor(.white, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            } else {
                button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
                button.setTitleColor(.label, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            }
        }
    }
    
    private func createMockData() {
        let mockData: [LinkMetadata] = [
            LinkMetadata(
                url: URL(string: "https://react.dev")!,
                title: "React 공식 문서",
                description: "React 18 새로운 기능들 학습하기",
                thumbnailImage: nil,
                categories: [(name: "학습", colorIndex: 2)],
                dueDate: Date().addingTimeInterval(86400 * 20),
                createdAt: Date(),
                isLiked: true
            ),
            LinkMetadata(
                url: URL(string: "https://developer.apple.com/swift")!,
                title: "Swift Programming Language",
                description: "Swift 공식 문서 및 가이드",
                thumbnailImage: nil,
                categories: [(name: "개발", colorIndex: 1)],
                dueDate: Date().addingTimeInterval(86400 * 15),
                createdAt: Date().addingTimeInterval(-86400),
                isLiked: true
            ),
            LinkMetadata(
                url: URL(string: "https://github.com")!,
                title: "GitHub",
                description: "코드 저장소 및 협업 플랫폼",
                thumbnailImage: nil,
                categories: [(name: "개발", colorIndex: 1)],
                dueDate: Date().addingTimeInterval(86400 * 10),
                createdAt: Date().addingTimeInterval(-86400 * 2),
                isLiked: true
            )
        ]
        
        mockLinks.accept(mockData)
    }
}
