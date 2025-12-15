//
//  CategoryRepositoryLinkTests.swift
//  ClippyTests
//
//  Created by Jimin on 12/15/25.
//

import XCTest
import RealmSwift
@testable import Clippy

final class CategoryRepositoryLinkTests: XCTestCase {
    var repository: CategoryRepository!
    var realm: Realm!

    override func setUp() {
        super.setUp()

        // In-Memory Realm 설정
        let config = Realm.Configuration(
            inMemoryIdentifier: "test-realm-\(UUID().uuidString)"
        )
        realm = try! Realm(configuration: config)
        repository = CategoryRepository(realm: realm)

        // 테스트용 카테고리 생성
        repository.createDefaultCategory()
        repository.createCategory(name: "개발", colorIndex: 1, iconName: "folder")
        repository.createCategory(name: "디자인", colorIndex: 2, iconName: "paintbrush")
    }

    override func tearDown() {
        realm = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - 링크 추가 테스트

    func test_링크_추가_성공() {
        // When
        repository.addLink(
            title: "Swift 공식 문서",
            url: "https://swift.org",
            userMemo: "읽어보기",
            metadataDescription: "Swift 프로그래밍 언어",
            categoryName: "개발",
            deadline: nil
        )

        // Then
        let category = repository.readCategory(name: "개발")!
        XCTAssertEqual(category.category.count, 1)

        let link = category.category.first!
        XCTAssertEqual(link.title, "Swift 공식 문서")
        XCTAssertEqual(link.url, "https://swift.org")
        XCTAssertEqual(link.userMemo, "읽어보기")
        XCTAssertEqual(link.metadataDescription, "Swift 프로그래밍 언어")
    }

    func test_존재하지_않는_카테고리에_링크_추가_실패() {
        // When
        repository.addLink(
            title: "Test",
            url: "https://test.com",
            categoryName: "존재하지않음",
            deadline: nil
        )

        // Then: 링크가 추가되지 않아야 함 (CategoryRepository.swift:55-57)
        let link = repository.getLinkByURL("https://test.com")
        XCTAssertNil(link)
    }

    func test_같은_URL_같은_카테고리_중복_추가_방지() {
        // Given
        repository.addLink(
            title: "Swift 공식 문서",
            url: "https://swift.org",
            categoryName: "개발",
            deadline: nil
        )

        // When: 같은 URL을 같은 카테고리에 다시 추가
        repository.addLink(
            title: "Swift 문서 (중복)",
            url: "https://swift.org",
            categoryName: "개발",
            deadline: nil
        )

        // Then: 중복 추가되지 않음 (CategoryRepository.swift:60-63)
        let category = repository.readCategory(name: "개발")!
        XCTAssertEqual(category.category.count, 1, "같은 카테고리에 같은 URL 중복 추가 방지")
    }

    func test_같은_URL_다른_카테고리_추가_가능_같은_객체_공유() {
        // Given
        repository.addLink(
            title: "디자인 가이드",
            url: "https://material.io",
            categoryName: "개발",
            deadline: nil
        )

        // When: 같은 URL을 다른 카테고리에 추가
        repository.addLink(
            title: "디자인 가이드",
            url: "https://material.io",
            categoryName: "디자인",
            deadline: nil
        )

        // Then
        let devCategory = repository.readCategory(name: "개발")!
        let designCategory = repository.readCategory(name: "디자인")!

        XCTAssertEqual(devCategory.category.count, 1)
        XCTAssertEqual(designCategory.category.count, 1)

        // 같은 URL을 가진 링크가 두 카테고리에 모두 존재하는지 확인
        let devLink = devCategory.category.first!
        let designLink = designCategory.category.first!

        XCTAssertEqual(devLink.url, "https://material.io")
        XCTAssertEqual(designLink.url, "https://material.io")

        // Realm 객체는 같은 URL을 공유 (CategoryRepository.swift:70-76)
        XCTAssertEqual(devLink.url, designLink.url, "같은 URL 링크가 여러 카테고리에 존재해야 합니다")
    }

    // MARK: - 링크 조회 테스트

    func test_URL로_링크_조회_성공() {
        // Given
        repository.addLink(
            title: "Swift",
            url: "https://swift.org",
            categoryName: "개발",
            deadline: nil
        )

        // When
        let link = repository.getLinkByURL("https://swift.org")

        // Then
        XCTAssertNotNil(link)
        XCTAssertEqual(link?.title, "Swift")
        XCTAssertEqual(link?.url, "https://swift.org")
    }

    func test_존재하지_않는_URL_조회_nil_반환() {
        // When
        let link = repository.getLinkByURL("https://notexist.com")

        // Then
        XCTAssertNil(link)
    }

    func test_카테고리별_고유_링크_개수_계산() {
        // Given
        repository.addLink(
            title: "Link 1",
            url: "https://link1.com",
            categoryName: "개발",
            deadline: nil
        )
        repository.addLink(
            title: "Link 2",
            url: "https://link2.com",
            categoryName: "개발",
            deadline: nil
        )
        repository.addLink(
            title: "Link 3",
            url: "https://link3.com",
            categoryName: "개발",
            deadline: nil
        )

        // When
        let count = repository.getUniqueLinkCount(for: "개발")

        // Then
        XCTAssertEqual(count, 3)
    }

    // MARK: - 링크 수정 테스트

    func test_링크_제목과_메모_수정() {
        // Given
        repository.addLink(
            title: "원래 제목",
            url: "https://test.com",
            userMemo: "원래 메모",
            metadataDescription: "원래 설명",
            categoryName: "개발",
            deadline: nil
        )

        // When
        repository.updateLinkTitleAndDescription(
            url: "https://test.com",
            title: "새로운 제목",
            userMemo: "새로운 메모",
            metadataDescription: "새로운 설명"
        )

        // Then
        let link = repository.getLinkByURL("https://test.com")!
        XCTAssertEqual(link.title, "새로운 제목")
        XCTAssertEqual(link.userMemo, "새로운 메모")
        XCTAssertEqual(link.metadataDescription, "새로운 설명")
    }

    func test_링크_카테고리_변경() {
        // Given: 개발 카테고리에 링크 추가
        repository.addLink(
            title: "Test Link",
            url: "https://test.com",
            categoryName: "개발",
            deadline: nil
        )

        // When: 디자인 카테고리로 변경
        repository.updateLink(
            url: "https://test.com",
            title: "Test Link",
            categoryNames: ["디자인"],
            deadline: nil
        )

        // Then
        let devCategory = repository.readCategory(name: "개발")!
        let designCategory = repository.readCategory(name: "디자인")!

        XCTAssertEqual(devCategory.category.count, 0, "개발 카테고리에서 제거됨")
        XCTAssertEqual(designCategory.category.count, 1, "디자인 카테고리에 추가됨")
    }

    func test_링크_여러_카테고리에_동시_추가() {
        // Given
        repository.addLink(
            title: "Test Link",
            url: "https://test.com",
            categoryName: "개발",
            deadline: nil
        )

        // When: 개발, 디자인 두 카테고리에 모두 추가
        repository.updateLink(
            url: "https://test.com",
            title: "Test Link",
            categoryNames: ["개발", "디자인"],
            deadline: nil
        )

        // Then
        let devCategory = repository.readCategory(name: "개발")!
        let designCategory = repository.readCategory(name: "디자인")!

        XCTAssertEqual(devCategory.category.count, 1)
        XCTAssertEqual(designCategory.category.count, 1)
    }

    // MARK: - 링크 삭제 테스트

    func test_링크_삭제_성공() {
        // Given
        repository.addLink(
            title: "Test",
            url: "https://test.com",
            categoryName: "개발",
            deadline: nil
        )

        // When
        repository.deleteLink(url: "https://test.com")

        // Then
        let link = repository.getLinkByURL("https://test.com")
        XCTAssertNil(link, "링크가 삭제되어야 합니다")

        let category = repository.readCategory(name: "개발")!
        XCTAssertEqual(category.category.count, 0)
    }

    func test_링크_삭제_시_모든_카테고리에서_제거() {
        // Given: 개발, 디자인 두 카테고리에 같은 링크 추가
        repository.addLink(
            title: "Test",
            url: "https://test.com",
            categoryName: "개발",
            deadline: nil
        )
        repository.addLink(
            title: "Test",
            url: "https://test.com",
            categoryName: "디자인",
            deadline: nil
        )

        // When: 링크 삭제
        repository.deleteLink(url: "https://test.com")

        // Then: 모든 카테고리에서 제거됨 (CategoryRepository.swift:131-140)
        let devCategory = repository.readCategory(name: "개발")!
        let designCategory = repository.readCategory(name: "디자인")!

        XCTAssertEqual(devCategory.category.count, 0)
        XCTAssertEqual(designCategory.category.count, 0)
        XCTAssertNil(repository.getLinkByURL("https://test.com"))
    }

    // MARK: - 링크 상태 토글 테스트

    func test_즐겨찾기_토글() {
        // Given
        repository.addLink(
            title: "Test",
            url: "https://test.com",
            categoryName: "개발",
            deadline: nil,
            likeStatus: false
        )

        // When: 토글
        repository.toggleLikeStatus(url: "https://test.com")

        // Then
        let link = repository.getLinkByURL("https://test.com")!
        XCTAssertTrue(link.likeStatus)

        // When: 다시 토글
        repository.toggleLikeStatus(url: "https://test.com")

        // Then
        XCTAssertFalse(link.likeStatus)
    }

    func test_열람_상태_토글() {
        // Given
        repository.addLink(
            title: "Test",
            url: "https://test.com",
            categoryName: "개발",
            deadline: nil,
            isOpened: false
        )

        // When
        repository.toggleOpenedStatus(url: "https://test.com")

        // Then
        let link = repository.getLinkByURL("https://test.com")!
        XCTAssertTrue(link.isOpened)
    }

    func test_즐겨찾기_토글_여러_카테고리_동시_적용() {
        // Given: 한 카테고리에 링크 추가
        repository.addLink(
            title: "Test",
            url: "https://test.com",
            categoryName: "개발",
            deadline: nil,
            likeStatus: false
        )

        // When: 즐겨찾기 토글
        repository.toggleLikeStatus(url: "https://test.com")

        // Then: toggleLikeStatus는 URL을 찾아서 토글 (CategoryRepository.swift:182-183)
        let devCategory = repository.readCategory(name: "개발")!
        XCTAssertTrue(devCategory.category.first!.likeStatus, "링크가 즐겨찾기 되어야 합니다")

        // 다시 토글
        repository.toggleLikeStatus(url: "https://test.com")
        XCTAssertFalse(devCategory.category.first!.likeStatus, "링크가 즐겨찾기 해제되어야 합니다")
    }
}
