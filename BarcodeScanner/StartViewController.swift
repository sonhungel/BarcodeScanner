//
//  StartViewController.swift
//  BarcodeScanner
//
//  Created by Trần Sơn on 25/12/2020.
//

import UIKit
import SnapKit

class StartViewController: UIViewController {
    
    private let scanbutton:UIButton = {
        let btn = UIButton()
        btn.setTitle("SCAN", for: .normal)
        btn.setTitleColor(.blue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 40, weight: .thin)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Start"
        scanbutton.addTarget(self, action: #selector(scanClicked), for: .touchUpInside)

        // Do any additional setup after loading the view.
        view.addSubview(scanbutton)
    }
    override func viewDidLayoutSubviews() {
        scanbutton.snp.makeConstraints { (make) ->Void in
            make.center.equalTo(view.snp.center)
            make.size.equalTo(CGSize(width: 175, height: 50))
        }
    }
    
    @objc func scanClicked(){
        let scannerView = ScannerViewController()
        
        self.navigationController?.pushViewController(scannerView, animated: true)
  //      scannerView.title = "Scanner"

        navigationController?.isNavigationBarHidden = true
    }

}
