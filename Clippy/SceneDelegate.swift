//
//  SceneDelegate.swift
//  Clippy
//
//  Created by 서지민 on 9/23/25.
//

import UIKit
import RxSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let appGroupID = "group.com.jimin.Clippy"
    private let metadataDisposeBag = DisposeBag() // 메타데이터 업데이트용 DisposeBag


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
        let statisticsVC = UINavigationController(rootViewController: StatisticsViewController())
        statisticsVC.tabBarItem = UITabBarItem(title: "통계", image: UIImage(systemName: "chart.bar"), selectedImage: UIImage(systemName: "chart.bar.fill"))
        // 설정 탭 비활성화 (다음 배포에서 구현 예정)
        // let settingVC = SettingViewController()
        // settingVC.tabBarItem = UITabBarItem(title: "설정", image: UIImage(systemName: "gearshape.2"), selectedImage: UIImage(systemName: "gearshape.2.fill"))

        // 탭바를 4개로 변경 (카테고리, 검색, 즐겨찾기, 통계)
        tabBarController.viewControllers = [categoryVC, searchVC, likeVC, statisticsVC]
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

        // URL 스킴으로 앱이 열린 경우 처리 (clippy://add?url=...)
        if let urlContext = connectionOptions.urlContexts.first {
            handleURLContext(urlContext, tabBarController: tabBarController)
        }

        // 카테고리 목록을 App Group에 동기화
        syncCategoriesToAppGroup()
        
        // 앱 시작 시에도 공유된 항목 확인
        importSharedItemsIfNeeded()

        // 카테고리 변경 알림 구독하여 동기화 유지
        NotificationCenter.default.addObserver(forName: .categoryDidCreate, object: nil, queue: .main) { [weak self] _ in
            self?.syncCategoriesToAppGroup()
            self?.syncSavedLinksToAppGroup()
        }
        NotificationCenter.default.addObserver(forName: .categoryDidUpdate, object: nil, queue: .main) { [weak self] _ in
            self?.syncCategoriesToAppGroup()
        }
        NotificationCenter.default.addObserver(forName: .categoryDidDelete, object: nil, queue: .main) { [weak self] _ in
            self?.syncCategoriesToAppGroup()
            self?.syncSavedLinksToAppGroup()
        }
        NotificationCenter.default.addObserver(forName: .linkDidCreate, object: nil, queue: .main) { [weak self] _ in
            self?.syncSavedLinksToAppGroup()
        }
        NotificationCenter.default.addObserver(forName: .linkDidDelete, object: nil, queue: .main) { [weak self] _ in
            self?.syncSavedLinksToAppGroup()
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

        // Share Extension에서 적재된 항목을 수신해 저장
        importSharedItemsIfNeeded()
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
        
        // Share Extension에서 적재된 항목을 수신해 저장 (포그라운드 진입 시에도 체크)
        importSharedItemsIfNeeded()
        
        // 알림으로 앱이 포그라운드로 온 경우는 제거
        // (알림 탭으로만 마감 임박 화면으로 이동하도록 수정)
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
            
            navigateToExpiringLinks(tabBarController: tabBarController, highlightLinkId: linkId)
        }
    }
    
    private func navigateToExpiringLinks(tabBarController: UITabBarController, highlightLinkId: String? = nil) {
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
                
                // 하이라이트할 링크 ID가 있으면 전달
                if let linkId = highlightLinkId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("HighlightExpiringLink"),
                            object: nil,
                            userInfo: ["linkId": linkId]
                        )
                    }
                }
            }
        }
    }
}

// MARK: - App Group Shared Items Import
extension SceneDelegate {
    private func importSharedItemsIfNeeded() {
        let defaults = UserDefaults(suiteName: appGroupID)
        guard let items = defaults?.array(forKey: "shared_items") as? [[String: String]], !items.isEmpty else {
            return
        }

        let repository = CategoryRepository()
        repository.createDefaultCategory()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy. MM. dd."

        // 1단계: Realm에 먼저 저장 (빠른 표시)
        for item in items {
            guard let urlString = item["url"], !urlString.isEmpty else { continue }
            guard let url = URL(string: urlString) else { continue }

            let userTitle = item["title"]
            let userMemo = item["memo"]
            let dueDateString = item["dueDate"]
            let dueDate: Date? = dueDateString.flatMap { dateFormatter.date(from: $0) }

            let selectedCategoriesString = item["categories"] ?? ""
            let selectedCategoryNames = selectedCategoriesString.split(separator: "|").map { String($0) }.filter { !$0.isEmpty }
            let targetCategories = selectedCategoryNames.isEmpty ? ["일반"] : selectedCategoryNames

            // 일단 URL을 제목으로 사용하여 Realm에 저장
            let tempTitle = userTitle?.isEmpty == false ? userTitle! : urlString
            let tempDescription = userMemo?.isEmpty == false ? userMemo : nil

            for categoryName in targetCategories {
                repository.addLink(
                    title: tempTitle,
                    url: urlString,
                    description: tempDescription,
                    categoryName: categoryName,
                    deadline: dueDate
                )
            }
        }

        // UserDefaults 클리어
        defaults?.removeObject(forKey: "shared_items")

        // 2단계: LinkManager 캐시 새로고침 (Realm 데이터 로드)
        LinkManager.shared.refreshLinks()

        // 3단계: UI 업데이트 알림
        NotificationCenter.default.post(name: .linkDidCreate, object: nil)

        // 4단계: 백그라운드에서 메타데이터 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            for item in items {
                guard let urlString = item["url"], !urlString.isEmpty else { continue }
                guard let url = URL(string: urlString) else { continue }

                let userTitle = item["title"]
                let userMemo = item["memo"]

                // 메타데이터 가져오기
                LinkManager.shared.fetchLinkMetadata(for: url)
                    .observe(on: MainScheduler.instance)
                    .subscribe(onNext: { metadata in
                        // 사용자가 title을 입력하지 않았으면 메타데이터로 업데이트
                        if userTitle?.isEmpty != false {
                            let finalTitle = metadata.title
                            let finalDescription = userMemo?.isEmpty == false ? userMemo : metadata.description

                            // Realm에서 해당 URL의 모든 링크 찾아서 업데이트
                            repository.updateLinkTitleAndDescription(
                                url: urlString,
                                title: finalTitle,
                                description: finalDescription
                            )

                            // LinkManager 캐시 새로고침
                            LinkManager.shared.refreshLinks()
                        }
                    })
                    .disposed(by: self.metadataDisposeBag)
            }
        }
    }

    private func syncCategoriesToAppGroup() {
        let repository = CategoryRepository()
        let categories = repository.readCategoryList()
        let payload: [[String: Any]] = categories.map { [
            "name": $0.name,
            "colorIndex": $0.colorIndex
        ] }

        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(payload, forKey: "categories")
    }

    // --- AppGroup으로 전체 저장 URL 동기화 ---
    private func syncSavedLinksToAppGroup() {
        let categoryRepo = CategoryRepository()
        let categories = categoryRepo.readCategoryList()
        let allLinks = categories.flatMap { $0.category } // Realm 리스트 flatMap
        let urlArr = allLinks.compactMap { $0.url }
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(urlArr, forKey: "saved_links")
    }
}

// MARK: - URL Scheme Handling
extension SceneDelegate {
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let tabBarController = window?.rootViewController as? UITabBarController,
              let urlContext = URLContexts.first else { return }
        handleURLContext(urlContext, tabBarController: tabBarController)
    }

    private func handleURLContext(_ urlContext: UIOpenURLContext, tabBarController: UITabBarController) {
        let url = urlContext.url
        guard url.scheme == "clippy" else { return }

        // clippy://add?url=ENCODED_URL
        if url.host == "add" {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? [URLQueryItem]()
            let sharedURLString = queryItems.first(where: { $0.name == "url" })?.value
            presentEditLink(with: sharedURLString, tabBarController: tabBarController)
        }
    }

    private func presentEditLink(with urlString: String?, tabBarController: UITabBarController) {
        // 카테고리 탭(NavController) 기준으로 표시
        tabBarController.selectedIndex = 0
        guard let nav = tabBarController.viewControllers?.first as? UINavigationController else { return }

        let editVC = EditLinkViewController()
        editVC.prefillURLString = urlString
        nav.present(UINavigationController(rootViewController: editVC), animated: true)
    }
}