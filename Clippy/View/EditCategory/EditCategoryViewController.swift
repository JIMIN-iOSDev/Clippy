//
//  EditCategoryViewController.swift
//  Clippy
//
//  Created by Jimin on 9/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class EditCategoryViewController: BaseViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let repository = CategoryRepository()
    
    private let selectedColorIndex = BehaviorRelay<Int>(value: 0)
    private let selectedIconIndex = BehaviorRelay<Int>(value: 0)
    
    var onCategoryCreated: (() -> Void)?
    
    // MARK: - UI Components
    private let scrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let categoryNameLabel = {
        let label = UILabel()
        label.text = "카테고리 이름 *"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let categoryNameTextField = {
        let textField = UITextField()
        textField.placeholder = "10자 이내로 입력 (예: 취미, 맛집)"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.rightViewMode = .always
        return textField
    }()
    
    private let colorSectionLabel = {
        let label = UILabel()
        label.text = "색상 선택"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let colorScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let colorStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .equalSpacing
        return stackView
    }()
    
    private let iconSectionLabel = {
        let label = UILabel()
        label.text = "아이콘 선택"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let iconStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let firstIconRowStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let secondIconRowStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    
    private let createButton = {
        let button = UIButton(type: .system)
        button.setTitle("카테고리 만들기", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    // MARK: - Configuration
    override func bind() {
        // 카테고리 이름 글자수 제한 (10자)
        categoryNameTextField.rx.text.orEmpty
            .map { text in
                if text.count > 10 {
                    return String(text.prefix(10))
                }
                return text
            }
            .bind(to: categoryNameTextField.rx.text)
            .disposed(by: disposeBag)
        
        // 색상 선택
        for (index, view) in colorStackView.arrangedSubviews.enumerated() {
            guard let button = view as? UIButton else { continue }
            button.rx.tap
                .asDriver()
                .drive(with: self) { owner, _ in
                    owner.selectedColorIndex.accept(index)
                }
                .disposed(by: disposeBag)
        }
        
        // 아이콘 선택 - 첫 번째 줄
        for (index, view) in firstIconRowStackView.arrangedSubviews.enumerated() {
            guard let button = view as? UIButton else { continue }
            button.rx.tap
                .asDriver()
                .drive(with: self) { owner, _ in
                    owner.selectedIconIndex.accept(index)
                }
                .disposed(by: disposeBag)
        }
        
        // 아이콘 선택 - 두 번째 줄
        for (index, view) in secondIconRowStackView.arrangedSubviews.enumerated() {
            guard let button = view as? UIButton else { continue }
            button.rx.tap
                .asDriver()
                .drive(with: self) { owner, _ in
                    owner.selectedIconIndex.accept(index + 6)
                }
                .disposed(by: disposeBag)
        }
        
        // 선택된 색상 업데이트
        selectedColorIndex
            .bind(with: self) { owner, _ in
                owner.updateColorButtons()
            }
            .disposed(by: disposeBag)
        
        // 선택된 아이콘 업데이트
        selectedIconIndex
            .bind(with: self) { owner, _ in
                owner.updateIconButtons()
            }
            .disposed(by: disposeBag)
        
        createButton.rx.tap
            .withLatestFrom(Observable.combineLatest(categoryNameTextField.rx.text.orEmpty, selectedColorIndex.asObservable(), selectedIconIndex.asObservable()))
            .bind(with: self) { owner, value in
                let (name, colorIndex, iconIndex) = value
                
                guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                    owner.showToast(message: "카테고리 이름을 입력해주세요")
                    return
                }
                
                let allIcons = ["folder", "book", "heart", "cart", "star", "tag", "music.note", "photo", "car", "house", "gamecontroller", "paintbrush"]
                let iconName = allIcons[iconIndex]
                
                let success = owner.repository.createCategory(name: name, colorIndex: colorIndex, iconName: iconName)
                
                if success {
                    NotificationCenter.default.post(name: .categoryDidCreate, object: nil)
                    owner.onCategoryCreated?()
                    owner.dismiss(animated: true)
                } else {
                    owner.showToast(message: "이미 존재하는 카테고리 이름입니다")
                }
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
    
    private func updateColorButtons() {
        for (index, view) in colorStackView.arrangedSubviews.enumerated() {
            if let button = view as? UIButton {
                if index == selectedColorIndex.value {
                    button.layer.borderColor = UIColor.systemGray2.cgColor
                    button.layer.borderWidth = 3
                    button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                } else {
                    button.layer.borderColor = UIColor.systemGray5.cgColor
                    button.layer.borderWidth = 1
                    button.transform = .identity
                }
            }
        }
    }
    
    private func updateIconButtons() {
        for (index, view) in firstIconRowStackView.arrangedSubviews.enumerated() {
            if let button = view as? UIButton {
                let isSelected = index == selectedIconIndex.value
                button.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.15) : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
                button.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
                button.layer.borderWidth = isSelected ? 2 : 0
            }
        }
        
        for (index, view) in secondIconRowStackView.arrangedSubviews.enumerated() {
            if let button = view as? UIButton {
                let globalIndex = index + 6
                let isSelected = globalIndex == selectedIconIndex.value
                button.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.15) : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
                button.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
                button.layer.borderWidth = isSelected ? 2 : 0
            }
        }
    }
    
    private func createColorButtons() {
        CategoryColor.colors.forEach { color in
            let button = UIButton(type: .system)
            button.backgroundColor = color
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray5.cgColor
            button.layer.masksToBounds = true
            
            colorStackView.addArrangedSubview(button)
            
            button.snp.makeConstraints { make in
                make.width.height.equalTo(44)
            }
            
            button.layoutIfNeeded()
            button.layer.cornerRadius = 22
        }
        updateColorButtons()
    }
    
    private func createIconButtons() {
        let firstRowIcons = ["folder", "book", "heart", "cart", "star", "tag"]
        let secondRowIcons = ["music.note", "photo", "car", "house", "gamecontroller", "paintbrush"]
        
        createIconRow(icons: firstRowIcons, stackView: firstIconRowStackView)
        createIconRow(icons: secondRowIcons, stackView: secondIconRowStackView)
        updateIconButtons()
    }
    
    private func createIconRow(icons: [String], stackView: UIStackView) {
        icons.forEach { iconName in
            let button = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            button.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
            button.tintColor = .label
            button.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.clear.cgColor
            stackView.addArrangedSubview(button)
            
            button.snp.makeConstraints { make in
                make.height.equalTo(42)
            }
        }
    }
    
    override func configureHierarchy() {
        [scrollView, createButton].forEach { view.addSubview($0) }
        scrollView.addSubview(contentView)
        
        [categoryNameLabel, categoryNameTextField, colorSectionLabel, colorScrollView, iconSectionLabel, iconStackView].forEach { contentView.addSubview($0) }
        
        colorScrollView.addSubview(colorStackView)
        [firstIconRowStackView, secondIconRowStackView].forEach { iconStackView.addArrangedSubview($0) }
        
        createColorButtons()
        createIconButtons()
    }
    
    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(createButton.snp.top).offset(-20)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        categoryNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        categoryNameTextField.snp.makeConstraints { make in
            make.top.equalTo(categoryNameLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
        
        colorSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryNameTextField.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        colorScrollView.snp.makeConstraints { make in
            make.top.equalTo(colorSectionLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(60)
        }
        
        colorStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
            make.height.equalTo(44)
        }
        
        iconSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(colorStackView.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        iconStackView.snp.makeConstraints { make in
            make.top.equalTo(iconSectionLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(96)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        createButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(52)
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.title = "카테고리 추가"
        
        // 화면 탭 시 키보드 숨기기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
