//
//  CreationViewController.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 27/07/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

/*
 Sources:
 - https://www.appcoda.com/barcode-reader-swift/
*/

import UIKit
import AVFoundation

class CreationViewController: UIViewController {

    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var foodNameTextField: UITextField!
    
    @IBOutlet weak var snapshotButton: UIButton!
    @IBOutlet weak var foodImage: UIImageView!
    @IBOutlet weak var addToFridgeTextButton: NSLayoutConstraint!
    @IBOutlet weak var fridgeCountLabel: UILabel!
    
    @IBOutlet weak var addToFridgeButton: NSLayoutConstraint!
    var avCaptureSession:AVCaptureSession?
    var cameraViewLayer:AVCaptureVideoPreviewLayer?
    var barcodeFrameView:UIView?
    var latestBarcodeValue:String? = nil
    var snapshotOutput = AVCapturePhotoOutput()

    @IBOutlet weak var snapshotCaptureView: UIView!
    
    @IBOutlet weak var expirationdatePicker: UIDatePicker!
    var food:FridgeFoodInfo? = nil
    
    // Scan result
    var foodRequest:URLSessionTask? = nil
    @IBOutlet weak var barCodeResult: UILabel!
    @IBOutlet weak var resultActivity: UIActivityIndicatorView!
    @IBOutlet weak var resultName: UILabel!
    @IBOutlet weak var resultImage: UIImageView!
    @IBOutlet weak var resultView: UIView!
    @IBOutlet weak var resultSearchingInfoLabel: UILabel!
    var openFoodFactResult:OpenFoodFactsProduct? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureInitialisation()
        resetFoodInfo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func resetFoodInfo() {
        self.food = FridgeFoodInfo()
        updateSelectedFoodUI()
        dismissResultScreen()
        self.expirationdatePicker.date = Date()
    }
    
    func captureInitialisation() {
        // Camera input
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            avCaptureSession = AVCaptureSession()
            avCaptureSession?.addInput(input)
        } catch {
            print(error)
            return
        }
        
        // Snapshot output
        if let avCaptureSession = avCaptureSession, avCaptureSession.canAddOutput(snapshotOutput) {
            avCaptureSession.addOutput(snapshotOutput)
        }
        
        // MD output
        let mdOutput = AVCaptureMetadataOutput()
        avCaptureSession?.addOutput(mdOutput)
        mdOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        mdOutput.metadataObjectTypes = [AVMetadataObjectTypeEAN13Code]
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        cameraViewLayer = AVCaptureVideoPreviewLayer(session: avCaptureSession)
        if let cameraViewLayer = cameraViewLayer {
            cameraViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            cameraViewLayer.frame = captureView.layer.bounds
            captureView.layer.addSublayer(cameraViewLayer)
        }
        avCaptureSession?.startRunning()
        
        // Prepare the barcode frame
        barcodeFrameView = UIView()
        if let barcodeFrameView = barcodeFrameView {
            barcodeFrameView.layer.borderColor = UIColor.green.cgColor
            barcodeFrameView.layer.borderWidth = 2
            captureView.addSubview(barcodeFrameView)
            captureView.bringSubview(toFront: barcodeFrameView)
            barcodeFrameView.isHidden = true
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        cameraViewLayer?.frame = view.layer.bounds
        cameraViewLayer?.connection.videoOrientation = AVCaptureVideoOrientation(from: UIApplication.shared.statusBarOrientation) ?? .portrait
    }
    
    // Barcode analysis
    
    func newDetection(forBarcode barcode:String) {
        print("Barcode: \(barcode)")
        self.displayResultScreen(forBarcode: barcode)
        
        self.foodRequest?.cancel()
        self.foodRequest = URLSession.shared.openFoodFactTask(forBarcode: barcode, completionHandler: { (product, response, error) in
            if let product = product, let foodName = product.productName {
                self.openFoodFactResult = product
                self.displayResultScreen(forFoodName: foodName)
                if let foodImageUrlStr = product.imageUrlStr,
                    let foodImageUrl = URL(string: foodImageUrlStr),
                    let data = try? Data(contentsOf: foodImageUrl) {
                    self.displayResultScreen(forFoodName: foodName, foodImage: UIImage(data: data), activityRunning: false)
                } else {
                    self.displayResultScreen(forFoodName: foodName, foodImage: nil, activityRunning: false)
                }
            }
        })
        self.foodRequest?.resume()
    }
    
    // MARK: Result screen
    
    func displayResultScreen(forBarcode code: String){
        self.resultView.isHidden = false
        self.barCodeResult.text = code
        self.resultActivity.isHidden = false
        self.resultSearchingInfoLabel.isHidden = false
        self.resultImage.image = FridgeFoodInfo.noImageIcon
        self.resultName.text = ""
        self.snapshotCaptureView.isHidden = true
    }
    
    func displayResultScreen(forFoodName foodName: String?, foodImage: UIImage? = nil, activityRunning: Bool = true) {
        self.snapshotCaptureView.isHidden = true
        self.resultSearchingInfoLabel.isHidden = true
        self.resultView.isHidden = false
        self.resultActivity.isHidden = !activityRunning
        if let foodName = foodName{
            self.resultName.text = foodName
        } else {
            self.resultName.text = "Inconnu"
        }
        if let foodImage = foodImage {
            self.resultImage.image = foodImage
        } else {
            self.resultImage.image = FridgeFoodInfo.noImageIcon
        }
    }

    func dismissResultScreen() {
        self.snapshotCaptureView.isHidden = false
        self.resultView.isHidden = true
        self.openFoodFactResult = nil
        self.latestBarcodeValue = nil
    }
    
    func updateSelectedFoodUI() {
        self.foodNameTextField.text = self.food?.productName ?? ""
        if self.food?.image == nil {
            self.foodImage.image = FridgeFoodInfo.noImageIcon
        } else {
            self.foodImage.image = self.food?.image
        }
        self.fridgeCountLabel.text = String(format: "%02d", FoodHistory.shared.count)
    }
    
    // MARK: Interaction
    
    @IBAction func validateResultClick(_ sender: Any) {
        self.food?.openFoodFact = self.openFoodFactResult
        self.food?.image = self.resultImage.image
        self.food?.expirationDate = self.expirationdatePicker.date
        updateSelectedFoodUI()
        dismissResultScreen()
    }
    
    @IBAction func cancelResultClick(_ sender: Any) {
        latestBarcodeValue = nil
        dismissResultScreen()
    }
    
    @IBAction func addToFridge(_ sender: Any) {
        self.food?.productName = self.foodNameTextField.text
        self.food?.expirationDate = self.expirationdatePicker.date
        if let food = self.food {
            FoodHistory.shared.append(food)
        }
        self.resetFoodInfo()
    }
    
    @IBAction func expirationdateChange(_ sender: Any) {
        self.food?.expirationDate = self.expirationdatePicker.date
    }
    
    @IBAction func snapshotClick(_ sender: Any) {
        if let _ = snapshotOutput.connection(withMediaType: AVMediaTypeVideo) {
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG])
            snapshotOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
}

extension CreationViewController:AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        // print(metadataObjects)
        barcodeFrameView?.isHidden = false
        for mdObject in metadataObjects {
            if let mdObject = mdObject as? AVMetadataMachineReadableCodeObject {
                if let barCodeObject = cameraViewLayer?.transformedMetadataObject(for: mdObject), let barcode = mdObject.stringValue {
                    
                    if barcode != latestBarcodeValue {
                        latestBarcodeValue = barcode
                        barcodeFrameView?.frame = barCodeObject.bounds

                        newDetection(forBarcode: barcode)
                        return
                    }
                }
            }
        }
        barcodeFrameView?.frame = CGRect.zero
    }
}

extension CreationViewController:UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension CreationViewController:AVCapturePhotoCaptureDelegate {
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        // Source: https://stackoverflow.com/questions/39173865/avcapturestillimageoutput-vs-avcapturephotooutput-in-swift-3
        if let error = error {
            print("error occure : \(error.localizedDescription)")
        }
        
        if  let sampleBuffer = photoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
            print(UIImage(data: dataImage)?.size as Any)
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            
            self.food?.image = image
            updateSelectedFoodUI()
        } else {
            print("some error here")
        }
    }
}

