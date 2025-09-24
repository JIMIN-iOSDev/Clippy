//
//  UIButton+Extension.swift
//  Clippy
//
//  Created by Jimin on 9/24/25.
//

import UIKit
import RxSwift
import RxCocoa

enum SortType: String, CaseIterable {
    case name = "이름순"
    case createdDate = "생성일순"
    case modifiedDate = "수정일순"
    case userCustom = "사용자설정순"
}

extension UIButton {
    
    static func makeSortToggleButton() -> UIButton {
        let button = UIButton(type: .system)
        
        // 기본 설정
        button.setTitle(SortType.name.rawValue, for: .normal)
        button.setTitleColor(.black, for: .normal)
        
        // 이미지 크기 조정
        let downImage = UIImage(systemName: "chevron.down")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        )
        let upImage = UIImage(systemName: "chevron.up")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        )
        
        button.setImage(downImage, for: .normal)
        button.setImage(upImage, for: .selected)
        button.tintColor = .black
        
        // 이미지를 왼쪽에 배치
        button.semanticContentAttribute = .forceLeftToRight
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        
        return button
    }
}
