//
//  CategoryRepository.swift
//  Clippy
//
//  Created by Jimin on 9/25/25.
//

import Foundation
import RealmSwift

final class CategoryRepository {
    
    let realm = try! Realm()
    
    /// 카테고리 추가
    /// - Parameter name: 카테고리명
    func createCategory(name: String, colorIndex: Int, iconName: String, memo: String? = nil) {
        let category = Category(name: name, colorIndex: colorIndex, iconName: iconName, memo: memo)
        
        do {
            try realm.write {
                realm.add(category)
            }
        } catch {
            print("카테고리 만들기 실패")
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
    
    func addLink(title: String, url: String, description: String? = nil, categoryName: String, deadline: Date?) {
        guard let category = readCategory(name: categoryName) else {
            print("\(categoryName) 없음")
            return
        }
        
        let link = LinkList(title: title, url: url, memo: description, likeStatus: false, deadline: deadline, isOpened: false, openCount: 0)
        
        do {
            try realm.write {
                category.category.append(link)
            }
        } catch {
            print("링크 저장 실패")
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
}
