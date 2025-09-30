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
    
    private let emptyStateLabel = {
        let label = UILabel()
        label.text = "즐겨찾기한 링크가 없습니다"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Configuration
    override func bind() {
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
        
        // LinkManager에서 즐겨찾기 링크만 필터링하고 정렬
        let sortedFavoriteLinks = Observable.combineLatest(
            LinkManager.shared.links,
            sortType.asObservable()
        )
        .map { [weak self] (links, sortType) -> [LinkMetadata] in
            guard let self = self else { return [] }
            
            // 즐겨찾기만 필터링
            let favoriteLinks = links.filter { $0.isLiked }
            
            // 정렬
            return self.sortLinks(favoriteLinks, by: sortType)
        }
        
        // Empty state 처리
        sortedFavoriteLinks
            .map { !$0.isEmpty }
            .bind(to: emptyStateLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        sortedFavoriteLinks
            .map { $0.isEmpty }
            .bind(to: tableView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // 테이블뷰 바인딩
        sortedFavoriteLinks
            .bind(to: tableView.rx.items(cellIdentifier: LinkTableViewCell.identifier, cellType: LinkTableViewCell.self)) { [weak self] _, item, cell in
                guard let self = self else { return }
                cell.configure(with: item)
                
                cell.heartTapHandler = {
                    LinkManager.shared.toggleLike(for: item.url)
                        .subscribe()
                        .disposed(by: cell.disposeBag)
                }
                
                cell.shareTapHandler = { [weak self] in
                    let activityViewController = UIActivityViewController(activityItems: [item.url], applicationActivities: nil)
                    self?.present(activityViewController, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
    
    override func configureHierarchy() {
        [sortButtonsStackView, tableView, emptyStateLabel].forEach { view.addSubview($0) }
        
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
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
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
    
    private func sortLinks(_ links: [LinkMetadata], by sortType: SortType) -> [LinkMetadata] {
        switch sortType {
        case .latest:
            return links.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return links.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .deadline:
            return links.sorted { link1, link2 in
                // 마감일이 없는 링크는 뒤로
                guard let date1 = link1.dueDate else { return false }
                guard let date2 = link2.dueDate else { return true }
                return date1 < date2
            }
        }
    }
}
