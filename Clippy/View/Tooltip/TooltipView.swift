import UIKit
import SnapKit

enum TooltipDirection {
    case top, bottom, left, right
}

class TooltipView: UIView {
    
    // MARK: - Properties
    var onDismiss: (() -> Void)?
    private var arrowDirection: TooltipDirection = .top
    
    // MARK: - UI Components
    private let overlayView = UIView() // 말풍선 주변 터치 차단용 (반투명하지 않음)
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let arrowView = TriangleView()
    
    // MARK: - Initialization
    init(message: String, arrowDirection: TooltipDirection) {
        self.arrowDirection = arrowDirection
        super.init(frame: .zero)
        setupUI()
        messageLabel.text = message
        arrowView.configure(direction: arrowDirection, color: UIColor.darkGray)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        setupOverlayView()
        setupBubbleView()
        setupMessageLabel()
        setupCloseButton()
        setupArrowView()
        setupLayout()
    }
    
    private func setupOverlayView() {
        overlayView.backgroundColor = UIColor.clear // 투명하게 설정
        overlayView.isUserInteractionEnabled = true
        addSubview(overlayView)
    }
    
    private func setupBubbleView() {
        bubbleView.backgroundColor = UIColor.darkGray
        bubbleView.layer.cornerRadius = 12
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 2)
        bubbleView.layer.shadowOpacity = 0.3
        bubbleView.layer.shadowRadius = 8
        addSubview(bubbleView)
    }
    
    private func setupMessageLabel() {
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        messageLabel.textColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        bubbleView.addSubview(messageLabel)
    }
    
    private func setupCloseButton() {
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.clear
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        bubbleView.addSubview(closeButton)
    }
    
    private func setupArrowView() {
        arrowView.backgroundColor = UIColor.clear
        addSubview(arrowView)
    }
    
    private func setupLayout() {
        // 오버레이 전체 화면 덮기 (투명)
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 말풍선 크기 설정 (너비 동적, 높이 동적)
        bubbleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            if messageLabel.text?.contains("카테고리") == true {
                // 카테고리 말풍선은 더 작은 너비로 조정
                make.width.equalTo(180)
            } else {
                // 나머지는 기본 너비
                make.width.equalTo(250)
            }
            make.height.greaterThanOrEqualTo(50)
        }
        
        // 메시지 라벨 (말풍선 높이를 결정)
        messageLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(closeButton.snp.leading).offset(-8)
            make.top.bottom.equalToSuperview().inset(12)
            make.height.greaterThanOrEqualTo(26) // 최소 높이 보장
        }
        
        // 닫기 버튼
        closeButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
            make.width.height.equalTo(24)
        }
        
        // 화살표 위치 설정 (타겟과 말풍선 사이 중간에 배치)
        switch arrowDirection {
        case .top:
            // 타겟 위쪽: 말풍선 아래쪽에 화살표 배치 (위로 향함)
            arrowView.snp.makeConstraints { make in
                make.centerX.equalTo(bubbleView)
                make.top.equalTo(bubbleView.snp.bottom).offset(-1)
                make.width.height.equalTo(16)
            }
        case .bottom:
            // 타겟 아래쪽: 말풍선 위쪽에 화살표 배치 (아래로 향함)
            arrowView.snp.makeConstraints { make in
                make.centerX.equalTo(bubbleView.snp.centerX)
                make.bottom.equalTo(bubbleView.snp.top).offset(1)
                make.width.height.equalTo(16)
            }
        case .left:
            // 타겟 왼쪽: 말풍선 오른쪽에 화살표 배치 (왼쪽으로 향함)
            arrowView.snp.makeConstraints { make in
                make.centerY.equalTo(bubbleView)
                make.left.equalTo(bubbleView.snp.right).offset(-1)
                make.width.height.equalTo(16)
            }
        case .right:
            // 타겟 오른쪽: 말풍선 왼쪽에 화살표 배치 (오른쪽으로 향함)
            arrowView.snp.makeConstraints { make in
                make.centerY.equalTo(bubbleView)
                if messageLabel.text?.contains("카테고리") == true {
                    // 카테고리 화살표는 기본 위치와 조금 다르게
                    make.right.equalTo(bubbleView.snp.left).offset(1)
                } else {
                    // 나머지는 기본 위치
                    make.right.equalTo(bubbleView.snp.left).offset(1)
                }
                make.width.height.equalTo(16)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismissTooltip()
    }
    
    public func show(in parentView: UIView, near targetView: UIView? = nil) {
        parentView.addSubview(self)
        
        // 말풍선이 화면 밖으로 나가지 않도록 부모 뷰 범위 내에서 위치 조정
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 오버레이는 터치 차단, 말풍선은 터치 가능하게 설정
        overlayView.isUserInteractionEnabled = true
        bubbleView.isUserInteractionEnabled = true
        
        // 말풍선과 화살표를 오버레이 위로 올리기
        bringSubviewToFront(bubbleView)
        bringSubviewToFront(arrowView)
        
        // 타겟 뷰 근처에 위치시키기
        if let targetView = targetView {
            positionNearTarget(targetView, in: parentView)
        }
        
        // 애니메이션으로 나타나기
        alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
        }
    }
    
    private func positionNearTarget(_ targetView: UIView, in parentView: UIView) {
        // 화면 위치 계산
        let targetFrame = targetView.convert(targetView.bounds, to: parentView)
        let bubbleHeight = bubbleView.frame.height > 0 ? bubbleView.frame.height : 50
        let margin: CGFloat = 10
        
        // 기존 제약조건들 제거
        snp.removeConstraints()
        bubbleView.snp.removeConstraints()
        
        // 전체 화면 제약 조건 다시 설정
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 말풍선 위치 설정
        switch arrowDirection {
        case .top:
            // 타겟 위쪽에 배치
            bubbleView.snp.makeConstraints { make in
                make.centerX.equalTo(targetFrame.midX)
                make.bottom.equalTo(parentView).offset(-(parentView.bounds.height - targetFrame.minY + margin))
            }
        case .bottom:
            // 링크 추가 버튼의 경우 오른쪽 끝 정렬
            if messageLabel.text?.contains("링크 추가") == true {
                bubbleView.snp.makeConstraints { make in
                    make.right.equalTo(targetFrame.maxX)
                    make.top.equalTo(targetFrame.maxY + margin)
                }
            } else {
                // 나머지는 중앙 정렬
                bubbleView.snp.makeConstraints { make in
                    make.centerX.equalTo(targetFrame.midX)
                    make.top.equalTo(targetFrame.maxY + margin)
                }
            }
        case .left:
            // 타겟 왼쪽에 배치
            bubbleView.snp.makeConstraints { make in
                make.centerY.equalTo(targetFrame.midY)
                make.right.equalTo(targetFrame.minX - margin)
            }
        case .right:
            // 타겟 오른쪽에 배치 (카테고리는 아주 살짝만 추가 거리)
            if messageLabel.text?.contains("카테고리") == true {
                // 카테고리 말풍선은 아주 살짝만 추가 거리 (5pt)
                bubbleView.snp.makeConstraints { make in
                    make.centerY.equalTo(targetFrame.midY)
                    make.left.equalTo(targetFrame.maxX + margin + 5)
                }
            } else {
                // 나머지는 기본 거리
                bubbleView.snp.makeConstraints { make in
                    make.centerY.equalTo(targetFrame.midY)
                    make.left.equalTo(targetFrame.maxX + margin)
                }
            }
        }
    }
    
    public func dismissTooltip() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            self.onDismiss?()
        }
    }
}

// MARK: - Triangle Arrow View
class TriangleView: UIView {
    private var direction: TooltipDirection = .bottom
    private var fillColor: UIColor = UIColor.darkGray
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
    }
    
    func configure(direction: TooltipDirection, color: UIColor = UIColor.darkGray) {
        self.direction = direction
        self.fillColor = color
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.clear(rect)
        context.setFillColor(fillColor.cgColor)
        context.setShadow(offset: CGSize(width: 0, height: 1), blur: 4, color: UIColor.black.withAlphaComponent(0.3).cgColor)
        
        context.beginPath()
        
        switch direction {
        case .top:
            context.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            context.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        case .bottom:
            context.move(to: CGPoint(x: rect.midX, y: rect.minY))
            context.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .left:
            context.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            context.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            context.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .right:
            context.move(to: CGPoint(x: rect.minX, y: rect.midY))
            context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        
        context.closePath()
        context.fillPath()
    }
}