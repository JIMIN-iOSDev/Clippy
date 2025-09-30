//
//  SearchViewController.swift
//  Clippy
//
//  Created by Jimin on 9/25/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RealmSwift

final class SearchViewController: BaseViewController {

    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let repository = CategoryRepository()

    private let allLinks = BehaviorRelay<[LinkList]>(value: []) // 전체 링크 데이터
    private let filteredLinks = BehaviorRelay<[LinkList]>(value: []) // 검색 결과

    // MARK: - UI Components
    private let searchBar = {
        let sb = UISearchBar()
        sb.placeholder = "검색어를 입력하세요"
        sb.searchBarStyle = .minimal
        sb.searchTextField.font = UIFont.systemFont(ofSize: 16)
        sb.searchTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return sb
    }()

    private let tableView = {
        let table = UITableView()
        table.separatorStyle = .none
        table.backgroundColor = .systemBackground
        table.register(LinkTableViewCell.self, forCellReuseIdentifier: "LinkTableViewCell")
        return table
    }()

    private let emptyLabel = {
        let label = UILabel()
        label.text = "검색 결과가 없습니다"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.isHidden = true
        return label
    }()

    // MARK: - Configuration
    override func bind() {
        // 검색어 입력 대소문자 구분 없이
        searchBar.rx.text.orEmpty
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .withLatestFrom(allLinks) { query, links -> [LinkList] in
                guard !query.isEmpty else { return Array(links.prefix(20)) }
                return links.filter {
                    $0.title.range(of: query, options: .caseInsensitive) != nil || $0.url.range(of: query, options: .caseInsensitive) != nil
                }
                .prefix(20)
                .map { $0 }
            }
            .bind(to: filteredLinks)
            .disposed(by: disposeBag)

        // 테이블뷰에 데이터 바인딩
        filteredLinks
            .observe(on: MainScheduler.instance)
            .bind(to: tableView.rx.items(cellIdentifier: "LinkTableViewCell", cellType: LinkTableViewCell.self)) { [weak self] row, link, cell in
                guard let self = self else { return }

                cell.configure(with: LinkMetadata(url: URL(string: link.url) ?? URL(string: "https://example.com")!, title: link.title, description: link.memo, thumbnailImage: nil, categories: link.parentCategory.map { (name: $0.name, colorIndex: $0.colorIndex) }, createdAt: link.date, isLiked: link.likeStatus))

                // 즐겨찾기 버튼
                cell.heartTapHandler = {
                    self.toggleLikeStatus(link: link)
                }

                // 공유 버튼
                cell.shareTapHandler = {
                    self.shareLink(link: link)
                }
            }
            .disposed(by: disposeBag)

        // 검색 결과 없을 때
        filteredLinks
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] links in
                self?.emptyLabel.isHidden = !links.isEmpty
            })
            .disposed(by: disposeBag)

        // 테이블뷰 스크롤 시 키보드 숨김
        tableView.rx.contentOffset
            .bind(with: self) { owner, _ in
                owner.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)

        loadLinks()
    }

    override func configureHierarchy() {
        [searchBar, tableView, emptyLabel].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(60)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func configureView() {
        super.configureView()
    }

    private func loadLinks() {
        let categories = repository.readCategoryList()
        let allLinksArray = categories
            .flatMap { $0.category } // 모든 링크 합치기
            .sorted(by: { $0.date > $1.date })
        allLinks.accept(allLinksArray)
        filteredLinks.accept(Array(allLinksArray.prefix(20)))
    }

    private func toggleLikeStatus(link: LinkList) {
        do {
            let realm = try Realm()
            try realm.write {
                link.likeStatus.toggle()
            }
            loadLinks() // 변경 반영
        } catch {
            print("즐겨찾기 상태 변경 실패: \(error.localizedDescription)")
        }
    }

    private func shareLink(link: LinkList) {
        guard let url = URL(string: link.url) else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = view
        present(activityVC, animated: true)
    }
}
