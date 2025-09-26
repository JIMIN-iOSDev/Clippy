//
//  DateFormatter.swift
//  Clippy
//
//  Created by Jimin on 9/26/25.
//

import Foundation

extension DateFormatter {
    static let displayFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd."
        return formatter
    }()
}
