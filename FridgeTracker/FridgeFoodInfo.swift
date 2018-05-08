//
//  FridgeFoodInfo.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 28/07/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

import Foundation
import UIKit

class FridgeFoodInfo:NSObject, NSCoding {
    var productName: String? = nil
    var expirationDate: Date? = nil
    var fridgeName: String? = nil
    var image:UIImage? = nil
    var imagePath:String? = nil
    var foodId: String? = nil
    
    static let noImageIcon:UIImage? = UIImage(named: "food")
    
    /// Image url can be either a local or remote image
    var openFoodFact:OpenFoodFactsProduct? = nil {
        didSet {
            self.productName = openFoodFact?.productName
        }
    }
    
    static func generateNewId() -> String {
        return String(Date().timeIntervalSince1970)
    }

    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        if let foodId = self.foodId {
            aCoder.encode(foodId, forKey: "foodId")
        } else {
            let foodId = FridgeFoodInfo.generateNewId()
            self.foodId = foodId
            aCoder.encode(foodId, forKey: "foodId")
        }
        aCoder.encode(productName, forKey: "productName")
        aCoder.encode(fridgeName, forKey: "fridgeName")
        aCoder.encode(expirationDate, forKey: "expirationDate")
        aCoder.encode(imagePath, forKey: "imagePath")
        aCoder.encode(openFoodFact?.json, forKey: "openFoodFactJSON")
    }
    
    var imageFileURL:URL? {
        if let imageFile = self.imagePath, let saveURL = FoodHistory.shared.saveDirectoryURL() {
            return saveURL.appendingPathComponent(imageFile)
        }
        return nil
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        self.init()
        self.foodId = aDecoder.decodeObject(forKey: "foodId") as? String
        self.fridgeName = aDecoder.decodeObject(forKey: "fridgeName") as? String
        self.productName = aDecoder.decodeObject(forKey: "productName") as? String
        self.expirationDate = aDecoder.decodeObject(forKey: "expirationDate") as? Date
        self.imagePath = aDecoder.decodeObject(forKey: "imagePath") as? String
        if let json = aDecoder.decodeObject(forKey: "openFoodFactJSON") as? [String:Any] {
            self.openFoodFact = OpenFoodFactsProduct(json: json)
        }
        if let imageFileURL = imageFileURL {
            let imagePath = imageFileURL.path
            self.image = UIImage(contentsOfFile: imagePath)
        } else if let imagedata = aDecoder.decodeObject(forKey: "image") as? Data {
            print("Legacy: loading image data from file directly")
            self.image = UIImage(data: imagedata)
        }
    }
}

