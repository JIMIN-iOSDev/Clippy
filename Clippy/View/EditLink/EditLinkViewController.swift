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
    
    var defaultCategoryName: String?
    var onLinkCreated: (() -> Void)?
    private let selectedDueDate = BehaviorRelay<Date?>(value: nil)
    var editingLink: LinkMetadata? // 수정 모드일 때 사용
    var onLinkUpdated: (() -> Void)? // 수정 완료 콜백
    /// 외부에서 진입 시 URL을 미리 채우기 위한 값
    var prefillURLString: String?
    
    
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
    
    private let categorySectionStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()
    
    private let categoryLabel = {
        let label = UILabel()
        label.text = "카테고리"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let addCategoryButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ 추가", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.clippyBlue, for: .normal)
        return button
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
        button.backgroundColor = .clippyBlue
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
        memoTextView.rx.text.orEmpty
            .map { !$0.isEmpty }
            .bind(to: memoPlaceholderLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        
        // 카테고리 추가 버튼
        addCategoryButton.rx.tap
            .bind(with: self) { owner, _ in
                let editCategoryVC = EditCategoryViewController()
                editCategoryVC.onCategoryCreated = { [weak owner] in
                    owner?.loadCategories()
                }
                owner.present(UINavigationController(rootViewController: editCategoryVC), animated: true)
            }
            .disposed(by: disposeBag)
        
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
        
        saveButton.rx.tap
            .withLatestFrom(Observable.combineLatest(urlTextField.rx.text.orEmpty, titleTextField.rx.text.orEmpty, memoTextView.rx.text.orEmpty, selectedCategories.asObservable(), selectedDueDate.asObservable()))
            .flatMapLatest { [weak self] urlString, title, memo, selectedCategories, dueDate -> Observable<LinkMetadata> in
                guard let self = self else { return Observable.empty() }
                
                let trimmedURL = urlString.trimmingCharacters(in: .whitespaces)
                guard !trimmedURL.isEmpty else {
                    self.showToast(message: "링크 URL을 입력해주세요")
                    return Observable.empty()
                }
                
                // URL 형식 검증
                guard let url = URL(string: trimmedURL),
                      let scheme = url.scheme?.lowercased(),
                      ["http", "https"].contains(scheme),
                      url.host != nil else {
                    self.showToast(message: "올바른 URL 형식이 아닙니다")
                    return Observable.empty()
                }
                
                // 중복 링크 검사 (수정 모드가 아닌 경우에만)
                if self.editingLink == nil {
                    let categories = self.repository.readCategoryList()
                    let isDuplicate = categories.contains { category in
                        category.category.contains { $0.url == trimmedURL }
                    }
                    
                    if isDuplicate {
                        self.showToast(message: "이미 저장되어 있는 링크입니다")
                        return Observable.empty()
                    }
                } else {
                    // 수정 모드: 현재 수정 중인 링크를 제외하고 중복 검사
                    let categories = self.repository.readCategoryList()
                    let currentEditingURL = self.editingLink?.url.absoluteString
                    let isDuplicate = categories.contains { category in
                        category.category.contains { link in
                            link.url == trimmedURL && link.url != currentEditingURL
                        }
                    }
                    
                    if isDuplicate {
                        self.showToast(message: "이미 저장되어 있는 링크입니다")
                        return Observable.empty()
                    }
                }
                
                let finalTitle = title.isEmpty ? nil : title
                let finalUserMemo = memo.isEmpty ? nil : memo

                // 카테고리 선택 안했으면 "일반"에 저장
                let targetCategories = selectedCategories.isEmpty ? ["일반"] : selectedCategories

                // 카테고리 정보 가져오기 (색상 포함)
                let categoryInfos: [(name: String, colorIndex: Int)] = targetCategories.compactMap { name in
                    guard let category = self.repository.readCategory(name: name) else { return nil }
                    return (name: category.name, colorIndex: category.colorIndex)
                }

                // 먼저 메타데이터 가져오기
                return LinkManager.shared.fetchLinkMetadata(for: url)
                    .flatMap { [weak self] fetchedMetadata -> Observable<LinkMetadata> in
                        guard let self = self else { return Observable.empty() }

                        // 제목: 사용자 입력 우선, 없으면 메타데이터 사용
                        let actualTitle = finalTitle ?? fetchedMetadata.title
                        // 사용자 메모: 사용자가 입력한 값 (있으면 저장, 없으면 nil)
                        let actualUserMemo = finalUserMemo

                        // 수정 모드인 경우
                        if let editingLink = self.editingLink {
                            // 메타데이터 설명: 수정 모드에서는 기존 값 보존 (URL이 변경되지 않으므로)
                            let actualMetadataDescription = editingLink.metadataDescription

                            // 기존 링크 삭제
                            LinkManager.shared.deleteLink(url: editingLink.url)
                                .subscribe()
                                .disposed(by: self.disposeBag)

                            // CategoryRepository에서 따로 업데이트 (즐겨찾기/열람 상태 보존)
                            self.repository.updateLink(
                                url: urlString,
                                title: actualTitle,
                                userMemo: actualUserMemo,
                                metadataDescription: actualMetadataDescription, // 기존 값 보존
                                categoryNames: targetCategories,
                                deadline: dueDate,
                                preserveLikeStatus: true,
                                preserveOpenedStatus: true,
                                preserveOpenCount: true
                            )

                            // LinkManager에 추가 (메타데이터 fetch 및 캐시, 상태 복원, 생성일 유지)
                            return LinkManager.shared.addLink(
                                url: url,
                                title: actualTitle,
                                userMemo: actualUserMemo,
                                metadataDescription: actualMetadataDescription, // 기존 값 보존
                                categories: categoryInfos,
                                dueDate: dueDate,
                                thumbnailImage: fetchedMetadata.thumbnailImage,
                                isLiked: editingLink.isLiked,
                                isOpened: editingLink.isOpened,
                                createdAt: editingLink.createdAt
                            )
                        } else {
                            // 새 링크 추가 모드: 메타데이터에서 가져온 값 사용
                            let actualMetadataDescription = fetchedMetadata.metadataDescription

                            targetCategories.forEach { categoryName in
                                self.repository.addLink(title: actualTitle, url: urlString, userMemo: actualUserMemo, metadataDescription: actualMetadataDescription, categoryName: categoryName, deadline: dueDate)
                            }

                            // LinkManager에 추가 (메타데이터 fetch 및 캐시)
                            return LinkManager.shared.addLink(url: url, title: actualTitle, userMemo: actualUserMemo, metadataDescription: actualMetadataDescription, categories: categoryInfos, dueDate: dueDate, thumbnailImage: fetchedMetadata.thumbnailImage)
                        }
                    }
            }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                if owner.editingLink != nil {
                    // 수정 모드
                    NotificationCenter.default.post(name: .linkDidCreate, object: nil)
                    owner.onLinkUpdated?()
                } else {
                    // 추가 모드
                    NotificationCenter.default.post(name: .linkDidCreate, object: nil)
                    owner.onLinkCreated?()
                }
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
        
        // 완료 버튼 툴바
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let clearButton = UIBarButtonItem(title: "지우기", style: .plain, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "완료", style: .done, target: nil, action: nil)
        toolbar.setItems([clearButton, flexSpace, doneButton], animated: true)
        dueDateTextField.inputAccessoryView = toolbar
        
        // 지우기 버튼 탭
        clearButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.selectedDueDate.accept(nil)
                owner.dueDateTextField.text = nil
                owner.dueDateTextField.resignFirstResponder()
            }
            .disposed(by: disposeBag)
        
        // 완료 버튼 탭 -> 날짜 선택 확정
        doneButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.selectedDueDate.accept(owner.datePicker.date)
                owner.dueDateTextField.text = DateFormatter.displayFormatter.string(from: owner.datePicker.date)
                owner.dueDateTextField.resignFirstResponder()
            }
            .disposed(by: disposeBag)
        
        // 선택된 날짜를 TextField에 표시
        selectedDueDate
            .map { date in
                if let date = date {
                    return DateFormatter.displayFormatter.string(from: date)
                } else {
                    return nil
                }
            }
            .bind(to: dueDateTextField.rx.text)
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
            
            button.backgroundColor = isSelected ? .clippyBlue : .systemGray6
            button.setTitleColor(isSelected ? .white : .label, for: .normal)
            button.layer.borderColor = (isSelected ? UIColor.clippyBlue : UIColor.systemGray4).cgColor
        }
    }
    
    override func configureHierarchy() {
        [scrollView, saveButton].forEach { view.addSubview($0) }
        
        scrollView.addSubview(contentView)
        
        [urlLabel, urlTextField, titleSectionLabel, titleTextField, memoLabel, memoTextView, categorySectionStackView, categoryTagsScrollView, dueDateLabel, dueDateTextField].forEach { contentView.addSubview($0) }
        
        urlTextField.addSubview(linkIconImageView)
        
        memoTextView.addSubview(memoPlaceholderLabel)
        
        categoryTagsScrollView.addSubview(categoryTagsStackView)
        
        categorySectionStackView.addArrangedSubview(categoryLabel)
        categorySectionStackView.addArrangedSubview(addCategoryButton)
        
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
            make.top.equalTo(urlTextField.snp.bottom).offset(20)
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
        
        categorySectionStackView.snp.makeConstraints { make in
            make.top.equalTo(memoTextView.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        categoryTagsScrollView.snp.makeConstraints { make in
            make.top.equalTo(categorySectionStackView.snp.bottom).offset(12)
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
        
        // 완료 버튼 추가
        let completeButton = UIBarButtonItem(title: "완료", style: .done, target: nil, action: nil)
        navigationItem.rightBarButtonItem = completeButton
        
        // 완료 버튼 바인딩 (수정하기 버튼과 동일한 로직)
        completeButton.rx.tap
            .do(onNext: { [weak self] _ in
                self?.view.endEditing(true) // 키보드 내리기
            })
            .subscribe(onNext: { [weak self] _ in
                self?.saveButton.sendActions(for: .touchUpInside) // 저장하기 버튼과 동일한 동작
            })
            .disposed(by: disposeBag)
        
        // 수정 모드인지 확인
        if let link = editingLink {
            navigationItem.title = "링크 수정"
            saveButton.setTitle("수정하기", for: .normal)

            // 기존 데이터 채우기
            urlTextField.text = link.url.absoluteString
            titleTextField.text = link.title
            // 사용자 메모만 표시 (메타데이터 설명은 수정 불가)
            memoTextView.text = link.userMemo
            
            // 마감일 설정
            if let dueDate = link.dueDate {
                selectedDueDate.accept(dueDate)
                datePicker.date = dueDate
                dueDateTextField.text = DateFormatter.displayFormatter.string(from: dueDate)
            }
            
            // 카테고리 선택
            if let categories = link.categories {
                let categoryNames = categories.map { $0.name }
                selectedCategories.accept(categoryNames)
            }
            
            // URL 필드 비활성화 (수정 시 URL 변경 불가)
            urlTextField.isEnabled = false
            urlTextField.textColor = .secondaryLabel
        } else {
            navigationItem.title = "링크 추가"
            saveButton.setTitle("저장하기", for: .normal)
            
            if let defaultCategoryName = defaultCategoryName {
                selectedCategories.accept([defaultCategoryName])
            }

            // 외부에서 전달된 URL이 있으면 프리필
            if let prefill = prefillURLString, !prefill.isEmpty {
                urlTextField.text = prefill
            }
        }
        
        loadCategories()
        
        if let defaultCategoryName = defaultCategoryName {
            selectedCategories.accept([defaultCategoryName])
        }
        
        // 화면 클릭 시 키보드 내려감
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
        
        // 링크 이미지 클릭 시에도 텍스트필드 선택
        linkIconImageView.isUserInteractionEnabled = true
        let linkTap = UITapGestureRecognizer()
        linkIconImageView.addGestureRecognizer(linkTap)
        
        linkTap.rx.event
            .bind(with: self) { owner, _ in
                owner.urlTextField.becomeFirstResponder()
            }
            .disposed(by: disposeBag)
        
        // 캘린더 이미지 클릭 시에도 캘린더 띄워주기
        calendarIconImageView.isUserInteractionEnabled = true
        let calendarTap = UITapGestureRecognizer()
        calendarIconImageView.addGestureRecognizer(calendarTap)
        
        calendarTap.rx.event
            .bind(with: self) { owner, _ in
                owner.dueDateTextField.becomeFirstResponder()
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Toast Message
    private func showToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textAlignment = .center
        toast.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.alpha = 0
        
        view.addSubview(toast)
        view.bringSubviewToFront(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-100)
            make.height.equalTo(36)
            make.width.greaterThanOrEqualTo(message.count * 12 + 40)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                UIView.animate(withDuration: 0.3, animations: {
                    toast.alpha = 0
                }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }
}
