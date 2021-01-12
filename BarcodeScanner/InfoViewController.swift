//
//  InforViewController.swift
//  BarcodeScanner
//
//  Created by Trần Sơn on 10/12/2020.
//

import UIKit
import SnapKit


class InfoViewController: UIViewController {
    
    private let imageViewProduct:UIImageView = {
        let imageView = UIImageView()
        //imageView.backgroundColor = .blue
        return imageView
    }()
    
    private let productPriceLabel:UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = UIColor(red: 98/255, green: 58/255, blue: 154/255, alpha: 0.9)
        label.textAlignment = .center
        label.font = UIFont(name: "Geeza Pro", size: 16)
        return label
    }()
    
    private let productNameLabel:UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = UIColor(red: 98/255, green: 58/255, blue: 154/255, alpha: 0.9)
        label.layer.cornerRadius = 30
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.font = UIFont(name: "Geeza Pro", size: 16)
        return label
    }()
    
    private let productBarcodeLabel:UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = UIColor(red: 98/255, green: 58/255, blue: 154/255, alpha: 0.9)
        label.textAlignment = .center
        label.font = UIFont(name: "Geeza Pro", size: 16)
        return label
    }()
    
    private let btnDone:UIButton = {
        let button=UIButton()
        button.setTitle("Done", for: .normal)
        button.backgroundColor = UIColor(red: 98/255, green: 58/255, blue: 154/255, alpha: 0.9)
        button.layer.cornerRadius = 26
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.layer.masksToBounds = true
        return button
    }()
    
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
        self.view.backgroundColor = .white

        // Do any additional setup after loading the view.
        let url = URL(string:productInfor.imageURL)!
        downloadImage(from: url)
        productNameLabel.text = "Tên sản phẩm: " + productInfor.name
        productPriceLabel.text = "Giá: " + String(productInfor.price) + "K VND"
        productBarcodeLabel.text = "Barcode: " + String(productInfor.barcode)
        
        view.addSubview(imageViewProduct)
        view.addSubview(productPriceLabel)
        view.addSubview(productNameLabel)
        view.addSubview(productBarcodeLabel)
        btnDone.addTarget(self, action: #selector(btnDoneAction), for: .touchUpInside)
        view.addSubview(btnDone)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageViewProduct.snp.makeConstraints { (make)->Void in
            make.top.equalTo(view).offset(35)
            //make.size.equalTo(view.frame.width/2)
            make.leading.equalTo(view).offset(25)
            make.trailing.equalTo(view).offset(-25)
            make.bottom.equalTo(view).offset(-view.frame.height/3)
        }
        productNameLabel.snp.makeConstraints { (make)->Void in
            make.top.equalTo(imageViewProduct.snp.bottom).offset(10)
            make.size.equalTo(CGSize(width: 300, height: 70))
            make.centerX.equalTo(view.snp.centerX)
        }
        productPriceLabel.snp.makeConstraints { (make)->Void in
            make.top.equalTo(productNameLabel.snp.bottom).offset(10)
            make.leading.equalTo(view.snp.leading).offset(5)
            make.trailing.equalTo(view.snp.centerX).offset(-5)
            make.bottom.equalTo(btnDone.snp.top).offset(-10)
        }
        productBarcodeLabel.snp.makeConstraints { (make)->Void in
            make.top.equalTo(productNameLabel.snp.bottom).offset(10)
            make.leading.equalTo(view.snp.centerX).offset(5)
            make.trailing.equalTo(view.snp.trailing).offset(-5)
            make.bottom.equalTo(btnDone.snp.top).offset(-10)
        }
        btnDone.snp.makeConstraints { (make)->Void in
            make.size.equalTo(CGSize(width: 100, height: 60))
            make.centerX.equalTo(view.snp.centerX)
            make.bottom.equalTo(view).offset(-15)
        }
        
    }
    @objc private func btnDoneAction(){
        navigationController?.popViewController(animated: true)
        print("Touch Up the button DONE")
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    func downloadImage(from url: URL) {
        print("Download Started")
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() { [weak self] in
                self?.imageViewProduct.image = UIImage(data: data)
            }
        }
    }
}

