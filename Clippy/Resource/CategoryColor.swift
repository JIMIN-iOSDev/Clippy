//
//  CategoryColor.swift
//  Clippy
//
//  Created by Jimin on 9/29/25.
//

import UIKit

enum CategoryColor {    // 카테고리 생성할 때 사용하는 색상
    static let colors: [UIColor] = [.clippyBlue, .systemPurple, .systemGreen, .systemOrange, .systemRed, .systemPink, .systemTeal, .systemYellow]
    
    static func color(index: Int) -> UIColor {
        guard index >= 0 && index < colors.count else {
            return .clippyBlue
        }
        return colors[index]
    }
}
