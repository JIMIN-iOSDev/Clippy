//
//  SceneDelegate.swift
//  Clippy
//
//  Created by 서지민 on 9/23/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        
        // 앱 아이콘 배지 제거
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let tabBarController = UITabBarController()
        let categoryVC = UINavigationController(rootViewController: CategoryViewController())
        categoryVC.tabBarItem = UITabBarItem(title: "카테고리", image: UIImage(systemName: "square.grid.2x2"), selectedImage: UIImage(systemName: "square.grid.2x2.fill"))
        let searchVC = SearchViewController()
        searchVC.tabBarItem = UITabBarItem(title: "검색", image: UIImage(systemName: "magnifyingglass"), selectedImage: UIImage(systemName: "magnifyingglass"))
        let likeVC = UINavigationController(rootViewController: LikeViewController())
        likeVC.tabBarItem = UITabBarItem(title: "즐겨찾기", image: UIImage(systemName: "star"), selectedImage: UIImage(systemName: "star.fill"))
        // 설정 탭 비활성화 (다음 배포에서 구현 예정)
        // let settingVC = SettingViewController()
        // settingVC.tabBarItem = UITabBarItem(title: "설정", image: UIImage(systemName: "gearshape.2"), selectedImage: UIImage(systemName: "gearshape.2.fill"))
        
        // 탭바를 3개로 변경 (카테고리, 검색, 즐겨찾기)
        tabBarController.viewControllers = [categoryVC, searchVC, likeVC]
        tabBarController.tabBar.tintColor = .clippyBlue
        tabBarController.tabBar.unselectedItemTintColor = .systemGray
        
        // 탭바 불투명하게 설정
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .separator
        appearance.shadowImage = UIImage()
        
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        
        // 알림으로 앱이 열린 경우 처리
        if let notificationResponse = connectionOptions.notificationResponse {
            handleNotificationResponse(notificationResponse, tabBarController: tabBarController)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        // 앱이 활성화될 때마다 배지 제거
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        // 앱이 포그라운드로 올 때 배지 제거
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // 알림으로 앱이 포그라운드로 온 경우 처리
        if let tabBarController = window?.rootViewController as? UITabBarController {
            // 현재 대기 중인 알림 응답이 있는지 확인
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                // 최근 알림이 있다면 마감 임박 화면으로 이동
                if let recentNotification = notifications.first,
                   let userInfo = recentNotification.request.content.userInfo as? [String: Any],
                   let linkId = userInfo["linkId"] as? String {
                    
                    DispatchQueue.main.async {
                        self.navigateToExpiringLinks(tabBarController: tabBarController)
                    }
                }
            }
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    // MARK: - Notification Handling
    
    private func handleNotificationResponse(_ response: UNNotificationResponse, tabBarController: UITabBarController) {
        let userInfo = response.notification.request.content.userInfo
        
        // 마감 임박 알림인지 확인
        if let linkId = userInfo["linkId"] as? String,
           let title = userInfo["title"] as? String {
            
            navigateToExpiringLinks(tabBarController: tabBarController)
        }
    }
    
    private func navigateToExpiringLinks(tabBarController: UITabBarController) {
        // 카테고리 탭으로 이동
        tabBarController.selectedIndex = 0
        
        // 마감 임박 화면으로 이동
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let categoryNavController = tabBarController.viewControllers?[0] as? UINavigationController {
                
                let linkListVC = LinkListViewController(mode: .expiring)
                
                // 백버튼 제목 완전히 숨기기
                linkListVC.navigationItem.backButtonTitle = ""
                
                // 네비게이션 컨트롤러의 백버튼 스타일 설정
                categoryNavController.navigationBar.topItem?.backButtonTitle = ""
                
                categoryNavController.pushViewController(linkListVC, animated: true)
            }
        }
    }
}