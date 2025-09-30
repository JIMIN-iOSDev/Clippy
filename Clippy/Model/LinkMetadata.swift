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
    let description: String?
    let thumbnailImage: UIImage?
    let categories: [(name: String, colorIndex: Int)]?
    let dueDate: Date?  
    let createdAt: Date
    let isLiked: Bool
    
    init(url: URL, title: String, description: String? = nil, thumbnailImage: UIImage? = nil, categories: [(name: String, colorIndex: Int)]? = nil, dueDate: Date? = nil, createdAt: Date = Date(), isLiked: Bool = false) {
        self.url = url
        self.title = title.isEmpty ? url.absoluteString : title
        self.description = description
        self.thumbnailImage = thumbnailImage
        self.categories = categories
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.isLiked = isLiked
    }
}
