//
//  BaseViewController.swift
//  Clippy
//
//  Created by Jimin on 9/24/25.
//

import UIKit

class BaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureLayout()
        configureView()
        configureBind()
    }
    
    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() {
        view.backgroundColor = .white
    }
    func configureBind() { }
    
}
