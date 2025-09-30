//
//  EditLinkViewController.swift
//  Clippy
//
//  Created by Jimin on 9/26/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class EditLinkViewController: BaseViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let repository = CategoryRepository()
    private let selectedCategories = BehaviorRelay<[String]>(value: [])
    
    private let categories = BehaviorRelay<[Category]>(value: [])
    
    // MARK: - UI Components
    private let scrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let urlLabel = {
        let label = UILabel()
        label.text = "링크 URL *"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let urlTextField = {
        let textField = UITextField()
        textField.placeholder = "https://example.com"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 0))
        textField.leftViewMode = .always
        textField.rightViewMode = .always
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        return textField
    }()
    
    private let linkIconImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        imageView.image = UIImage(systemName: "link", withConfiguration: config)
        imageView.tintColor = .systemGray3
        return imageView
    }()
    
    private let titleSectionLabel = {
        let label = UILabel()
        label.text = "제목"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let titleTextField = {
        let textField = UITextField()
        textField.placeholder = "링크 제목을 입력하세요"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.rightViewMode = .always
        return textField
    }()
    
    private let memoLabel = {
        let label = UILabel()
        label.text = "메모"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let memoTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.isScrollEnabled = false
        return textView
    }()
    
    private let memoPlaceholderLabel = {
        let label = UILabel()
        label.text = "메모나 설명을 입력하세요"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .placeholderText
        return label
    }()
    
    private let categoryLabel = {
        let label = UILabel()
        label.text = "카테고리"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let categoryTagsStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    private let categoryTagsScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let dueDateLabel = {
        let label = UILabel()
        label.text = "마감일 설정"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let dueDateTextField = {
        let textField = UITextField()
        textField.placeholder = "연도. 월. 일."
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 0))
        textField.leftViewMode = .always
        textField.rightViewMode = .always
        return textField
    }()
    
    private let calendarIconImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        imageView.image = UIImage(systemName: "calendar", withConfiguration: config)
        imageView.tintColor = .systemGray3
        return imageView
    }()
    
    private let saveButton = {
        let button = UIButton(type: .system)
        button.setTitle("저장하기", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let datePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        return picker
    }()
    
    // MARK: - Configuration
    override func bind() {
        categories
            .bind(with: self) { owner, categories in
                owner.createCategoryButtons(categories)
            }
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.categoryDidCreate)
            .bind(with: self) { owner, _ in
                owner.loadCategories()
            }
            .disposed(by: disposeBag)
        
        selectedCategories
            .bind(with: self) { owner, selected in
                owner.updateButtonStyles(selected: selected)
            }
            .disposed(by: disposeBag)
        
        // URL 메타데이터 가져오기
        urlTextField.rx.text.orEmpty
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { urlString -> Observable<LinkMetadata?> in
                guard !urlString.isEmpty, let url = URL(string: urlString) else { return Observable.just(nil) }
                
                return LinkManager.shared.fetchLinkMetadata(for: url)
                    .map { Optional($0) }
                    .catch { _ in Observable.just(nil) }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] metadata in
                guard let self = self, let metadata = metadata else { return }
                //
                //                // 자동으로 제목 설정 (사용자가 입력하지 않은 경우)
                //                if self.titleTextField.text?.isEmpty == true {
                //                    self.titleTextField.text = metadata.title
                //                }
            })
            .disposed(by: disposeBag)
        
//        saveButton.rx.tap
//            .withLatestFrom(Observable.combineLatest(urlTextField.rx.text.orEmpty, titleTextField.rx.text.orEmpty, memoTextView.rx.text.orEmpty, selectedCategories.asObservable(), datePicker.rx.date))
//            .flatMapLatest { [weak self] urlString, title, memo, selectedCategories, dueDate -> Observable<[LinkMetadata]> in
//                guard let self = self, let url = URL(string: urlString), !selectedCategories.isEmpty else {
//                    return Observable.just([])
//                }
//                
//                let finalTitle = title.isEmpty ? nil : title
//                let finalMemo = memo.isEmpty ? nil : memo
//                
//                let targetCategories = selectedCategories.isEmpty ? ["일반"] : selectedCategories
//                
//                targetCategories.forEach { categoryName in
//                    self.repository.addLink(title: finalTitle ?? urlString, url: urlString, description: finalMemo, categoryName: categoryName, deadline: dueDate)
//                }
//                
//                let categoryInfos: [(name: String, colorIndex: Int)] = targetCategories.compactMap { name in
//                    guard let category = self.repository.readCategory(name: name) else { return nil }
//                    return (name: category.name, colorIndex: category.colorIndex)
//                }
//                
//                //                // 각 카테고리마다 링크 추가 (Observable 배열)
//                //                let observables = selectedCategories.map { categoryName -> Observable<LinkMetadata> in
//                //                    // 1. Realm에 저장
//                //                    self.repository.addLink(title: finalTitle ?? urlString, url: urlString, description: finalMemo, categoryName: categoryName, deadline: dueDate)
//                //
//                //                    // 2. LinkManager에도 추가 (캐시 및 UI 업데이트)
//                //                    return LinkManager.shared.addLink(url: url, title: finalTitle, descrpition: finalMemo, category: categoryName, dueDate: dueDate)
//                
//                return LinkManager.shared.addLink(
//                    url: url,
//                    title: finalTitle,
//                    descrpition: finalMemo,
//                    categories: categoryInfos,
//                    dueDate: dueDate
//                )
//            
//        
//        //                return Observable.zip(observables)
//    }
//            .observe(on: MainScheduler.instance)
//            .bind(with: self) { owner, _ in
//                NotificationCenter.default.post(name: .linkDidCreate, object: nil)
//                owner.dismiss(animated: true)
//            }
//            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .withLatestFrom(Observable.combineLatest(urlTextField.rx.text.orEmpty, titleTextField.rx.text.orEmpty, memoTextView.rx.text.orEmpty, selectedCategories.asObservable(), datePicker.rx.date))
            .flatMapLatest { [weak self] urlString, title, memo, selectedCategories, dueDate -> Observable<LinkMetadata> in
                guard let self = self,
                      let url = URL(string: urlString) else {
                    return Observable.empty()
                }
                
                let finalTitle = title.isEmpty ? nil : title
                let finalMemo = memo.isEmpty ? nil : memo
                
                // 카테고리 선택 안했으면 "일반"에 저장
                let targetCategories = selectedCategories.isEmpty ? ["일반"] : selectedCategories
                
                // 각 카테고리마다 Realm에 저장
                targetCategories.forEach { categoryName in
                    self.repository.addLink(title: finalTitle ?? urlString, url: urlString, description: finalMemo, categoryName: categoryName, deadline: dueDate)
                }
                
                // 카테고리 정보 가져오기 (색상 포함)
                let categoryInfos: [(name: String, colorIndex: Int)] = targetCategories.compactMap { name in
                    guard let category = self.repository.readCategory(name: name) else { return nil }
                    return (name: category.name, colorIndex: category.colorIndex)
                }
                
                // LinkManager에 추가 (여러 카테고리 정보 포함)
                return LinkManager.shared.addLink(url: url, title: finalTitle, descrpition: finalMemo, categories: categoryInfos, dueDate: dueDate)
            }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                // 링크 추가 알림 발송
                NotificationCenter.default.post(name: .linkDidCreate, object: nil)
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
        // 로딩 상태 바인딩
        LinkManager.shared.isLoading
            .map { !$0 }
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // 선택된 마감일 TextField에 바인딩
        dueDateTextField.inputView = datePicker
        
        datePicker.rx.date
            .map { DateFormatter.displayFormatter.string(from: $0) }
            .bind(to: dueDateTextField.rx.text)
            .disposed(by: disposeBag)
        
        // 완료 버튼 툴바
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "완료", style: .done, target: nil, action: nil)
        toolbar.setItems([doneButton], animated: true)
        dueDateTextField.inputAccessoryView = toolbar
        
        // 완료 버튼 탭 -> 키보드 닫기
        doneButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dueDateTextField.resignFirstResponder()
            }
            .disposed(by: disposeBag)
    }
    
    private func loadCategories() {
        let realmCategories = repository.readCategoryList()
        categories.accept(realmCategories)
        createCategoryButtons(realmCategories)
    }
    
    private func createCategoryButtons(_ categories: [Category]) {
        categoryTagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() } // 기존 버튼 제거
        
        // 새로운 버튼 생성
        categories.forEach { category in
            let button = UIButton(type: .system)
            button.setTitle(category.name, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.layer.cornerRadius = 12
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            
            categoryTagsStackView.addArrangedSubview(button)
            
            button.rx.tap
                .withLatestFrom(selectedCategories) { (_, current) -> [String] in
                    var updated = current
                    if updated.contains(category.name) {
                        updated.removeAll { $0 == category.name }
                    } else {
                        updated.append(category.name)
                    }
                    return updated
                }
                .bind(to: selectedCategories)
                .disposed(by: disposeBag)
        }
    }
    
    private func updateButtonStyles(selected: [String]) {
        for (index, view) in categoryTagsStackView.arrangedSubviews.enumerated() {
            guard let button = view as? UIButton, index < categories.value.count else { continue }
            
            let category = categories.value[index]
            let isSelected = selected.contains(category.name)
            
            button.backgroundColor = isSelected ? .systemBlue : .systemGray6
            button.setTitleColor(isSelected ? .white : .label, for: .normal)
            button.layer.borderColor = (isSelected ? UIColor.systemBlue : UIColor.systemGray4).cgColor
        }
    }
    
    override func configureHierarchy() {
        [scrollView, saveButton].forEach { view.addSubview($0) }
        
        scrollView.addSubview(contentView)
        
        [urlLabel, urlTextField, titleSectionLabel, titleTextField, memoLabel, memoTextView, categoryLabel, categoryTagsScrollView, dueDateLabel, dueDateTextField].forEach { contentView.addSubview($0) }
        
        urlTextField.addSubview(linkIconImageView)
        
        memoTextView.addSubview(memoPlaceholderLabel)
        
        categoryTagsScrollView.addSubview(categoryTagsStackView)
        
        dueDateTextField.addSubview(calendarIconImageView)
    }
    
    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(saveButton.snp.top).offset(-20)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        urlLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        urlTextField.snp.makeConstraints { make in
            make.top.equalTo(urlLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
        
        linkIconImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        titleSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(urlTextField.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        titleTextField.snp.makeConstraints { make in
            make.top.equalTo(titleSectionLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
        
        memoLabel.snp.makeConstraints { make in
            make.top.equalTo(titleTextField.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        memoTextView.snp.makeConstraints { make in
            make.top.equalTo(memoLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(120)
        }
        
        memoPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        
        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(memoTextView.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        categoryTagsScrollView.snp.makeConstraints { make in
            make.top.equalTo(categoryLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(32)
        }
        
        categoryTagsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        dueDateLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryTagsScrollView.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        dueDateTextField.snp.makeConstraints { make in
            make.top.equalTo(dueDateLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        calendarIconImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        saveButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(52)
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.title = "링크 추가"
        loadCategories()
    }
}
