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
    @IBOutlet weak var foodInfoBottomConstant: NSLayoutConstraint!

    @IBOutlet weak var fridgePickerView: UIPickerView!
    
    @IBOutlet weak var nutritionGradeIMageView: UIImageView!
    
    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var foodNameTextField: UITextField!
    
    @IBOutlet weak var validateResultButton: UIButton!
    @IBOutlet weak var snapshotButton: UIButton!
    @IBOutlet weak var foodImage: UIImageView!
    @IBOutlet weak var addToFridgeTextButton: NSLayoutConstraint!
    //@IBOutlet weak var fridgeCountLabel: UILabel!
    
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
        if TARGET_OS_SIMULATOR != 0 {
            newDetection(forBarcode: "3266980467111")
        }
        if let lastSelectedFridge = UserDefaults.standard.object(forKey: "LastSelectedRow") as? String {
            for (index, fridgeName) in FoodHistory.shared.fridges.enumerated() {
                if fridgeName == lastSelectedFridge {
                    fridgePickerView.selectRow(index, inComponent: 0, animated: false)
                    break
                }
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.standard.synchronize()
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
            } else {
                self.displayResultScreenForNoResult()
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
        self.validateResultButton.isHidden = true
        self.nutritionGradeIMageView.image = nil
    }
    
    func displayResultScreenForNoResult(){
        self.snapshotCaptureView.isHidden = true
        self.resultSearchingInfoLabel.isHidden = true
        self.resultView.isHidden = false
        self.resultActivity.isHidden = true
        self.resultName.text = "Article inconnu"
        self.resultImage.image = nil
        self.validateResultButton.isHidden = true
        self.nutritionGradeIMageView.image = nil
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
        self.validateResultButton.isHidden = false
        if let off = self.openFoodFactResult, let grade = off.nutritionGrade, let image = UIImage(named: "Nutri-score-\(grade.uppercased())") {
            self.nutritionGradeIMageView.image = image
            self.nutritionGradeIMageView.isHidden = false
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
        self.fridgePickerView.reloadAllComponents()
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
        if !self.resultView.isHidden {
            if self.openFoodFactResult != nil {
                validateResultClick(sender)
            }
        }
        self.food?.fridgeName = fridgeNameFor(row: fridgePickerView.selectedRow(inComponent: 0))
        self.food?.productName = self.foodNameTextField.text
        self.food?.expirationDate = self.expirationdatePicker.date
        if self.food?.image == nil, self.food?.productName == "", self.food?.openFoodFact == nil {
            print("Nothing to add")
            return
        }
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
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.foodInfoBottomConstant.constant = self.foodNameTextField.frame.size.height + self.foodNameTextField.frame.origin.y
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.foodInfoBottomConstant.constant = 0
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
            //print(UIImage(data: dataImage)?.size as Any)
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            
            self.food?.image = image.correctlyOrientedImage()
            updateSelectedFoodUI()
        } else {
            print("some error here")
        }
    }
}

extension CreationViewController:UIPickerViewDelegate {
    

    // func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat { return 0.0 }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 35
    }
    
    
    //func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { }
    
    func fridgeNameFor(row: Int) -> String? {
        if FoodHistory.shared.fridges.count > row {
            return FoodHistory.shared.fridges[row]
        }
        return nil
    }
    
    // func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {}
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        let fridgeName = (fridgeNameFor(row: row) ?? "Autre")
        let fridgeContent = FoodHistory.shared.foodByFridge[fridgeName]
        let fridgeContentCount:Int
        if let fridgeContent = fridgeContent {
            fridgeContentCount = fridgeContent.count
        } else {
            fridgeContentCount = 0
        }
            
        pickerLabel.textAlignment = NSTextAlignment.left
        let fridgeContentStr = "\(String(format: "%02d", fridgeContentCount)) "
        let str:String = fridgeContentStr + " " + fridgeName
        
        let indiceFont = UIFont.systemFont(ofSize: 15)
        
        let attString = NSMutableAttributedString(string: str, attributes: [NSForegroundColorAttributeName:UIColor.white, NSFontAttributeName:UIFont.systemFont(ofSize: 28)])
        let indexRange = (str as NSString).range(of: fridgeContentStr)
        
        attString.setAttributes([NSFontAttributeName:indiceFont,NSBaselineOffsetAttributeName:-6,NSForegroundColorAttributeName:UIColor.white], range: indexRange)
        pickerLabel.attributedText = attString
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        UserDefaults.standard.set(fridgeNameFor(row: row), forKey: "LastSelectedRow")
    }

}

extension CreationViewController:UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return FoodHistory.shared.fridges.count
    }
}

