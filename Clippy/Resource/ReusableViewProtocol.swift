//
//  ReusableViewProtocol.swift
//  Clippy
//
//  Created by Jimin on 9/26/25.
//

import UIKit

protocol ReusableViewProtocol {
    static var identifier: String { get }
}

extension UITableViewCell: ReusableViewProtocol {
    static var identifier: String {
        return String(describing: self)
    }
}

