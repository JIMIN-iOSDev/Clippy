//
//  ShareViewController.swift
//  ClippyShare
//
//  Created by Jimin on 10/15/25.
//

import UIKit
import SnapKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let appGroupID = "group.com.jimin.Clippy" // 반드시 본앱과 동일하게!
    
    // MARK: - Properties
    private var categories: [[String: Any]] = []
    private var selectedCategoryNames: Set<String> = []
    // 정확한 clippyBlue(본앱 기준):
    private let clippyBlue = UIColor(red: 33/255.0, green: 150/255.0, blue: 243/255.0, alpha: 1.0)
    private var selectedDueDate: Date?

    // MARK: - UI Elements
    private let navBar: UINavigationBar = {
        let nav = UINavigationBar()
        nav.isTranslucent = false
        nav.setBackgroundImage(UIImage(), for: .default)
        nav.shadowImage = UIImage()
        nav.backgroundColor = .systemBackground
        nav.barTintColor = .systemBackground
        return nav
    }()
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    private let contentView = UIView()
    
    private let urlLabel: UILabel = {
        let label = UILabel()
        label.text = "링크 URL *"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    let urlTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "https://example.com"
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.borderStyle = .none
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.leftViewMode = .always
        tf.rightViewMode = .always
        tf.keyboardType = .URL
        tf.autocapitalizationType = .none
        tf.isEnabled = false
        tf.textColor = .secondaryLabel
        return tf
    }()
    
    private let titleSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "제목"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "링크 제목을 입력하세요"
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.borderStyle = .none
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.leftViewMode = .always
        tf.rightViewMode = .always
        return tf
    }()
    private let memoLabel: UILabel = {
        let label = UILabel()
        label.text = "메모"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    let memoTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = .systemGray6
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        tv.isScrollEnabled = false
        return tv
    }()
    private let memoPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "메모나 설명을 입력하세요"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .placeholderText
        label.isUserInteractionEnabled = false
        return label
    }()
    private let categorySectionStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        return sv
    }()
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "카테고리"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    private let categoryTagsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        sv.distribution = .fillProportionally
        return sv
    }()
    private let categoryTagsScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()
    // --- 마감일 추가
    private let dueDateLabel: UILabel = {
        let label = UILabel()
        label.text = "마감일 설정"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    private let dueDateTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "연도. 월. 일."
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.borderStyle = .none
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.leftViewMode = .always
        tf.rightViewMode = .always
        return tf
    }()
    private let calendarIconImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        imageView.image = UIImage(systemName: "calendar", withConfiguration: config)
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        return picker
    }()
    // ---
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("저장하기", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        // clippyBlue는 viewDidLoad에서 적용하도록 수정
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        return btn
    }()
    private let bottomMargin = UIView() // 아래 마진 여백

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupSheetStyle()
        setupNavBar()
        setupUI()
        bind()
        loadCategoriesFromAppGroup()
        preloadURLFromContext()
        saveButton.backgroundColor = clippyBlue

        // --- 키보드 내리기 로직 ---
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)
        contentView.addGestureRecognizer(tapGesture)
        scrollView.delegate = self
    }

    @objc private func endEditing() {
        view.endEditing(true)
    }
    
    private func setupSheetStyle() {
        // iOS16 medium 시트/아래쪽 여백 스타일(최대한 아래로 띄우기)
        preferredContentSize = CGSize(width: 0, height: 440)
        if let pc = presentationController as? UISheetPresentationController {
            pc.detents = [.medium(), .large()]
            pc.selectedDetentIdentifier = .medium
            pc.prefersGrabberVisible = true
            pc.prefersEdgeAttachedInCompactHeight = true
            pc.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }
        modalPresentationStyle = .pageSheet
    }

    private func setupNavBar() {
        view.addSubview(navBar)
        let navItem = UINavigationItem(title: "링크 추가")
        let done = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(onSave))
        done.tintColor = clippyBlue
        let cancel = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(onCancel))
        cancel.tintColor = .systemGray
        navItem.leftBarButtonItem = cancel
        navItem.rightBarButtonItem = done
        navBar.setItems([navItem], animated: false)
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        navBar.backgroundColor = .systemBackground
        navBar.barTintColor = .systemBackground
        navBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(44)
        }
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [urlLabel, urlTextField, titleSectionLabel, titleTextField, memoLabel, memoTextView, memoPlaceholderLabel, categorySectionStackView, categoryTagsScrollView, dueDateLabel, dueDateTextField, saveButton, bottomMargin].forEach { contentView.addSubview($0) }

        categorySectionStackView.addArrangedSubview(categoryLabel)
        categoryTagsScrollView.addSubview(categoryTagsStackView)
        dueDateTextField.addSubview(calendarIconImageView)

        // 상단 안전 여백 + 8pt: scrollView top 12
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom).offset(12)
            make.bottom.leading.trailing.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        urlLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        urlTextField.snp.makeConstraints { make in
            make.top.equalTo(urlLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(48)
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
            make.top.equalTo(memoTextView.snp.top).offset(16)
            make.leading.equalTo(memoTextView.snp.leading).offset(16)
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
        }
        calendarIconImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        saveButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(dueDateTextField.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(52)
        }
        bottomMargin.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom)
            make.bottom.equalToSuperview().offset(-10)
            make.height.greaterThanOrEqualTo(20)
        }

        // datePicker 연동
        dueDateTextField.inputView = datePicker
        calendarIconImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(openDatePicker))
        calendarIconImageView.addGestureRecognizer(tap)
        let doneToolbar = UIToolbar()
        doneToolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(selectDueDate))
        doneBtn.tintColor = clippyBlue
        doneToolbar.setItems([flex, doneBtn], animated: false)
        dueDateTextField.inputAccessoryView = doneToolbar
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        memoTextView.delegate = self
        updateMemoPlaceholder()
    }

    private func bind() {
        saveButton.addTarget(self, action: #selector(onSave), for: .touchUpInside)
    }

    private func loadCategoriesFromAppGroup() {
        let defaults = UserDefaults(suiteName: appGroupID)
        guard let arr = defaults?.array(forKey: "categories") as? [[String: Any]] else { return }
        self.categories = arr
        createCategoryButtons(arr)
    }

    private func createCategoryButtons(_ categories: [[String: Any]]) {
        categoryTagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for dict in categories {
            guard let name = dict["name"] as? String,
                  let colorIndex = dict["colorIndex"] as? Int else { continue }

            let button = UIButton(type: .system)
            button.setTitle(name, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.layer.cornerRadius = 12
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            button.tag = colorIndex
            button.addTarget(self, action: #selector(onCategoryTap(_:)), for: .touchUpInside)
            categoryTagsStackView.addArrangedSubview(button)
        }
        updateButtonStyles()
    }

    @objc private func onCategoryTap(_ sender: UIButton) {
        guard let name = sender.title(for: .normal) else { return }
        if selectedCategoryNames.contains(name) {
            selectedCategoryNames.remove(name)
        } else {
            selectedCategoryNames.insert(name)
        }
        updateButtonStyles()
    }

    private func updateButtonStyles() {
        for case let button as UIButton in categoryTagsStackView.arrangedSubviews {
            guard let name = button.title(for: .normal) else { continue }
            let isSelected = selectedCategoryNames.contains(name)
            button.backgroundColor = isSelected ? clippyBlue : .systemGray6
            button.setTitleColor(isSelected ? .white : .label, for: .normal)
            button.layer.borderColor = (isSelected ? clippyBlue : UIColor.systemGray4).cgColor
        }
        saveButton.backgroundColor = clippyBlue
        saveButton.setTitleColor(.white, for: .normal)
    }
    
    private func preloadURLFromContext() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            return
        }
        let providers = items.compactMap { $0.attachments }.flatMap { $0 }
        let group = DispatchGroup()
        var receivedURLs: [URL] = []
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    if let url = item as? URL { receivedURLs.append(url) }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            if let first = receivedURLs.first {
                self.urlTextField.text = first.absoluteString
            }
        }
    }

    @objc private func openDatePicker() {
        dueDateTextField.becomeFirstResponder()
    }
    @objc private func selectDueDate() {
        selectedDueDate = datePicker.date
        dueDateTextField.text = Self.dateFormatter.string(from: datePicker.date)
        dueDateTextField.resignFirstResponder()
    }
    @objc private func dateChanged() {
        dueDateTextField.text = Self.dateFormatter.string(from: datePicker.date)
        selectedDueDate = datePicker.date
    }
    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "yyyy. MM. dd."
        return df
    }()

    // 저장: URL 유효성 + 모든 입력값/카테고리 UserDefaults에 담아 저장
    @objc private func onSave() {
        let urlString = (urlTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: urlString), ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else {
            showAlert(message: "올바른 URL을 입력하세요")
            return
        }
        let title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let memo = memoTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedCategoriesString = selectedCategoryNames.joined(separator: "|")
        let dueDateString: String? = selectedDueDate.map { Self.dateFormatter.string(from: $0) }

        let defaults = UserDefaults(suiteName: appGroupID)
        
        if defaults == nil {
            showAlert(message: "App Group 설정 오류")
            return
        }
        
        var items = defaults?.array(forKey: "shared_items") as? [[String: String]] ?? []
        var dict: [String: String] = ["url": url.absoluteString]
        if let title, !title.isEmpty { dict["title"] = title }
        if let memo, !memo.isEmpty { dict["memo"] = memo }
        if !selectedCategoriesString.isEmpty { dict["categories"] = selectedCategoriesString }
        if let dueDate = dueDateString { dict["dueDate"] = dueDate }
        items.append(dict)
        
        defaults?.set(items, forKey: "shared_items")
        defaults?.synchronize()
        
        extensionContext?.completeRequest(returningItems: nil)
    }
    @objc private func onCancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "ClippyShare", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled"]))
    }
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    // --- Memo Placeholder Delegate
}
extension ShareViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateMemoPlaceholder()
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        updateMemoPlaceholder()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        updateMemoPlaceholder()
    }
    private func updateMemoPlaceholder() {
        memoPlaceholderLabel.isHidden = !(memoTextView.text?.isEmpty ?? true)
    }
}

extension ShareViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}
