//
//  RealmTable.swift
//  Clippy
//
//  Created by 서지민 on 9/23/25.
//

import Foundation
import RealmSwift

class Category: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String // 카테고리명
    @Persisted var colorIndex: Int  // 색상
    @Persisted var iconName: String // 아이콘명
    @Persisted var memo: String? // 설명
    @Persisted var createdAt: Date  // 카테고리 생성일
    @Persisted var updatedAt: Date  // 카테고리 수정일
    @Persisted var category: List<LinkList> // 하나의 카테고리가 여러 링크를 가짐
    
    convenience init(name: String, colorIndex: Int, iconName: String, memo: String? = nil) {
        self.init()
        self.name = name
        self.colorIndex = colorIndex
        self.iconName = iconName
        self.memo = memo
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

class LinkList: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String    // 링크 제목
    @Persisted var thumbnail: String    // 링크 이미지
    @Persisted var url: String  // 링크 URL
    @Persisted var memo: String?    // 메모
    @Persisted var likeStatus: Bool // 즐겨찾기
    @Persisted var date: Date   // 링크 생성일
    @Persisted var deadline: Date?  // 사용자가 설정한 마감일
    @Persisted var isOpened: Bool   // 링크 열람 여부
    @Persisted var openCount: Int   // 링크별로 열린 총 횟수
    
    @Persisted(originProperty: "category") var parentCategory: LinkingObjects<Category>   // 이 링크가 어떤 카테고리에 속하는지 역참조
    
    convenience init(title: String, url: String, memo: String? = nil, likeStatus: Bool = false, deadline: Date? = nil, isOpened: Bool = false, openCount: Int = 0) {
        self.init()
        self.title = title
        self.url = url
        self.memo = memo
        self.likeStatus = likeStatus
        self.date = Date()
        self.openCount = openCount
    }
}
