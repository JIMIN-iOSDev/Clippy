//
//  LinkMetadata.swift
//  Clippy
//
//  Created by Jimin on 9/27/25.
//

import UIKit

struct LinkMetadata {
    let url: URL
    let title: String
    let userMemo: String?           // 사용자가 직접 입력한 메모
    let metadataDescription: String? // 메타데이터에서 가져온 설명
    let thumbnailImage: UIImage?
    let categories: [(name: String, colorIndex: Int)]?
    let dueDate: Date?
    let createdAt: Date
    let isLiked: Bool
    let isOpened: Bool

    init(url: URL, title: String, userMemo: String? = nil, metadataDescription: String? = nil, thumbnailImage: UIImage? = nil, categories: [(name: String, colorIndex: Int)]? = nil, dueDate: Date? = nil, createdAt: Date = Date(), isLiked: Bool = false, isOpened: Bool = false) {
        self.url = url
        self.title = title.isEmpty ? url.absoluteString : title
        self.userMemo = userMemo
        self.metadataDescription = metadataDescription
        self.thumbnailImage = thumbnailImage
        self.categories = categories
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.isLiked = isLiked
        self.isOpened = isOpened
    }
}
