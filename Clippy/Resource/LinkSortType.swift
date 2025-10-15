//
//  LinkSortType.swift
//  Clippy
//
//  Created by Jimin on 9/27/25.
//

import Foundation

enum LinkSortType: String, CaseIterable {
    case latest = "최신순"
    case title = "제목순"
    case deadline = "마감일순"
    case read = "열람"
    case unread = "미열람"
    
    var displayName: String {
        return self.rawValue
    }
    
    var isFiltering: Bool {
        return self == .read || self == .unread
    }
}
