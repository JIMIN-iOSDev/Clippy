//
//  CategoryRepository.swift
//  Clippy
//
//  Created by Jimin on 9/25/25.
//

import UIKit
import RealmSwift

final class CategoryRepository: CategoryRepositoryProtocol {
    
    let realm = try! Realm()
    
    /// 카테고리 추가
    /// - Parameter name: 카테고리명
    func createCategory(name: String, colorIndex: Int, iconName: String) -> Bool {
        
        if readCategory(name: name) != nil { return false } // 중복 카테고리 체크
        
        let category = Category(name: name, colorIndex: colorIndex, iconName: iconName)
        
        do {
            try realm.write {
                realm.add(category)
            }
            return true
        } catch {
            print("카테고리 만들기 실패")
            return false
        }
    }
    
    /// 기본 카테고리 "일반" 제공
    func createDefaultCategory() {
        print(realm.configuration.fileURL)
        if readCategory(name: "일반") == nil {
            createCategory(name: "일반", colorIndex: 0, iconName: "folder")
        }
    }
    
    func readCategory(name: String) -> Category? {
        let category = realm.objects(Category.self).where {
            $0.name == name
        }.first
        
        return category
    }
    
    func addLink(title: String, url: String, userMemo: String? = nil, metadataDescription: String? = nil, categoryName: String, deadline: Date?, likeStatus: Bool = false, isOpened: Bool = false, openCount: Int = 0, date: Date? = nil) {
        guard let category = readCategory(name: categoryName) else {
            print("\(categoryName) 없음")
            return
        }

        // 이미 해당 카테고리에 같은 URL의 링크가 있는지 확인
        let existingLink = category.category.first { $0.url == url }
        if existingLink != nil {
            print("이미 존재하는 링크 \(url)")
            return
        }

        // 다른 카테고리에 같은 URL의 링크가 있는지 확인
        let existingLinkInOtherCategory = getLinkByURL(url)

        let link: LinkList
        if let existingLink = existingLinkInOtherCategory {
            // 기존 링크가 있으면 그 링크를 재사용
            link = existingLink
        } else {
            // 새로운 링크 생성
            link = LinkList(title: title, thumbnail: "", url: url, userMemo: userMemo, metadataDescription: metadataDescription, likeStatus: likeStatus, deadline: deadline, isOpened: isOpened, openCount: openCount, date: date)
        }

        do {
            try realm.write {
                category.category.append(link)
            }
        } catch {
            print("링크 저장 실패")
        }
    }
    
    func updateLink(url: String, title: String, userMemo: String? = nil, metadataDescription: String? = nil, categoryNames: [String], deadline: Date?, preserveLikeStatus: Bool = false, preserveOpenedStatus: Bool = true, preserveOpenCount: Bool = true) {
        let categories = realm.objects(Category.self)

        // 기존 링크의 상태 보존 (즐겨찾기, 열람 상태, 열람 횟수, 생성일)
        var preservedLikeStatus = false
        var preservedIsOpened = false
        var preservedOpenCount = 0
        var preservedDate: Date?

        // 기존 링크 찾기 (생성일은 항상 보존)
        for category in categories {
            if let existingLink = category.category.first(where: { $0.url == url }) {
                preservedDate = existingLink.date
                if preserveLikeStatus {
                    preservedLikeStatus = existingLink.likeStatus
                }
                if preserveOpenedStatus {
                    preservedIsOpened = existingLink.isOpened
                }
                if preserveOpenCount {
                    preservedOpenCount = existingLink.openCount
                }
                break
            }
        }

        // 기존 링크 삭제
        deleteLink(url: url)

        // 새 카테고리에 링크 추가 (모든 상태 보존)
        categoryNames.forEach { categoryName in
            addLink(title: title, url: url, userMemo: userMemo, metadataDescription: metadataDescription, categoryName: categoryName, deadline: deadline, likeStatus: preservedLikeStatus, isOpened: preservedIsOpened, openCount: preservedOpenCount, date: preservedDate)
        }
    }
    
    func deleteLink(url: String) {
        let categories = realm.objects(Category.self)
        
        do {
            try realm.write {
                for category in categories {
                    if let link = category.category.first(where: { $0.url == url }) {
                        // List에서 삭제
                        if let index = category.category.index(of: link) {
                            category.category.remove(at: index)
                        }
                        // 객체 자체도 삭제
                        realm.delete(link)
                    }
                }
            }
        } catch {
            print("링크 삭제 실패: \(error)")
        }
    }
    
    func readCategoryList() -> [Category] {
        return Array(realm.objects(Category.self))
    }
    
    /// 통계에서 전체 카테고리 수 보여줄 때 사용
    /// - Returns: 전체 카테고리 수
    func readCategoryCount() -> Int {
        return realm.objects(Category.self).count
    }
    
    /// 특정 카테고리의 고유 링크 개수 계산 (중복 제거)
    /// - Parameter categoryName: 카테고리명
    /// - Returns: 해당 카테고리의 고유 링크 개수
    func getUniqueLinkCount(for categoryName: String) -> Int {
        guard let category = readCategory(name: categoryName) else { return 0 }
        
        // URL 기준으로 중복 제거하여 고유 링크 개수 계산
        let uniqueURLs = Set(category.category.map { $0.url })
        return uniqueURLs.count
    }
    
    // 즐겨찾기 토글
    func toggleLikeStatus(url: String) {
        let categories = realm.objects(Category.self)
        
        do {
            try realm.write {
                for category in categories {
                    if let link = category.category.first(where: { $0.url == url }) {
                        link.likeStatus.toggle()
                    }
                }
            }
        } catch {
            print("즐겨찾기 토글 실패: \(error)")
        }
    }
    
    // 열람 상태 토글
    func toggleOpenedStatus(url: String) {
        let categories = realm.objects(Category.self)
        
        do {
            try realm.write {
                for category in categories {
                    if let link = category.category.first(where: { $0.url == url }) {
                        link.isOpened.toggle()
                    }
                }
            }
        } catch {
            print("열람 상태 토글 실패: \(error)")
        }
    }
    
    /// 카테고리 수정
    /// - Parameters:
    ///   - oldName: 기존 카테고리명
    ///   - newName: 새로운 카테고리명
    ///   - colorIndex: 색상 인덱스
    ///   - iconName: 아이콘명
    func updateCategory(oldName: String, newName: String, colorIndex: Int, iconName: String) -> Bool {
        guard let category = readCategory(name: oldName) else {
            print("카테고리 없음: \(oldName)")
            return false
        }
        
        // 새 이름이 이미 존재하는지 확인 (자기 자신 제외)
        if oldName != newName && readCategory(name: newName) != nil {
            print("이미 존재하는 카테고리명: \(newName)")
            return false
        }
        
        do {
            try realm.write {
                category.name = newName
                category.colorIndex = colorIndex
                category.iconName = iconName
                category.updatedAt = Date()
            }
            print("카테고리 수정 성공: \(oldName) -> \(newName)")
            return true
        } catch {
            print("카테고리 수정 실패: \(error)")
            return false
        }
    }
    
    /// URL로 링크 찾기
    /// - Parameter url: 찾을 링크의 URL
    /// - Returns: 해당 URL의 LinkList 객체
    func getLinkByURL(_ url: String) -> LinkList? {
        let categories = realm.objects(Category.self)

        for category in categories {
            if let link = category.category.first(where: { $0.url == url }) {
                return link
            }
        }

        return nil
    }

    /// 링크의 제목, 사용자 메모, 메타데이터 설명을 업데이트 (다른 속성은 유지)
    /// - Parameters:
    ///   - url: 업데이트할 링크의 URL
    ///   - title: 새로운 제목
    ///   - userMemo: 새로운 사용자 메모
    ///   - metadataDescription: 새로운 메타데이터 설명
    func updateLinkTitleAndDescription(url: String, title: String, userMemo: String?, metadataDescription: String?) {
        guard let link = getLinkByURL(url) else {
            print("링크 없음: \(url)")
            return
        }

        do {
            try realm.write {
                link.title = title
                link.userMemo = userMemo
                link.metadataDescription = metadataDescription
            }
            print("링크 제목/메모/설명 업데이트 성공: \(url)")
        } catch {
            print("링크 업데이트 실패: \(error)")
        }
    }
    
    /// 카테고리 삭제 (해당 카테고리의 링크들을 일반 카테고리로 이동)
    /// - Parameter name: 삭제할 카테고리명
    func deleteCategory(name: String) -> Bool {
        // "일반" 카테고리는 삭제 불가
        if name == "일반" {
            print("일반 카테고리는 삭제할 수 없습니다")
            return false
        }
        
        guard let category = readCategory(name: name) else {
            print("카테고리 없음: \(name)")
            return false
        }
        
        do {
            try realm.write {
                // 해당 카테고리의 모든 링크를 일반 카테고리로 이동
                if let generalCategory = readCategory(name: "일반") {
                    let linksToMove = Array(category.category)
                    linksToMove.forEach { link in
                        // 일반 카테고리에 이미 같은 URL의 링크가 있는지 확인
                        let existingLink = generalCategory.category.first { $0.url == link.url }
                        if existingLink == nil {
                            generalCategory.category.append(link)
                        }
                    }
                }
                
                // 카테고리 삭제
                realm.delete(category)
            }
            print("카테고리 삭제 성공: \(name)")
            return true
        } catch {
            print("카테고리 삭제 실패: \(error)")
            return false
        }
    }
}
