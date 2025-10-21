//
//  CategoryRepositoryProtocol.swift
//  Clippy
//
//  Created by Jimin on 10/20/25.
//

import Foundation

/// CategoryRepository의 추상화 프로토콜
/// DIP(Dependency Inversion Principle)를 적용하여 구체적인 구현에 의존하지 않도록 함
protocol CategoryRepositoryProtocol {

    /// 카테고리 추가
    /// - Parameters:
    ///   - name: 카테고리명
    ///   - colorIndex: 색상 인덱스
    ///   - iconName: 아이콘명
    /// - Returns: 성공 여부
    func createCategory(name: String, colorIndex: Int, iconName: String) -> Bool

    /// 기본 카테고리 "일반" 생성
    func createDefaultCategory()

    /// 카테고리 조회
    /// - Parameter name: 카테고리명
    /// - Returns: 카테고리 객체
    func readCategory(name: String) -> Category?

    /// 링크 추가
    /// - Parameters:
    ///   - title: 링크 제목
    ///   - url: URL 문자열
    ///   - userMemo: 사용자가 직접 입력한 메모
    ///   - metadataDescription: 메타데이터에서 가져온 설명
    ///   - categoryName: 카테고리명
    ///   - deadline: 마감일
    ///   - likeStatus: 즐겨찾기 상태
    ///   - isOpened: 열람 상태
    ///   - openCount: 열람 횟수
    ///   - date: 생성일
    func addLink(title: String, url: String, userMemo: String?, metadataDescription: String?, categoryName: String, deadline: Date?, likeStatus: Bool, isOpened: Bool, openCount: Int, date: Date?)

    /// 링크 수정
    /// - Parameters:
    ///   - url: URL 문자열
    ///   - title: 새로운 제목
    ///   - userMemo: 새로운 사용자 메모
    ///   - metadataDescription: 새로운 메타데이터 설명
    ///   - categoryNames: 카테고리명 배열
    ///   - deadline: 마감일
    ///   - preserveLikeStatus: 즐겨찾기 상태 보존 여부
    ///   - preserveOpenedStatus: 열람 상태 보존 여부
    ///   - preserveOpenCount: 열람 횟수 보존 여부
    func updateLink(url: String, title: String, userMemo: String?, metadataDescription: String?, categoryNames: [String], deadline: Date?, preserveLikeStatus: Bool, preserveOpenedStatus: Bool, preserveOpenCount: Bool)

    /// 링크 삭제
    /// - Parameter url: URL 문자열
    func deleteLink(url: String)

    /// 전체 카테고리 목록 조회
    /// - Returns: 카테고리 배열
    func readCategoryList() -> [Category]

    /// 전체 카테고리 수 조회
    /// - Returns: 카테고리 개수
    func readCategoryCount() -> Int

    /// 특정 카테고리의 고유 링크 개수 계산
    /// - Parameter categoryName: 카테고리명
    /// - Returns: 고유 링크 개수
    func getUniqueLinkCount(for categoryName: String) -> Int

    /// 즐겨찾기 토글
    /// - Parameter url: URL 문자열
    func toggleLikeStatus(url: String)

    /// 열람 상태 토글
    /// - Parameter url: URL 문자열
    func toggleOpenedStatus(url: String)

    /// 카테고리 수정
    /// - Parameters:
    ///   - oldName: 기존 카테고리명
    ///   - newName: 새로운 카테고리명
    ///   - colorIndex: 색상 인덱스
    ///   - iconName: 아이콘명
    /// - Returns: 성공 여부
    func updateCategory(oldName: String, newName: String, colorIndex: Int, iconName: String) -> Bool

    /// URL로 링크 찾기
    /// - Parameter url: URL 문자열
    /// - Returns: LinkList 객체
    func getLinkByURL(_ url: String) -> LinkList?

    /// 링크의 제목, 사용자 메모, 메타데이터 설명을 업데이트
    /// - Parameters:
    ///   - url: URL 문자열
    ///   - title: 새로운 제목
    ///   - userMemo: 새로운 사용자 메모
    ///   - metadataDescription: 새로운 메타데이터 설명
    func updateLinkTitleAndDescription(url: String, title: String, userMemo: String?, metadataDescription: String?)

    /// 카테고리 삭제
    /// - Parameter name: 카테고리명
    /// - Returns: 성공 여부
    func deleteCategory(name: String) -> Bool
}
