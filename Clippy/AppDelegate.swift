//
//  AppDelegate.swift
//  Clippy
//
//  Created by 서지민 on 9/23/25.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Realm 마이그레이션 설정
        configureRealmMigration()

        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )

        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        Messaging.messaging().token { token, error in
          if let error = error {
            print("Error fetching FCM registration token: \(error)")
          } else if let token = token {
            print("FCM registration token: \(token)")
          }
        }
        
        // 앱 시작 시 배지 제거
        application.applicationIconBadgeNumber = 0
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Realm Migration
    private func configureRealmMigration() {
        let config = Realm.Configuration(
            schemaVersion: 1, // 스키마 버전 1로 증가
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // 버전 0 → 1: memo 필드를 userMemo와 metadataDescription으로 분리
                    migration.enumerateObjects(ofType: LinkList.className()) { oldObject, newObject in
                        // 기존 memo 데이터를 userMemo로 이동 (사용자가 입력한 것으로 간주)
                        if let memo = oldObject?["memo"] as? String {
                            newObject?["userMemo"] = memo
                        }
                        // metadataDescription은 nil로 초기화 (새로운 링크부터 제대로 저장됨)
                        newObject?["metadataDescription"] = nil
                    }
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config

        // 마이그레이션 적용을 위해 Realm 인스턴스 생성
        do {
            _ = try Realm()
            print("Realm 마이그레이션 완료")
        } catch {
            print("Realm 마이그레이션 실패: \(error)")
        }
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")

      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
      // TODO: If necessary send token to application server.
      // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}
