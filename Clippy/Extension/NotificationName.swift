//
//  NotificationName.swift
//  Clippy
//
//  Created by Jimin on 9/29/25.
//

import Foundation

extension Notification.Name {
    static let categoryDidCreate = Notification.Name("categoryDidCreate")
    static let categoryDidUpdate = Notification.Name("categoryDidUpdate")
    static let categoryDidDelete = Notification.Name("categoryDidDelete")
    static let linkDidCreate = Notification.Name("linkDidCreate")
}
