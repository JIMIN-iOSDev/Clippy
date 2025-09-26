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
    private var selectedCategories: Set<String> = []
    
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
    
    private let categorySelectionView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let categoryPlaceholderLabel = {
        let label = UILabel()
        label.text = "카테고리를 선택하세요"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .placeholderText
        return label
    }()
    
    private let categoryArrowImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        imageView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        imageView.tintColor = .systemGray3
        return imageView
    }()
    
    private let categoryTagsStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    private let categoryTagsScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isHidden = true
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
        picker.preferredDatePickerStyle = .wheels
        return picker
    }()
    
    // MARK: - Configuration
    override func bind() {
        
    }
    
    override func configureHierarchy() {
        [scrollView, saveButton]
            .forEach { view.addSubview($0) }
        
        scrollView.addSubview(contentView)
        
        [urlLabel, urlTextField, titleSectionLabel, titleTextField, memoLabel, memoTextView,
         categoryLabel, categorySelectionView, categoryTagsScrollView, dueDateLabel, dueDateTextField]
            .forEach { contentView.addSubview($0) }
        
        urlTextField.addSubview(linkIconImageView)
        
        memoTextView.addSubview(memoPlaceholderLabel)
        
        [categoryPlaceholderLabel, categoryArrowImageView]
            .forEach { categorySelectionView.addSubview($0) }
        
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
        
        categorySelectionView.snp.makeConstraints { make in
            make.top.equalTo(categoryLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
        
        categoryPlaceholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        categoryArrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        categoryTagsScrollView.snp.makeConstraints { make in
            make.top.equalTo(categorySelectionView.snp.bottom).offset(12)
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
    }
}
