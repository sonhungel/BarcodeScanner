//
//  ScannerViewController.swift
//  BarcodeScanner
//
//  Created by Trần Sơn on 09/12/2020.
//

import UIKit
import AVFoundation
import Vision
import SnapKit
import JGProgressHUD

import Foundation

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

//    MARK: Properties Square
    
    private lazy var focusView:UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "im_frame")
        imageView.isUserInteractionEnabled = false
        imageView.backgroundColor = .clear
        return imageView
    }()

    fileprivate lazy var colorDefault: UIColor = {
        return UIColor(white: 0 , alpha: 0.5)
    }()
    
    private struct Constants{
        static let FOCUS_PADDING:CGFloat = 7
        static let FOCUS_BORDER: CGFloat = 2
        static let TITLE_HEIGHT: CGFloat = 50
    }
    
    private lazy var topView: UIView = {
        return self.createViewElement()
    }()
    private lazy var leftView: UIView = {
        return self.createViewElement()
    }()
    private lazy var rightView: UIView = {
        return self.createViewElement()
    }()
    private lazy var bottomView: UIView = {
        return self.createViewElement()
    }()
    
    fileprivate var focusFrame: CGRect {
        var barHeight: CGFloat = 0
        if let naviBar = self.navigationController?.navigationBar {
            barHeight = naviBar.frame.origin.y + naviBar.frame.height
        }
        
        let screenWidth = self.view.bounds.size.width
        let screenHeight = self.view.bounds.size.height - barHeight
        
        let squareWidth = screenWidth - Constants.FOCUS_PADDING * 2
        let squareHeight = screenHeight - Constants.FOCUS_PADDING * 2 - Constants.TITLE_HEIGHT
        
        let originX: CGFloat = (screenWidth - squareWidth) / 2;
        let originY: CGFloat = (screenHeight + Constants.TITLE_HEIGHT - squareHeight) / 2
        return CGRect(x: originX, y: originY, width: squareWidth, height: squareHeight)
    }
//    MARK: Properties of Scanner, Camera
    
    let messageLabel:UILabel = {
        let label = UILabel()
        label.backgroundColor = .lightGray
        label.font = .systemFont(ofSize: 15, weight: .thin)
        label.text = "No barcode is detected"
        label.textAlignment = .center
        return label
    }()
    let videoView:UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        
        return view
    }()
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var captureDevice:AVCaptureDevice?
    
    var lastCapturedCode:String?
    
    public var barcodeScanned:((String) -> ())?
    
    private var allowedTypes = [AVMetadataObject.ObjectType.upce,
                                AVMetadataObject.ObjectType.code39,
                                AVMetadataObject.ObjectType.code39Mod43,
                                AVMetadataObject.ObjectType.ean13,
                                AVMetadataObject.ObjectType.ean8,
                                AVMetadataObject.ObjectType.code93,
                                AVMetadataObject.ObjectType.code128,
                                AVMetadataObject.ObjectType.pdf417,
                                AVMetadataObject.ObjectType.qr,
                                AVMetadataObject.ObjectType.aztec]
    // This Project can be scan 10 type of code

//    MARK: User Interface
    
    private func configBackground(){
        let frame = self.focusFrame
        self.topView.frame = CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: frame.origin.y + Constants.FOCUS_BORDER))
        
        self.bottomView.frame = CGRect(x: 0, y: frame.origin.y + frame.size.height - Constants.FOCUS_BORDER, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - Constants.FOCUS_BORDER)
        
        self.leftView.frame = CGRect(x: 0, y: frame.origin.y + Constants.FOCUS_BORDER, width: frame.origin.x + Constants.FOCUS_BORDER, height: frame.size.height - 2 * Constants.FOCUS_BORDER)
        
        self.rightView.frame = { () -> CGRect in
            var f = self.leftView.frame
            f.origin.x = frame.origin.x + frame.size.width - Constants.FOCUS_BORDER
            f.size.width = UIScreen.main.bounds.width - f.origin.x
            return f
        }()
        
        let textLayer = CATextLayer()
        
        textLayer.frame = CGRect(x: 0, y: 30, width: self.view.bounds.width, height: Constants.TITLE_HEIGHT)
        textLayer.fontSize = 13
        textLayer.alignmentMode = .center
        textLayer.string = "Chiếu vào mã vạch để quét"
        textLayer.isWrapped = true
        textLayer.truncationMode = .end
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.foregroundColor = UIColor.white.cgColor
        
        self.topView.layer.addSublayer(textLayer)
        
    }
   
    fileprivate func createViewElement() -> UIView {
        let nView = UIView()
        nView.isUserInteractionEnabled = false
        nView.backgroundColor = self.colorDefault
        self.view.layer.addSublayer(nView.layer)
        return nView
    }
    
    private func setupView(){
        self.configBackground()
        /// Setup videoView and focusView
        self.videoView.frame = self.focusFrame
        self.focusView.frame = self.videoView.frame
        //view.addSubview(videoView)
        self.view.addSubview(self.videoView)
        self.view.addSubview(self.focusView)
        self.view.addSubview(self.messageLabel)
    }
    
//  MARK: Config Camera
    private func configCamera(){
        //captureSession?.startRunning()
        // Retrieve the default capturing device for using the camera
        self.captureDevice = AVCaptureDevice.default(for: .video)
        
        // Get an instance of the AVCaptureDeviceInput class using the previous device object.
        var error:NSError?
        let input: AnyObject!
        do {
            if let captureDevice = self.captureDevice {
                input = try AVCaptureDeviceInput(device: captureDevice)
                
                if (error != nil) {
                    // If any error occurs, simply log the description of it and don't continue any more.
                    print("\(String(describing: error?.localizedDescription))")
                    return
                }
                
                // Initialize the captureSession object and set the input device on the capture session.
                captureSession = AVCaptureSession()
                captureSession?.addInput(input as! AVCaptureInput)
                
                // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
                let captureMetadataOutput = AVCaptureMetadataOutput()
                captureSession?.addOutput(captureMetadataOutput)
                
                // Set delegate and use the default dispatch queue to execute the call back
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                captureMetadataOutput.metadataObjectTypes = self.allowedTypes
                
                // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
                
                if let captureSession = captureSession {
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resize
                    videoPreviewLayer?.frame = videoView.layer.bounds
                    videoView.layer.addSublayer(videoPreviewLayer!)
                    
                    // Start video capture.
                    captureSession.startRunning()
                    
                    // Move the message label to the top view
                    view.bringSubviewToFront(messageLabel)
                    
                    // Initialize QR Code Frame to highlight the QR code
                    qrCodeFrameView = UIView()
                    qrCodeFrameView?.layer.borderColor = UIColor.red.cgColor
                    qrCodeFrameView?.layer.borderWidth = 2
                    qrCodeFrameView?.autoresizingMask = [UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin, UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin]
                    
                    view.addSubview(qrCodeFrameView!)
                    view.bringSubviewToFront(qrCodeFrameView!)
                }
            }
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
    }
// MARK: Data Output
    
    var message:String?
    var product:[String:Any]?

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No barcode is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if self.allowedTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            
            qrCodeFrameView?.frame = barCodeObject.bounds;
            
            if metadataObj.stringValue != nil {
                messageLabel.text = metadataObj.stringValue
                lastCapturedCode = metadataObj.stringValue
                
                //print("Scanned barcode: \(String(describing: metadataObj.stringValue))")
                showAlert(withTitle: "Barcode", message: metadataObj.stringValue ?? "Nothing")
                captureSession?.stopRunning()
            }

        }
    }
//  MARK: Processing Status Setup
    enum ProcessGoType {
        case up
        case down
    }
    fileprivate var timer: Timer?
    
    fileprivate lazy var processingView: UIView = {
        let view = UIView()
        let width = self.focusFrame.width - Constants.FOCUS_BORDER * 2
        view.frame = CGRect(x: self.focusFrame.origin.x + Constants.FOCUS_BORDER , y: self.focusFrame.origin.y, width: width, height: 1)
        view.backgroundColor = UIColor.red
        return view
    }()
    
    private func clearTimer(){
        timer?.invalidate()
        timer = nil
    }
    
    private func startLoadingView(){
        self.view.layer.addSublayer(self.processingView.layer)
        clearTimer()
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(showProcessingState), userInfo: nil, repeats: true)
    }
    
    @objc private func showProcessingState(){
        let topOrigin = self.focusFrame.origin.y
        let bottomOrigin = self.focusFrame.origin.y + self.focusFrame.height
        let currentY = self.processingView.frame.origin.y
        self.moveProcessStatus = currentY >= bottomOrigin ? .up : (currentY <= topOrigin ? .down : self.moveProcessStatus )
    }
    
    fileprivate let processingDuration: TimeInterval = 0.3
    
    private var moveProcessStatus: ProcessGoType = .down {
        didSet {
            if moveProcessStatus == .down {
                UIView.animate(withDuration: processingDuration) {
                    self.processingView.frame.origin.y += 2
                }
            } else {
                UIView.animate(withDuration: processingDuration) {
                    self.processingView.frame.origin.y -= 2
                }
            }
        }
    }
    
//    MARK: ScannerViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupView()
        startLoadingView()
        configCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        messageLabel.frame = CGRect(x: 11, y: 685, width: 392, height: 40)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
//    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        //showAlert(withTitle: "Test", message: "aloalo")
//        requestToAPI(barcode: "0", verifyCode: "1234", quantity: 1)
//
//    }
    

//  MARK: Helper Function
    
    private func showAlert(withTitle title:String, message:String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Huỷ", style: .cancel, handler: {[weak self](alertAction) in
            
            guard let strongSelf = self else {
                return
            }
            strongSelf.captureSession?.startRunning()
            
        }))
        alertController.addAction(UIAlertAction(title: "Xác nhận", style: .default, handler: { [weak self](alertAction) in
            
            guard let strongSelf = self else {
                return
            }
            
            let textFieldQuantity = alertController.textFields![1] as UITextField
            if textFieldQuantity.text?.isEmpty == false {
                //Read TextFields text data
                let numberOfProduct = Int(textFieldQuantity.text!) ?? 1

                if numberOfProduct == 0{
                    let alertWarning = UIAlertController(title: "Cảnh báo", message: "Nhập đúng số sản phẩm", preferredStyle: .alert)
                    alertWarning.addAction(UIAlertAction(title: "Huỷ", style: .cancel, handler: {[weak self](alertAction) in
                        guard let strongSelf = self else {
                            return
                        }
                        strongSelf.captureSession?.startRunning()
                    }))
                    strongSelf.present(alertWarning, animated: true, completion: nil)
                    return
                }

                // in case the user entered a string, the value will be 0
                print("TextField number of product : \(numberOfProduct)")
            } else {
                print("TextField 1 is Empty...")
            }
            
            let textFieldVerifyCode = alertController.textFields![0] as UITextField
            if textFieldVerifyCode.text?.isEmpty == true {
                let alertWarning = UIAlertController(title: "Cảnh báo", message: "Nhập đẩy đủ mã xác nhận", preferredStyle: .alert)
                alertWarning.addAction(UIAlertAction(title: "Huỷ", style: .cancel, handler: {[weak self](alertAction) in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.captureSession?.startRunning()
                }))
                strongSelf.present(alertWarning, animated: true, completion: nil)
                return
            }
            else
            {
                print("TextField number of product : \(textFieldVerifyCode)")
            }
            
            strongSelf.requestToAPI(barcode: strongSelf.messageLabel.text ?? "", verifyCode: textFieldVerifyCode.text!, quantity: Int(textFieldQuantity.text!)!)
            strongSelf.captureSession?.startRunning()
            
            if strongSelf.message == "Add cart successfully!"
            {
                var prod = Product()
                prod.name = (strongSelf.product?["title"] as? String) ?? ""
                prod.price = (strongSelf.product?["price"] as? Int) ?? 0
                prod.barcode = (strongSelf.product?["barcodeValue"] as? Int) ?? 0
                prod.imageURL = (strongSelf.product?["imageUrl"] as? String) ?? ""
                
                print(prod,"\n")
                
                let infoView = InfoViewController(product: prod)
                strongSelf.navigationController?.pushViewController(infoView, animated: true)
            }
            else{
                let alertWarning = UIAlertController(title: "Cảnh báo", message: "Quét thất bại", preferredStyle: .alert)
                alertWarning.addAction(UIAlertAction(title: "Huỷ", style: .cancel, handler: {[weak self](alertAction) in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.captureSession?.startRunning()
                }))
                strongSelf.present(alertWarning, animated: true, completion: nil)
            }
            
        }))
        
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Nhập mã OTP..."
            textField.textColor = .black
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Nhập số lượng sản phẩm..."
            textField.textColor = .black
        }
        present(alertController, animated: true, completion: nil)
    }
    
    private func requestToAPI(barcode:String, verifyCode:String, quantity:Int){
        
        let semaphore = DispatchSemaphore (value: 0)
        
        // create parameters
        let parameters = ["barcodeValue": "\(barcode)", "verifyCode": "\(verifyCode)", "quantity": "\(quantity)"]
        // convert to JSON
        let jsonData = try! JSONSerialization.data(withJSONObject: parameters, options: [])


        var request = URLRequest(url: URL(string: "https://banhtrangtayninh.herokuapp.com/api/postapi")!,timeoutInterval: Double.infinity)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("connect.sid=s%3AnlNGHthFbYmPq6aSR0cdweg3rxEL1ZsE.0FxCifmA%2FMLH6PirH3VnATNcYdwcI55Mx2TukeeNy38", forHTTPHeaderField: "Cookie")

        request.httpMethod = "POST"
        request.httpBody = jsonData

        DispatchQueue.global(qos: .background).async {
            
        let task = URLSession.shared.dataTask(with: request) { [weak self]data, response, error in
            
            guard let strongSelf = self else {
                            return
                        }
            
            guard let data = data else {
                print(String(describing: error))
                semaphore.signal()
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else { return }
                //print("json:", json)

                for (key, value) in json {
                    if key == "message"
                    {
                        strongSelf.message = value as? String
                        //print("message: \(strongSelf.message)")
                    }
                    else if key == "prod"
                    {
                        strongSelf.product = value as? [String:Any]
                        //print("prod: \(strongSelf.product)")
                    }
                  
                }
            } catch {
                print("error:", error)
            }
            semaphore.signal()
        }
        
        task.resume()
        }
        semaphore.wait()
    }
 
}
