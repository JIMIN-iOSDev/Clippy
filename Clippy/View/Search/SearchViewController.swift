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

final class SearchViewController: BaseViewController {

    // MARK: - Properties
    private let disposeBag = DisposeBag()

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
    override func configureView() {
        super.configureView()
        
        
        title = "검색"
        
        // 화면 탭 시 키보드 숨김을 위한 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // 다른 뷰의 터치 이벤트를 방해하지 않도록
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    override func bind() {
        // 검색어와 LinkManager의 링크를 결합하여 실시간 검색 결과 생성
        let searchResults = Observable.combineLatest(
            searchBar.rx.text.orEmpty.distinctUntilChanged().debounce(.milliseconds(300), scheduler: MainScheduler.instance),
            LinkManager.shared.links
        )
        .map { query, links -> [LinkMetadata] in
            guard !query.isEmpty else { 
                // 검색어가 없으면 최근 20개만 표시
                return Array(links.sorted { $0.createdAt > $1.createdAt }.prefix(20))
            }
            
            // 제목, URL, 설명에서 검색 (대소문자 구분 없음)
            return links.filter { link in
                link.title.range(of: query, options: .caseInsensitive) != nil ||
                link.url.absoluteString.range(of: query, options: .caseInsensitive) != nil ||
                (link.description?.range(of: query, options: .caseInsensitive) != nil)
            }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(20)
            .map { $0 }
        }

        // 테이블뷰에 직접 바인딩 (filteredLinks 제거)
        searchResults
            .bind(to: tableView.rx.items(cellIdentifier: "LinkTableViewCell", cellType: LinkTableViewCell.self)) { [weak self] row, linkMetadata, cell in
                guard let self = self else { return }

                cell.configure(with: linkMetadata)

                // 읽음 상태 버튼
                cell.readTapHandler = {
                    LinkManager.shared.toggleOpened(for: linkMetadata.url)
                        .subscribe()
                        .disposed(by: cell.disposeBag)
                }
                
                // 즐겨찾기 버튼 - LinkManager 사용
                cell.heartTapHandler = {
                    LinkManager.shared.toggleLike(for: linkMetadata.url)
                        .subscribe()
                        .disposed(by: cell.disposeBag)
                }

                // 공유 버튼
                cell.shareTapHandler = {
                    self.shareLink(url: linkMetadata.url)
                }
            }
            .disposed(by: disposeBag)

        // 검색 결과 없을 때 empty state 표시
        searchResults
            .map { !$0.isEmpty }
            .bind(to: emptyLabel.rx.isHidden)
            .disposed(by: disposeBag)

        // 셀 클릭 시 Safari에서 링크 열기
        tableView.rx.itemSelected
            .do(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .withLatestFrom(searchResults) { indexPath, links in
                links[indexPath.row]
            }
            .subscribe(onNext: { [weak self] link in
                guard let self = self else { return }
                let detailVC = LinkDetailViewController(link: link)
                let navController = UINavigationController(rootViewController: detailVC)
                navController.modalPresentationStyle = .formSheet
                self.present(navController, animated: true)
            })
            .disposed(by: disposeBag)

        // 테이블뷰 스크롤 시 키보드 숨김
        tableView.rx.contentOffset
            .bind(with: self) { owner, _ in
                owner.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)
        
        // 검색 버튼 탭 시 키보드 숨김
        searchBar.rx.searchButtonClicked
            .bind(with: self) { owner, _ in
                owner.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)
    }

    override func configureHierarchy() {
        [searchBar, tableView, emptyLabel].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.horizontalEdges.equalToSuperview().inset(10)
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


    private func shareLink(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = view
        present(activityVC, animated: true)
    }
}
