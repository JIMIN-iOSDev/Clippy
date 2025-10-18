//
//  StatisticsViewController.swift
//  Clippy
//
//  Created by Jimin on 10/18/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class StatisticsViewController: BaseViewController {

    // MARK: - Properties
    private let disposeBag = DisposeBag()

    // MARK: - UI Components
    private let scrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        
        scrollView.backgroundColor = .systemBackground
        return scrollView
    }()

    private let contentView = UIView()

    // MARK: - Calendar Section
    private let calendarContainerView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let calendarTitleLabel = {
        let label = UILabel()
        label.text = "링크 저장 캘린더"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let calendarView = CalendarView()

    // MARK: - Weekly Chart Section
    private let weeklyChartContainerView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let weeklyChartTitleLabel = {
        let label = UILabel()
        label.text = "최근 7일간 저장한 링크"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let weeklyChartCountLabel = {
        let label = UILabel()
        label.text = "6"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .clippyBlue
        return label
    }()

    private let weeklyChartCountUnitLabel = {
        let label = UILabel()
        label.text = "개"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let weeklyChartView = WeeklyChartView()

    // MARK: - Category Distribution Section
    private let categoryChartContainerView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let categoryChartTitleLabel = {
        let label = UILabel()
        label.text = "카테고리 분포"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let categoryDonutChartView = CategoryDonutChartView()

    private let categoryLegendStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupUI()
        setupConstraints()
        bindData()
    }

    // MARK: - Setup Methods
    private func setupNavigationBar() {
        navigationItem.title = "통계"
        navigationController?.navigationBar.prefersLargeTitles = false

        // 네비게이션 바 배경색 고정
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Calendar Section
        contentView.addSubview(calendarContainerView)
        calendarContainerView.addSubview(calendarTitleLabel)
        calendarContainerView.addSubview(calendarView)

        // Weekly Chart Section
        contentView.addSubview(weeklyChartContainerView)
        weeklyChartContainerView.addSubview(weeklyChartTitleLabel)
        weeklyChartContainerView.addSubview(weeklyChartCountLabel)
        weeklyChartContainerView.addSubview(weeklyChartCountUnitLabel)
        weeklyChartContainerView.addSubview(weeklyChartView)

        // Category Chart Section
        contentView.addSubview(categoryChartContainerView)
        categoryChartContainerView.addSubview(categoryChartTitleLabel)
        categoryChartContainerView.addSubview(categoryDonutChartView)
        categoryChartContainerView.addSubview(categoryLegendStackView)

        // Add sample category legend items
        createCategoryLegendItems()
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        // Calendar Container
        calendarContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        calendarTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        calendarView.snp.makeConstraints { make in
            make.top.equalTo(calendarTitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(320)
            make.bottom.equalToSuperview().offset(-20)
        }

        // Weekly Chart Container
        weeklyChartContainerView.snp.makeConstraints { make in
            make.top.equalTo(calendarContainerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        weeklyChartTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        weeklyChartCountLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.trailing.equalTo(weeklyChartCountUnitLabel.snp.leading).offset(-4)
        }

        weeklyChartCountUnitLabel.snp.makeConstraints { make in
            make.centerY.equalTo(weeklyChartCountLabel)
            make.trailing.equalToSuperview().offset(-20)
        }

        weeklyChartView.snp.makeConstraints { make in
            make.top.equalTo(weeklyChartTitleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(200)
            make.bottom.equalToSuperview().offset(-20)
        }

        // Category Chart Container
        categoryChartContainerView.snp.makeConstraints { make in
            make.top.equalTo(weeklyChartContainerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }

        categoryChartTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        categoryDonutChartView.snp.makeConstraints { make in
            make.top.equalTo(categoryChartTitleLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(200)
        }

        categoryLegendStackView.snp.makeConstraints { make in
            make.top.equalTo(categoryDonutChartView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    private func createCategoryLegendItems() {
        let sampleCategories = [
            ("일반", "2개 · 22%", UIColor.systemBlue, "folder"),
            ("iOS", "1개 · 11%", UIColor.systemRed, "swift"),
            ("개발", "3개 · 33%", UIColor.systemPurple, "chevron.left.forwardslash.chevron.right"),
            ("디자인", "2개 · 22%", UIColor.systemGreen, "paintpalette"),
            ("영상", "1개 · 11%", UIColor.systemOrange, "video")
        ]

        for (name, info, color, iconName) in sampleCategories {
            let legendItem = CategoryLegendItemView()
            legendItem.configure(name: name, info: info, color: color, iconName: iconName)
            categoryLegendStackView.addArrangedSubview(legendItem)
        }
    }

    private func bindData() {
        // TODO: Bind real data from LinkManager
    }
}

// MARK: - Weekly Chart View
final class WeeklyChartView: UIView {

    // MARK: - Properties
    private let barStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.alignment = .bottom
        return stackView
    }()

    private let dayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(barStackView)

        barStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(160)
        }

        // Create 7 bar items (sample data)
        let sampleHeights: [CGFloat] = [0.6, 0.8, 0.7, 0.9, 0.5, 0.7, 0.0] // normalized heights

        for (index, height) in sampleHeights.enumerated() {
            let barContainer = createBarContainer(dayLabel: dayLabels[index], height: height)
            barStackView.addArrangedSubview(barContainer)
        }
    }

    private func createBarContainer(dayLabel: String, height: CGFloat) -> UIView {
        let container = UIView()

        let barView = UIView()
        barView.backgroundColor = .clippyBlue.withAlphaComponent(0.8)
        barView.layer.cornerRadius = 8
        barView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let label = UILabel()
        label.text = dayLabel
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center

        container.addSubview(barView)
        container.addSubview(label)

        barView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(4)
            make.bottom.equalTo(label.snp.top).offset(-8)
            make.height.equalTo(160 * height)
        }

        label.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(20)
        }

        return container
    }
}

// MARK: - Category Donut Chart View
final class CategoryDonutChartView: UIView {

    // MARK: - Properties
    private let centerLabel = {
        let label = UILabel()
        label.text = "9"
        label.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let centerSubLabel = {
        let label = UILabel()
        label.text = "전체 링크"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(centerLabel)
        addSubview(centerSubLabel)

        centerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
        }

        centerSubLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(centerLabel.snp.bottom).offset(4)
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawDonutChart(in: rect)
    }

    private func drawDonutChart(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = min(rect.width, rect.height) / 2 - 20
        let lineWidth: CGFloat = 30

        // Sample data: percentages for each category
        let data: [(percentage: CGFloat, color: UIColor)] = [
            (0.22, .systemBlue),    // 일반 22%
            (0.11, .systemRed),     // iOS 11%
            (0.33, .systemPurple),  // 개발 33%
            (0.22, .systemGreen),   // 디자인 22%
            (0.11, .systemOrange)   // 영상 11%
        ]

        var startAngle: CGFloat = -.pi / 2 // Start from top

        for (percentage, color) in data {
            let endAngle = startAngle + (percentage * 2 * .pi)

            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )

            context.setStrokeColor(color.cgColor)
            context.setLineWidth(lineWidth)
            context.setLineCap(.round)
            context.addPath(path.cgPath)
            context.strokePath()

            startAngle = endAngle
        }
    }
}

// MARK: - Category Legend Item View
final class CategoryLegendItemView: UIView {

    // MARK: - UI Components
    private let iconContainerView = {
        let view = UIView()
        view.layer.cornerRadius = 24
        return view
    }()

    private let iconImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private let nameLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let infoLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        addSubview(nameLabel)
        addSubview(infoLabel)

        iconContainerView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainerView.snp.trailing).offset(16)
            make.top.equalToSuperview().offset(6)
        }

        infoLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-6)
        }

        self.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(48)
        }
    }

    func configure(name: String, info: String, color: UIColor, iconName: String) {
        nameLabel.text = name
        infoLabel.text = info
        iconContainerView.backgroundColor = color

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
    }
}

// MARK: - Calendar View
final class CalendarView: UIView {

    // MARK: - Properties
    private let calendar = Calendar.current
    private var currentMonth = Date()
    private var selectedDate: Date?
    private let eventDates: Set<Date> = [] // TODO: 실제 데이터로 채우기

    // MARK: - UI Components
    private let headerView = UIView()

    private let prevButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = .label
        return button
    }()

    private let monthLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private let nextButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        button.tintColor = .label
        return button
    }()

    private let weekdayStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let datesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.register(CalendarDateCell.self, forCellWithReuseIdentifier: "CalendarDateCell")
        return collectionView
    }()

    private var days: [Date?] = []

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
        updateCalendar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(headerView)
        headerView.addSubview(prevButton)
        headerView.addSubview(monthLabel)
        headerView.addSubview(nextButton)
        addSubview(weekdayStackView)
        addSubview(datesCollectionView)

        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        prevButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        monthLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        weekdayStackView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(30)
        }

        datesCollectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayStackView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        datesCollectionView.delegate = self
        datesCollectionView.dataSource = self

        setupWeekdayLabels()
    }

    private func setupWeekdayLabels() {
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        for (index, weekday) in weekdays.enumerated() {
            let label = UILabel()
            label.text = weekday
            label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            label.textAlignment = .center
            label.textColor = index == 0 ? .systemRed : (index == 6 ? .systemBlue : .secondaryLabel)
            weekdayStackView.addArrangedSubview(label)
        }
    }

    private func setupActions() {
        prevButton.addTarget(self, action: #selector(prevMonthTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextMonthTapped), for: .touchUpInside)
    }

    @objc private func prevMonthTapped() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
            updateCalendar()
        }
    }

    @objc private func nextMonthTapped() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
            updateCalendar()
        }
    }

    private func updateCalendar() {
        // Update month label
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        monthLabel.text = formatter.string(from: currentMonth)

        // Calculate days to display
        days = generateDaysInMonth(for: currentMonth)
        datesCollectionView.reloadData()
    }

    private func generateDaysInMonth(for date: Date) -> [Date?] {
        var days: [Date?] = []

        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return days
        }

        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end

        // Start from the first day of the first week
        var currentDate = monthFirstWeek.start

        while currentDate < monthEnd {
            if currentDate < monthStart {
                days.append(nil)
            } else {
                days.append(currentDate)
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return days
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension CalendarView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarDateCell", for: indexPath) as! CalendarDateCell

        let day = days[indexPath.item]
        if let day = day {
            let dayNumber = calendar.component(.day, from: day)
            let isToday = calendar.isDateInToday(day)
            let isSelected = selectedDate != nil && calendar.isDate(day, inSameDayAs: selectedDate!)

            cell.configure(day: dayNumber, isToday: isToday, isSelected: isSelected, hasEvent: false)
        } else {
            cell.configure(day: nil, isToday: false, isSelected: false, hasEvent: false)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 6 * 8) / 7
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let date = days[indexPath.item] else { return }
        selectedDate = date
        collectionView.reloadData()
    }
}

// MARK: - Calendar Date Cell
final class CalendarDateCell: UICollectionViewCell {

    private let dayLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let eventDotView = {
        let view = UIView()
        view.backgroundColor = .clippyBlue
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(dayLabel)
        contentView.addSubview(eventDotView)

        dayLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        eventDotView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(dayLabel.snp.bottom).offset(2)
            make.width.height.equalTo(6)
        }

        contentView.layer.cornerRadius = 8
    }

    func configure(day: Int?, isToday: Bool, isSelected: Bool, hasEvent: Bool) {
        if let day = day {
            dayLabel.text = "\(day)"
            dayLabel.textColor = .label
            dayLabel.isHidden = false

            if isSelected {
                contentView.backgroundColor = .clippyBlue
                dayLabel.textColor = .white
            } else if isToday {
                contentView.backgroundColor = .clippyBlue.withAlphaComponent(0.2)
                dayLabel.textColor = .clippyBlue
            } else {
                contentView.backgroundColor = .clear
                dayLabel.textColor = .label
            }

            eventDotView.isHidden = !hasEvent || isSelected
        } else {
            dayLabel.isHidden = true
            eventDotView.isHidden = true
            contentView.backgroundColor = .clear
        }
    }
}
