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
            // Error fetching FCM registration token
          } else if let token = token {
            // FCM registration token 발급 성공
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

    /// 기존 Documents 폴더의 Realm 파일을 App Group 컨테이너로 마이그레이션
    private func migrateRealmToAppGroup(targetURL: URL) {
        let fileManager = FileManager.default

        // App Group에 이미 Realm 파일이 있으면 마이그레이션 불필요
        if fileManager.fileExists(atPath: targetURL.path) {
            print("App Group에 Realm 파일이 이미 존재합니다. 마이그레이션 건너뜀.")
            return
        }

        // 기존 Documents 폴더의 Realm 파일 경로
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents 폴더를 찾을 수 없습니다")
            return
        }

        let oldRealmURL = documentsURL.appendingPathComponent("default.realm")

        // 기존 Realm 파일이 없으면 마이그레이션 불필요 (신규 사용자)
        guard fileManager.fileExists(atPath: oldRealmURL.path) else {
            print("기존 Realm 파일이 없습니다. 신규 사용자로 간주.")
            return
        }

        print("기존 Realm 데이터를 App Group으로 마이그레이션 시작...")

        do {
            // Realm 파일 복사
            try fileManager.copyItem(at: oldRealmURL, to: targetURL)
            print("✅ Realm 파일 복사 성공")

            // 관련 파일들도 복사 (.lock, .note, .management 등)
            let realmRelatedFiles = [".lock", ".note", ".management"]
            for suffix in realmRelatedFiles {
                let oldFileURL = documentsURL.appendingPathComponent("default.realm\(suffix)")
                let newFileURL = targetURL.deletingPathExtension().appendingPathExtension("realm\(suffix)")

                if fileManager.fileExists(atPath: oldFileURL.path) {
                    try? fileManager.copyItem(at: oldFileURL, to: newFileURL)
                }
            }

            print("✅ Realm 데이터 마이그레이션 완료")

            // 마이그레이션 성공 후 기존 파일 삭제 (선택사항)
            // 안전을 위해 주석 처리. 필요시 활성화
            // try? fileManager.removeItem(at: oldRealmURL)

        } catch {
            print("❌ Realm 마이그레이션 실패: \(error)")
        }
    }

    private func configureRealmMigration() {
        // App Group 컨테이너 URL 가져오기 (위젯과 공유하기 위해)
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.jimin.Clippy") else {
            print("App Group URL을 찾을 수 없습니다")
            return
        }

        let realmURL = appGroupURL.appendingPathComponent("default.realm")

        // 기존 데이터 마이그레이션: Documents 폴더 -> App Group
        migrateRealmToAppGroup(targetURL: realmURL)

        let config = Realm.Configuration(
            fileURL: realmURL,
            schemaVersion: 3, // 위젯과 동일한 버전 사용
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
                // 버전 1 → 2, 2 → 3은 자동 마이그레이션
            }
        )
        Realm.Configuration.defaultConfiguration = config

        // 마이그레이션 적용을 위해 Realm 인스턴스 생성
        do {
            _ = try Realm()
            print("Realm 초기화 성공: \(realmURL.path)")
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
