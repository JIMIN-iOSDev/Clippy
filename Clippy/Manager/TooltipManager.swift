//
//  TooltipManager.swift
//  Clippy
//
//  Created by 서지민 on 9/24/25.
//

import UIKit
import RxSwift
import RxCocoa

enum SequentialTooltipType: String, CaseIterable {
    case savedLinks = "saved_links_tooltip"
    case expiringLinks = "expiring_links_tooltip"
    case defaultCategory = "default_category_tooltip"
    case swipeAction = "swipe_action_tooltip"
    
    var message: String {
        switch self {
        case .savedLinks:
            return "저장된 모든 링크를 볼 수 있습니다"
        case .expiringLinks:
            return "마감일이 3일 이내인\n링크들을 볼 수 있습니다"
        case .defaultCategory:
            return "카테고리를 설정하지 않으면 '일반'으로 저장됩니다"
        case .swipeAction:
            return "좌우로 슬라이드해서 수정·삭제할 수 있습니다"
        }
    }
    
    var direction: TooltipDirection {
        switch self {
        case .savedLinks:
            return .bottom  // 저장된 링크 박스 아래쪽
        case .expiringLinks:
            return .bottom  // 마감 임박 박스 아래쪽
        case .defaultCategory:
            return .right   // 카테고리 레이블 오른쪽
        case .swipeAction:
            return .top     // 링크 항목 위쪽
        }
    }
}

class TooltipManager {
    static let shared = TooltipManager()
    
    private let userDefaults = UserDefaults.standard
    private let hasShownAllTooltipsKey = "has_shown_all_tooltips"
    private var currentViewController: UIViewController?
    private var currentTooltipIndex: Int = 0
    private var currentTooltipView: TooltipView?
    
    private init() {}
    
    // MARK: - Sequential Tooltip System
    
    func shouldStartSequentialTooltips() -> Bool {
        return !userDefaults.bool(forKey: hasShownAllTooltipsKey)
    }
    
    func startSequentialTooltips(in viewController: UIViewController) {
        guard shouldStartSequentialTooltips() else { return }
        
        currentViewController = viewController
        currentTooltipIndex = 0
        
        // 즉시 첫 번째 툴팁 시작 (딜레이 없음)
        DispatchQueue.main.async {
            self.showCurrentSequentialTooltip()
        }
    }
    
    private func showCurrentSequentialTooltip() {
        guard let viewController = currentViewController,
              currentTooltipIndex < SequentialTooltipType.allCases.count else {
            completeSequentialTooltips()
            return
        }
        
        let tooltipType = SequentialTooltipType.allCases[currentTooltipIndex]
        let targetView = getTargetInfo(for: tooltipType, in: viewController)
        
        guard let targetView = targetView else {
            // 대상 뷰가 없으면 다음 툴팁으로
            moveToNextTooltip()
            return
        }
        
        currentTooltipView = TooltipView(message: tooltipType.message, arrowDirection: tooltipType.direction)
        
        currentTooltipView?.onDismiss = { [weak self] in
            self?.moveToNextTooltip()
        }
        
        currentTooltipView?.show(in: viewController.view, near: targetView)
    }
    
    private func getTargetInfo(for tooltipType: SequentialTooltipType, in viewController: UIViewController) -> UIView? {
        guard let categoryVC = findViewController(type: CategoryViewController.self, in: viewController) else {
            return nil
        }
        
        switch tooltipType {
        case .savedLinks:
            return categoryVC.savedLinksView
        case .expiringLinks:
            return categoryVC.expiredLinksView
        case .defaultCategory:
            return categoryVC.categoryTitleLabel
        case .swipeAction:
            // 더미링크 생성 후 스와이프 안내 표시
            createDummyLinkAndShowSwipeGuide(categoryVC: categoryVC)
            return nil
        }
    }
    
    private func moveToNextTooltip() {
        currentTooltipIndex += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showCurrentSequentialTooltip()
        }
    }
    
    private func completeSequentialTooltips() {
        userDefaults.set(true, forKey: hasShownAllTooltipsKey)
        currentViewController = nil
        currentTooltipView = nil
        currentTooltipIndex = 0
    }
    
    private func findViewController<T: UIViewController>(type: T.Type, in viewController: UIViewController) -> T? {
        // 탭바 컨트롤러에서 첫 번째 탭이 카테고리 탭이므로 확인
        if let tabBarController = viewController.tabBarController,
           let navController = tabBarController.viewControllers?.first as? UINavigationController,
           let categoryVC = navController.topViewController as? T {
            return categoryVC
        }
        
        // 현재 뷰 컨트롤러가 구하는 타입인지 확인
        if let targetVC = viewController as? T {
            return targetVC
        }
        
        return nil
    }
    
    func resetSequentialTooltips() {
        userDefaults.set(false, forKey: hasShownAllTooltipsKey)
        currentViewController = nil
        currentTooltipView?.dismissTooltip()
        currentTooltipView = nil
        currentTooltipIndex = 0
    }
    
    private func createDummyLinkAndShowSwipeGuide(categoryVC: CategoryViewController) {
        // 더미링크 생성 후 스와이프 안내 표시
        LinkManager.shared.createDummyLinkForSwipeGuide()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] dummyLink in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.showSwipeTooltipForDummyLink(categoryVC: categoryVC, dummyLink: dummyLink)
                }
            })
            .disposed(by: DisposeBag())
    }
    
    private func showSwipeTooltipForDummyLink(categoryVC: CategoryViewController, dummyLink: LinkMetadata) {
        guard let firstCell = categoryVC.linksTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? LinkTableViewCell else {
            // 셀이 없으면 더미링크 삭제하고 다음 툴팁으로
            LinkManager.shared.deleteDummyLinkForSwipeGuide()
            moveToNextTooltip()
            return
        }
        
        // 스와이프 힌트 애니메이션과 툴팁을 동시에 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 애니메이션과 툴팁을 함께 시작
            firstCell.showSwipeHint()
            
            let tooltip = TooltipView(message: SequentialTooltipType.swipeAction.message, arrowDirection: .top)
            tooltip.onDismiss = { [weak self] in
                // 툴팁 닫을 때 더미링크 삭제
                LinkManager.shared.deleteDummyLinkForSwipeGuide()
                self?.currentTooltipView = nil
                // 0.5초 후 다음 툴팁으로 자연스럽게 이동
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.moveToNextTooltip()
                }
            }
            self.currentTooltipView = tooltip
            tooltip.show(in: categoryVC.view, near: firstCell)
        }
    }
    
}