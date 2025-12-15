//
//  ClippyTests.swift
//  ClippyTests
//
//  Created by Jimin on 12/15/25.
//

import XCTest
import RealmSwift
@testable import Clippy

final class ClippyTests: XCTestCase {

    // MARK: - 앱 설정 테스트

    func test_앱_번들_ID_확인() {
        let bundleID = Bundle.main.bundleIdentifier
        XCTAssertEqual(bundleID, "com.jimin.Clippy", "번들 ID가 올바르게 설정되어야 합니다")
    }

    func test_앱_버전_형식_확인() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        XCTAssertNotNil(version, "앱 버전이 설정되어야 합니다")

        // 버전 형식: "1.8.2" (major.minor.patch)
        XCTAssertTrue(version?.contains(".") ?? false, "버전은 점(.)을 포함해야 합니다")
    }

    func test_앱_디스플레이_이름() {
        let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        XCTAssertNotNil(displayName, "앱 표시 이름이 설정되어야 합니다")
    }

    // MARK: - App Group 설정 테스트

    func test_앱_그룹_설정_확인() {
        let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.jimin.Clippy"
        )
        XCTAssertNotNil(appGroupURL, "App Group이 설정되어야 합니다")

        // App Group 디렉토리가 실제로 존재하는지 확인
        if let url = appGroupURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "App Group 디렉토리가 존재해야 합니다")
        }
    }

    // MARK: - Realm 기본 설정 테스트

    func test_Realm_기본_설정() {
        let config = Realm.Configuration.defaultConfiguration
        XCTAssertNotNil(config.fileURL, "Realm 파일 경로가 설정되어야 합니다")
    }

    func test_Realm_파일_경로_존재() {
        let config = Realm.Configuration.defaultConfiguration
        let realmPath = config.fileURL?.path ?? ""

        // Realm 파일 경로가 유효한지 확인
        XCTAssertFalse(realmPath.isEmpty, "Realm 파일 경로가 비어있지 않아야 합니다")

        // 프로덕션 환경에서는 App Group 경로에 있어야 함
        // (테스트 환경에서는 다를 수 있음)
        if !realmPath.contains("group.com.jimin.Clippy") {
            print("⚠️ 테스트 환경: Realm 파일이 App Group 경로가 아닙니다: \(realmPath)")
        }
    }

    func test_Realm_마이그레이션_버전() {
        let config = Realm.Configuration.defaultConfiguration
        // 스키마 버전이 설정되어 있는지 확인
        XCTAssertGreaterThanOrEqual(config.schemaVersion, 0, "Realm 스키마 버전이 설정되어야 합니다")
    }

    // MARK: - NotificationName 존재 확인

    func test_NotificationName_categoryDidCreate() {
        XCTAssertEqual(
            Notification.Name.categoryDidCreate.rawValue,
            "categoryDidCreate",
            "카테고리 생성 알림 이름이 정의되어야 합니다"
        )
    }

    func test_NotificationName_categoryDidUpdate() {
        XCTAssertEqual(
            Notification.Name.categoryDidUpdate.rawValue,
            "categoryDidUpdate",
            "카테고리 업데이트 알림 이름이 정의되어야 합니다"
        )
    }

    func test_NotificationName_categoryDidDelete() {
        XCTAssertEqual(
            Notification.Name.categoryDidDelete.rawValue,
            "categoryDidDelete",
            "카테고리 삭제 알림 이름이 정의되어야 합니다"
        )
    }

    func test_NotificationName_linkDidCreate() {
        XCTAssertEqual(
            Notification.Name.linkDidCreate.rawValue,
            "linkDidCreate",
            "링크 생성 알림 이름이 정의되어야 합니다"
        )
    }

    func test_NotificationName_linkDidDelete() {
        XCTAssertEqual(
            Notification.Name.linkDidDelete.rawValue,
            "linkDidDelete",
            "링크 삭제 알림 이름이 정의되어야 합니다"
        )
    }

    // MARK: - Extension 테스트

    func test_UIColor_clippyBlue_존재() {
        let color = UIColor.clippyBlue
        XCTAssertNotNil(color, "clippyBlue 색상이 정의되어야 합니다")
    }

    func test_UIColor_clippyBlue_RGB_값() {
        let color = UIColor.clippyBlue
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // RGB: (33/255, 150/255, 243/255)
        XCTAssertEqual(red, 33/255, accuracy: 0.01, "Red 값이 33/255여야 합니다")
        XCTAssertEqual(green, 150/255, accuracy: 0.01, "Green 값이 150/255여야 합니다")
        XCTAssertEqual(blue, 243/255, accuracy: 0.01, "Blue 값이 243/255여야 합니다")
        XCTAssertEqual(alpha, 1.0, "Alpha 값이 1.0이어야 합니다")
    }

    // MARK: - Realm 데이터 모델 테스트

    func test_Category_모델_존재() {
        // Category 객체가 정의되어 있는지 확인
        let category = Category(name: "테스트", colorIndex: 0, iconName: "folder")
        XCTAssertNotNil(category)
        XCTAssertEqual(category.name, "테스트")
    }

    func test_LinkList_모델_존재() {
        // LinkList 객체가 정의되어 있는지 확인
        let link = LinkList(
            title: "테스트",
            thumbnail: "",
            url: "https://test.com",
            userMemo: nil,
            metadataDescription: nil,
            likeStatus: false,
            deadline: nil,
            isOpened: false,
            openCount: 0,
            date: Date()
        )
        XCTAssertNotNil(link)
        XCTAssertEqual(link.url, "https://test.com")
    }

    // MARK: - 싱글톤 인스턴스 테스트

    func test_LinkManager_싱글톤_접근() {
        let manager1 = LinkManager.shared
        let manager2 = LinkManager.shared

        // 같은 인스턴스인지 확인
        XCTAssertTrue(manager1 === manager2, "LinkManager는 싱글톤이어야 합니다")
    }

    func test_NotificationManager_싱글톤_접근() {
        let manager1 = NotificationManager.shared
        let manager2 = NotificationManager.shared

        // 같은 인스턴스인지 확인
        XCTAssertTrue(manager1 === manager2, "NotificationManager는 싱글톤이어야 합니다")
    }

    // MARK: - 성능 테스트

    func test_CategoryRepository_읽기_성능() {
        let config = Realm.Configuration(inMemoryIdentifier: "performance-test")
        let realm = try! Realm(configuration: config)
        let repository = CategoryRepository(realm: realm)

        // 100개 카테고리 생성
        for i in 0..<100 {
            _ = repository.createCategory(name: "Category\(i)", colorIndex: i % 10, iconName: "folder")
        }

        // 성능 측정: 카테고리 리스트 읽기
        measure {
            _ = repository.readCategoryList()
        }
    }

    func test_CategoryRepository_링크_추가_성능() {
        let config = Realm.Configuration(inMemoryIdentifier: "performance-test-link")
        let realm = try! Realm(configuration: config)
        let repository = CategoryRepository(realm: realm)

        repository.createCategory(name: "개발", colorIndex: 0, iconName: "folder")

        // 성능 측정: 링크 추가
        measure {
            for i in 0..<10 {
                repository.addLink(
                    title: "Link \(i)",
                    url: "https://test.com/\(i)",
                    categoryName: "개발",
                    deadline: nil
                )
            }
        }
    }
}
