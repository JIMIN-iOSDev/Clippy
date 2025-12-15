//
//  CategoryRepositoryTests.swift
//  ClippyTests
//
//  Created by Jimin on 12/15/25.
//

import XCTest
import RealmSwift
@testable import Clippy

final class CategoryRepositoryTests: XCTestCase {
    var repository: CategoryRepository!
    var realm: Realm!

    override func setUp() {
        super.setUp()

        // In-Memory Realm 설정 (테스트용 가짜 DB)
        let config = Realm.Configuration(
            inMemoryIdentifier: "test-realm-\(UUID().uuidString)"
        )
        realm = try! Realm(configuration: config)

        // 테스트용 Repository 생성 (DI)
        repository = CategoryRepository(realm: realm)
    }

    override func tearDown() {
        // 테스트 종료 시 정리
        realm = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - 카테고리 생성 테스트

    func test_카테고리_생성_성공() {
        // Given
        let categoryName = "개발"

        // When
        let result = repository.createCategory(
            name: categoryName,
            colorIndex: 1,
            iconName: "chevron.left.forwardslash.chevron.right"
        )

        // Then
        XCTAssertTrue(result, "카테고리 생성이 성공해야 합니다")

        let category = repository.readCategory(name: categoryName)
        XCTAssertNotNil(category, "생성된 카테고리를 조회할 수 있어야 합니다")
        XCTAssertEqual(category?.name, categoryName)
        XCTAssertEqual(category?.colorIndex, 1)
        XCTAssertEqual(category?.iconName, "chevron.left.forwardslash.chevron.right")
    }

    func test_중복_카테고리_생성_실패() {
        // Given: 먼저 "개발" 카테고리 생성
        repository.createCategory(name: "개발", colorIndex: 1, iconName: "folder")

        // When: 같은 이름으로 다시 생성 시도
        let result = repository.createCategory(name: "개발", colorIndex: 2, iconName: "star")

        // Then: 실패해야 함 (CategoryRepository.swift:25)
        XCTAssertFalse(result, "중복된 카테고리 생성은 실패해야 합니다")

        // 기존 카테고리는 그대로 유지
        let category = repository.readCategory(name: "개발")
        XCTAssertEqual(category?.colorIndex, 1, "기존 카테고리 정보는 변경되지 않아야 합니다")
    }

    func test_기본_일반_카테고리_생성() {
        // When
        repository.createDefaultCategory()

        // Then
        let generalCategory = repository.readCategory(name: "일반")
        XCTAssertNotNil(generalCategory, "일반 카테고리가 생성되어야 합니다")
        XCTAssertEqual(generalCategory?.name, "일반")
        XCTAssertEqual(generalCategory?.colorIndex, 0)
        XCTAssertEqual(generalCategory?.iconName, "folder")
    }

    func test_기본_일반_카테고리_중복_생성_방지() {
        // Given: 일반 카테고리가 이미 존재
        repository.createDefaultCategory()
        let initialCount = repository.readCategoryCount()

        // When: 다시 호출
        repository.createDefaultCategory()

        // Then: 중복 생성되지 않음
        let finalCount = repository.readCategoryCount()
        XCTAssertEqual(initialCount, finalCount, "일반 카테고리는 중복 생성되지 않아야 합니다")
    }

    // MARK: - 카테고리 조회 테스트

    func test_카테고리_조회_성공() {
        // Given
        repository.createCategory(name: "디자인", colorIndex: 2, iconName: "paintbrush")

        // When
        let category = repository.readCategory(name: "디자인")

        // Then
        XCTAssertNotNil(category)
        XCTAssertEqual(category?.name, "디자인")
    }

    func test_존재하지_않는_카테고리_조회_nil_반환() {
        // When
        let category = repository.readCategory(name: "존재하지않는카테고리")

        // Then
        XCTAssertNil(category, "존재하지 않는 카테고리는 nil을 반환해야 합니다")
    }

    func test_전체_카테고리_목록_조회() {
        // Given
        repository.createCategory(name: "개발", colorIndex: 1, iconName: "folder")
        repository.createCategory(name: "디자인", colorIndex: 2, iconName: "paintbrush")
        repository.createCategory(name: "공부", colorIndex: 3, iconName: "book")

        // When
        let categories = repository.readCategoryList()

        // Then
        XCTAssertEqual(categories.count, 3)

        let names = categories.map { $0.name }
        XCTAssertTrue(names.contains("개발"))
        XCTAssertTrue(names.contains("디자인"))
        XCTAssertTrue(names.contains("공부"))
    }

    func test_카테고리_개수_조회() {
        // Given
        repository.createCategory(name: "개발", colorIndex: 1, iconName: "folder")
        repository.createCategory(name: "디자인", colorIndex: 2, iconName: "paintbrush")

        // When
        let count = repository.readCategoryCount()

        // Then
        XCTAssertEqual(count, 2)
    }

    // MARK: - 카테고리 수정 테스트

    func test_카테고리_수정_성공() {
        // Given
        repository.createCategory(name: "개발", colorIndex: 1, iconName: "folder")

        // When
        let result = repository.updateCategory(
            oldName: "개발",
            newName: "프로그래밍",
            colorIndex: 3,
            iconName: "star"
        )

        // Then
        XCTAssertTrue(result, "카테고리 수정이 성공해야 합니다")

        let updatedCategory = repository.readCategory(name: "프로그래밍")
        XCTAssertNotNil(updatedCategory)
        XCTAssertEqual(updatedCategory?.colorIndex, 3)
        XCTAssertEqual(updatedCategory?.iconName, "star")

        // 기존 이름으로는 조회 안됨
        XCTAssertNil(repository.readCategory(name: "개발"))
    }

    func test_존재하지_않는_카테고리_수정_실패() {
        // When
        let result = repository.updateCategory(
            oldName: "존재하지않음",
            newName: "새이름",
            colorIndex: 1,
            iconName: "folder"
        )

        // Then
        XCTAssertFalse(result, "존재하지 않는 카테고리 수정은 실패해야 합니다")
    }

    func test_중복된_이름으로_카테고리_수정_실패() {
        // Given
        repository.createCategory(name: "개발", colorIndex: 1, iconName: "folder")
        repository.createCategory(name: "디자인", colorIndex: 2, iconName: "paintbrush")

        // When: "개발"을 이미 존재하는 "디자인"으로 변경 시도
        let result = repository.updateCategory(
            oldName: "개발",
            newName: "디자인",
            colorIndex: 3,
            iconName: "star"
        )

        // Then
        XCTAssertFalse(result, "중복된 이름으로 수정은 실패해야 합니다")

        // 원래 정보 유지
        let category = repository.readCategory(name: "개발")
        XCTAssertEqual(category?.colorIndex, 1)
    }

    // MARK: - 카테고리 삭제 테스트

    func test_카테고리_삭제_성공() {
        // Given
        repository.createCategory(name: "개발", colorIndex: 1, iconName: "folder")

        // When
        let result = repository.deleteCategory(name: "개발")

        // Then
        XCTAssertTrue(result, "카테고리 삭제가 성공해야 합니다")
        XCTAssertNil(repository.readCategory(name: "개발"))
    }

    func test_일반_카테고리_삭제_실패() {
        // Given
        repository.createDefaultCategory()

        // When
        let result = repository.deleteCategory(name: "일반")

        // Then (CategoryRepository.swift:276)
        XCTAssertFalse(result, "일반 카테고리는 삭제할 수 없어야 합니다")
        XCTAssertNotNil(repository.readCategory(name: "일반"), "일반 카테고리는 여전히 존재해야 합니다")
    }

    func test_카테고리_삭제_시_링크가_일반_카테고리로_이동() {
        // Given: 일반 카테고리와 개발 카테고리 생성
        repository.createDefaultCategory()
        repository.createCategory(name: "개발", colorIndex: 1, iconName: "folder")

        // 개발 카테고리에 링크 추가
        repository.addLink(
            title: "Swift 공식 문서",
            url: "https://swift.org",
            categoryName: "개발",
            deadline: nil
        )

        // When: 개발 카테고리 삭제
        let result = repository.deleteCategory(name: "개발")

        // Then
        XCTAssertTrue(result)
        XCTAssertNil(repository.readCategory(name: "개발"))

        // 링크는 일반 카테고리로 이동 (CategoryRepository.swift:287-295)
        let generalCategory = repository.readCategory(name: "일반")!
        XCTAssertEqual(generalCategory.category.count, 1)
        XCTAssertEqual(generalCategory.category.first?.url, "https://swift.org")
    }

    func test_존재하지_않는_카테고리_삭제_실패() {
        // When
        let result = repository.deleteCategory(name: "존재하지않음")

        // Then
        XCTAssertFalse(result)
    }
}
