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

    private let weeklyInsightLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

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

    private lazy var categoryLegendCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.register(CategoryLegendCell.self, forCellWithReuseIdentifier: "CategoryLegendCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    private var categoryLegendData: [(name: String, info: String, colorIndex: Int, iconName: String)] = []

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
        weeklyChartContainerView.addSubview(weeklyInsightLabel)

        // Category Chart Section
        contentView.addSubview(categoryChartContainerView)
        categoryChartContainerView.addSubview(categoryChartTitleLabel)
        categoryChartContainerView.addSubview(categoryDonutChartView)
        categoryChartContainerView.addSubview(categoryLegendCollectionView)
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
            make.height.equalTo(360)
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
            make.height.equalTo(160)
        }

        weeklyInsightLabel.snp.makeConstraints { make in
            make.top.equalTo(weeklyChartView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
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

        categoryLegendCollectionView.snp.makeConstraints { make in
            make.top.equalTo(categoryDonutChartView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.greaterThanOrEqualTo(48)
        }
    }

    private func createCategoryLegendItems() {
        let repository = CategoryRepository()
        let categories = repository.readCategoryList()

        // 카테고리별 링크 개수 계산
        categoryLegendData = []
        var totalCategoryLinks = 0

        for category in categories {
            let linkCount = category.category.count
            if linkCount > 0 {
                totalCategoryLinks += linkCount
            }
        }

        guard totalCategoryLinks > 0 else {
            categoryLegendData = []
            categoryLegendCollectionView.reloadData()
            return
        }

        // 카테고리 데이터 생성
        var tempData: [(name: String, count: Int, colorIndex: Int, iconName: String)] = []
        for category in categories {
            let linkCount = category.category.count
            if linkCount > 0 {
                tempData.append((
                    name: category.name,
                    count: linkCount,
                    colorIndex: category.colorIndex,
                    iconName: category.iconName
                ))
            }
        }

        // 링크 개수가 많은 순으로 정렬
        tempData.sort { $0.count > $1.count }

        // 범례 데이터 생성
        for data in tempData {
            let percentage = Double(data.count) / Double(totalCategoryLinks) * 100
            let info = "\(data.count)개 · \(Int(percentage))%"
            categoryLegendData.append((
                name: data.name,
                info: info,
                colorIndex: data.colorIndex,
                iconName: data.iconName
            ))
        }

        categoryLegendCollectionView.reloadData()

        // 컬렉션뷰 높이 업데이트
        let rows = ceil(Double(categoryLegendData.count) / 2.0)
        let height = rows * 60 + max(0, rows - 1) * 12
        categoryLegendCollectionView.snp.updateConstraints { make in
            make.height.greaterThanOrEqualTo(height)
        }
    }

    private func bindData() {
        // 링크 데이터 변경 감지
        LinkManager.shared.links
            .bind(with: self) { owner, links in
                // 전체 링크 개수 업데이트
                owner.categoryDonutChartView.updateTotalCount(links.count)

                // 카테고리 분포 업데이트
                owner.updateCategoryDistribution()

                // 주간 차트 업데이트
                owner.updateWeeklyChart(with: links)

                // 캘린더 업데이트
                owner.calendarView.updateEvents(with: links)
            }
            .disposed(by: disposeBag)

        // 카테고리 변경 감지
        NotificationCenter.default.rx
            .notification(.categoryDidUpdate)
            .bind(with: self) { owner, _ in
                owner.updateCategoryDistribution()
            }
            .disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(.categoryDidDelete)
            .bind(with: self) { owner, _ in
                owner.updateCategoryDistribution()
            }
            .disposed(by: disposeBag)
    }

    private func updateCategoryDistribution() {
        let repository = CategoryRepository()
        let categories = repository.readCategoryList()

        // 카테고리별 링크 개수 계산
        var categoryCounts: [(count: Int, colorIndex: Int)] = []
        var totalCategoryLinks = 0

        for category in categories {
            let linkCount = category.category.count
            if linkCount > 0 {
                categoryCounts.append((count: linkCount, colorIndex: category.colorIndex))
                totalCategoryLinks += linkCount
            }
        }

        guard totalCategoryLinks > 0 else {
            categoryDonutChartView.updateChartData([])
            createCategoryLegendItems()
            return
        }

        // 카테고리별 비율 계산
        var categoryData: [(percentage: CGFloat, color: UIColor)] = []
        for item in categoryCounts {
            let percentage = CGFloat(item.count) / CGFloat(totalCategoryLinks)
            let color = CategoryColor.color(index: item.colorIndex)
            categoryData.append((percentage: percentage, color: color))
        }

        categoryDonutChartView.updateChartData(categoryData)
        createCategoryLegendItems()
    }

    private func updateWeeklyChart(with links: [LinkMetadata]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 최근 7일간의 날짜 생성
        var dailyCounts: [Int] = Array(repeating: 0, count: 7)
        var totalCount = 0
        var weeklyLinks: [LinkMetadata] = []

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -6 + i, to: today) else { continue }

            let linksOnDate = links.filter { link in
                calendar.isDate(link.createdAt, inSameDayAs: date)
            }

            dailyCounts[i] = linksOnDate.count
            totalCount += linksOnDate.count
            weeklyLinks.append(contentsOf: linksOnDate)
        }

        // 주간 총 개수 업데이트
        weeklyChartCountLabel.text = "\(totalCount)"

        // 차트 업데이트
        weeklyChartView.updateChartData(dailyCounts)

        // 주간 인사이트 업데이트
        updateWeeklyInsight(with: weeklyLinks)
    }

    private func updateWeeklyInsight(with weeklyLinks: [LinkMetadata]) {
        guard !weeklyLinks.isEmpty else {
            weeklyInsightLabel.text = "이번 주에 저장한 링크가 없습니다"
            return
        }

        // 카테고리별 링크 개수 계산
        var categoryCounts: [String: Int] = [:]

        for link in weeklyLinks {
            if let categories = link.categories {
                for category in categories {
                    categoryCounts[category.name, default: 0] += 1
                }
            }
        }

        // 가장 많이 저장한 카테고리 찾기
        if let topCategory = categoryCounts.max(by: { $0.value < $1.value }) {
            weeklyInsightLabel.text = "이번 주 가장 많이 저장한 카테고리는 '\(topCategory.key)'입니다"
        } else {
            weeklyInsightLabel.text = ""
        }
    }
}

// MARK: - StatisticsViewController CollectionView Extension
extension StatisticsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryLegendData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryLegendCell", for: indexPath) as! CategoryLegendCell
        let data = categoryLegendData[indexPath.item]
        let color = CategoryColor.color(index: data.colorIndex)
        cell.configure(name: data.name, info: data.info, color: color, iconName: data.iconName)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 12
        let width = (collectionView.bounds.width - spacing) / 2
        return CGSize(width: width, height: 60)
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
    private var barContainers: [UIView] = []

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
            make.top.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(160)
        }

        // Create 7 bar items
        for index in 0..<7 {
            let barContainer = createBarContainer(dayLabel: dayLabels[index], count: 0)
            barStackView.addArrangedSubview(barContainer)
            barContainers.append(barContainer)
        }
    }

    func updateChartData(_ dailyCounts: [Int]) {
        guard dailyCounts.count == 7 else { return }

        // 최대값 찾기 (높이 정규화용)
        let maxCount = dailyCounts.max() ?? 1

        // 기존 막대 제거
        barContainers.forEach { $0.removeFromSuperview() }
        barContainers.removeAll()

        // 새 막대 추가
        for (index, count) in dailyCounts.enumerated() {
            let normalizedHeight: CGFloat = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
            let barContainer = createBarContainer(dayLabel: dayLabels[index], count: count, height: normalizedHeight)
            barStackView.addArrangedSubview(barContainer)
            barContainers.append(barContainer)
        }
    }

    private func createBarContainer(dayLabel: String, count: Int, height: CGFloat = 0) -> UIView {
        let container = UIView()

        let barView = UIView()
        barView.backgroundColor = height > 0 ? .clippyBlue.withAlphaComponent(0.8) : .systemGray5
        barView.layer.cornerRadius = 8
        barView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        // 개수 라벨 추가 (막대 위에 배치)
        let countLabel = UILabel()
        countLabel.text = count > 0 ? "\(count)" : ""
        countLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        countLabel.textColor = .clippyBlue
        countLabel.textAlignment = .center

        let label = UILabel()
        label.text = dayLabel
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center

        container.addSubview(countLabel)
        container.addSubview(barView)
        container.addSubview(label)

        // 최대 높이를 130으로 제한 (160에서 줄임)
        let maxBarHeight: CGFloat = 130
        let barHeight = height > 0 ? max(maxBarHeight * height, 20) : 20

        countLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(barView.snp.top).offset(-4)
        }

        barView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(4)
            make.bottom.equalTo(label.snp.top).offset(-8)
            make.height.equalTo(barHeight)
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
        label.text = "0"
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

    private var chartData: [(percentage: CGFloat, color: UIColor)] = []

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

    func updateTotalCount(_ count: Int) {
        centerLabel.text = "\(count)"
    }

    func updateChartData(_ data: [(percentage: CGFloat, color: UIColor)]) {
        chartData = data
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawDonutChart(in: rect)
    }

    private func drawDonutChart(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard !chartData.isEmpty else { return }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = min(rect.width, rect.height) / 2 - 20
        let lineWidth: CGFloat = 30
        let gapAngle: CGFloat = 0.05 // 각 섹션 사이 간격 (라디안) - 0.02에서 0.05로 증가

        var startAngle: CGFloat = -.pi / 2 // Start from top

        for (percentage, color) in chartData {
            // 간격을 고려하여 실제 그릴 각도 계산
            let actualPercentage = percentage * 2 * .pi
            // 시작과 끝에 간격의 절반씩 적용
            let drawStartAngle = startAngle + (gapAngle / 2)
            let drawEndAngle = startAngle + actualPercentage - (gapAngle / 2)

            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: drawStartAngle,
                endAngle: drawEndAngle,
                clockwise: true
            )

            context.setStrokeColor(color.cgColor)
            context.setLineWidth(lineWidth)
            context.setLineCap(.butt)
            context.addPath(path.cgPath)
            context.strokePath()

            startAngle = startAngle + actualPercentage
        }
    }
}

// MARK: - Category Legend Cell
final class CategoryLegendCell: UICollectionViewCell {
    private let itemView = CategoryLegendItemView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(itemView)
        itemView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(name: String, info: String, color: UIColor, iconName: String) {
        itemView.configure(name: name, info: info, color: color, iconName: iconName)
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
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let infoLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.lineBreakMode = .byTruncatingTail
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
            make.trailing.lessThanOrEqualToSuperview().offset(-4)
            make.top.equalToSuperview().offset(6)
        }

        infoLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-4)
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
    private var createdDates: Set<Date> = [] // 링크 저장 날짜
    private var dueDates: Set<Date> = [] // 마감일 날짜

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

    private let legendStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .leading
        return stackView
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
        addSubview(legendStackView)

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

        legendStackView.snp.makeConstraints { make in
            make.trailing.equalTo(datesCollectionView.snp.trailing)
            make.bottom.equalTo(datesCollectionView.snp.bottom).offset(-28)
        }

        datesCollectionView.delegate = self
        datesCollectionView.dataSource = self

        setupWeekdayLabels()
        setupLegend()
    }

    private func setupLegend() {
        // 저장 날짜 범례
        let createdLegend = createLegendItem(color: .clippyBlue, text: "저장 날짜")
        legendStackView.addArrangedSubview(createdLegend)

        // 마감일 범례
        let dueLegend = createLegendItem(color: .systemRed, text: "마감일")
        legendStackView.addArrangedSubview(dueLegend)
    }

    private func createLegendItem(color: UIColor, text: String) -> UIView {
        let container = UIView()

        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 3

        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel

        container.addSubview(dot)
        container.addSubview(label)

        dot.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(6)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(6)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        return container
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

        // 스와이프 제스처 추가
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipeGesture.direction = .left
        datesCollectionView.addGestureRecognizer(leftSwipeGesture)

        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipeGesture.direction = .right
        datesCollectionView.addGestureRecognizer(rightSwipeGesture)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            // 왼쪽으로 스와이프 -> 다음 달
            nextMonthTapped()
        case .right:
            // 오른쪽으로 스와이프 -> 이전 달
            prevMonthTapped()
        default:
            break
        }
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

    func updateEvents(with links: [LinkMetadata]) {
        let calendar = Calendar.current
        var newCreatedDates = Set<Date>()
        var newDueDates = Set<Date>()

        for link in links {
            // 저장 날짜 추가 (시간 제거)
            let createdDay = calendar.startOfDay(for: link.createdAt)
            newCreatedDates.insert(createdDay)

            // 마감일 추가 (있으면)
            if let dueDate = link.dueDate {
                let dueDay = calendar.startOfDay(for: dueDate)
                newDueDates.insert(dueDay)
            }
        }

        createdDates = newCreatedDates
        dueDates = newDueDates
        datesCollectionView.reloadData()
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

            // 이벤트 타입 확인
            let hasCreatedEvent = createdDates.contains(day)
            let hasDueEvent = dueDates.contains(day)

            cell.configure(
                day: dayNumber,
                isToday: isToday,
                isSelected: isSelected,
                hasCreatedEvent: hasCreatedEvent,
                hasDueEvent: hasDueEvent
            )
        } else {
            cell.configure(
                day: nil,
                isToday: false,
                isSelected: false,
                hasCreatedEvent: false,
                hasDueEvent: false
            )
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 6 * 8) / 7
        let height = width + 2 // 이벤트 점을 위한 추가 공간 더 줄임 (4 -> 2)
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let date = days[indexPath.item] else { return }
        selectedDate = date
        collectionView.reloadData()
    }
}

// MARK: - Calendar Date Cell
final class CalendarDateCell: UICollectionViewCell {

    private let backgroundCircle = UIView()

    private let dayLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let eventDotsStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .fillEqually
        stackView.isHidden = true
        return stackView
    }()

    private let createdEventDot = {
        let view = UIView()
        view.backgroundColor = .clippyBlue
        view.layer.cornerRadius = 3
        return view
    }()

    private let dueEventDot = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 3
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
        contentView.addSubview(backgroundCircle)
        contentView.addSubview(dayLabel)
        contentView.addSubview(eventDotsStackView)

        let circleSize: CGFloat = 32
        backgroundCircle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(2)
            make.width.height.equalTo(circleSize)
        }

        dayLabel.snp.makeConstraints { make in
            make.center.equalTo(backgroundCircle)
        }

        eventDotsStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(backgroundCircle.snp.bottom)
            make.bottom.equalToSuperview()
            make.height.equalTo(6)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 완벽한 원형으로 만들기 위해 layoutSubviews에서 cornerRadius 설정
        backgroundCircle.layer.cornerRadius = backgroundCircle.bounds.width / 2
    }

    func configure(day: Int?, isToday: Bool, isSelected: Bool, hasCreatedEvent: Bool, hasDueEvent: Bool) {
        if let day = day {
            dayLabel.text = "\(day)"
            dayLabel.isHidden = false
            backgroundCircle.isHidden = false

            if isSelected {
                // 선택된 날짜: 배경색 있음
                backgroundCircle.backgroundColor = .clippyBlue.withAlphaComponent(0.3)
                dayLabel.textColor = .clippyBlue
            } else if isToday {
                // 오늘: 다른 날짜가 선택되면 배경색 없이 텍스트만 포인트 색상
                backgroundCircle.backgroundColor = .clear
                dayLabel.textColor = .clippyBlue
            } else {
                // 일반 날짜: 배경색 없음, 기본 텍스트 색상
                backgroundCircle.backgroundColor = .clear
                dayLabel.textColor = .label
            }

            // 이벤트 점 표시
            eventDotsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            if hasCreatedEvent || hasDueEvent {
                eventDotsStackView.isHidden = false

                if hasCreatedEvent {
                    let dot = UIView()
                    dot.backgroundColor = .clippyBlue
                    dot.layer.cornerRadius = 3
                    dot.snp.makeConstraints { make in
                        make.width.height.equalTo(6)
                    }
                    eventDotsStackView.addArrangedSubview(dot)
                }

                if hasDueEvent {
                    let dot = UIView()
                    dot.backgroundColor = .systemRed
                    dot.layer.cornerRadius = 3
                    dot.snp.makeConstraints { make in
                        make.width.height.equalTo(6)
                    }
                    eventDotsStackView.addArrangedSubview(dot)
                }
            } else {
                eventDotsStackView.isHidden = true
            }
        } else {
            dayLabel.isHidden = true
            backgroundCircle.isHidden = true
            eventDotsStackView.isHidden = true
        }
    }
}
