//
//  CategoryColor.swift
//  Clippy
//
//  Created by Jimin on 9/29/25.
//

import UIKit

enum CategoryColor {    
    static let colors: [UIColor] = [.systemBlue, .systemPurple, .systemGreen, .systemOrange, .systemRed, .systemPink, .systemTeal, .systemYellow]
    
    static func color(index: Int) -> UIColor {
        guard index >= 0 && index < colors.count else {
            return .systemBlue
        }
        return colors[index]
    }
}
