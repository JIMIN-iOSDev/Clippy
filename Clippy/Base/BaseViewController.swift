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
        bind()
    }
    
    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() {
        view.backgroundColor = .white
    }
    func bind() { }
    
}
