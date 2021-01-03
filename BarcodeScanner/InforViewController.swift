//
//  InforViewController.swift
//  BarcodeScanner
//
//  Created by Trần Sơn on 10/12/2020.
//

import UIKit
import SnapKit

class InforViewController: UIViewController {
    
    var productInfor:Product
    
    
    init(product: Product) {
        self.productInfor = product
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        // Do any additional setup after loading the view.
    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//    }

}
