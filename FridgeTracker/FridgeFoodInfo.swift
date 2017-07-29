//
//  FridgeFoodInfo.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 28/07/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

import Foundation
import UIKit

struct Fridge {

}

class FridgeFoodInfo:NSObject, NSCoding {
    var productName: String? = nil
    var expirationDate: Date? = nil
    var associatedFridge: Fridge? = nil
    var image:UIImage? = nil
    
    static let noImageIcon:UIImage? = UIImage(named: "foodIcon")
    
    /// Image url can be either a local or remote image
    var openFoodFact:OpenFoodFactsProduct? = nil {
        didSet {
            self.productName = openFoodFact?.productName
        }
    }

    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(productName, forKey: "productName")
        aCoder.encode(expirationDate, forKey: "expirationDate")
        if let image = image {
            aCoder.encode(UIImagePNGRepresentation(image), forKey: "image")
        }
        aCoder.encode(openFoodFact?.json, forKey: "openFoodFactJSON")
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        self.init()
        self.productName = aDecoder.decodeObject(forKey: "productName") as? String
        self.expirationDate = aDecoder.decodeObject(forKey: "expirationDate") as? Date
        if let json = aDecoder.decodeObject(forKey: "openFoodFactJSON") as? [String:Any] {
            self.openFoodFact = OpenFoodFactsProduct(json: json)
        }
        if let imagedata = aDecoder.decodeObject(forKey: "image") as? Data {
            self.image = UIImage(data: imagedata)
        }
    }
}

class FoodHistory {
    private var foods:[FridgeFoodInfo] = []
    static let shared:FoodHistory = FoodHistory()
    let queue = DispatchQueue.global(qos: .background)
    
    init() {
        loadHistory()
    }
    
    func sort() {
        self.foods.sort { (food1, food2) -> Bool in
            if let date1 = food1.expirationDate, let date2 = food2.expirationDate {
                if date1 < date2 {
                    return true
                } else {
                    return false
                }
            }
            return false
        }
    }
    
    // MARK: External access to foods
    
    func append(_ food: FridgeFoodInfo) {
        self.foods.append(food)
        DispatchQueue.main.async {
            self.saveHistory()
        }
    }
    
    func remove(at index: Int) {
        self.foods.remove(at: index)
        self.saveHistory()
    }
    
    subscript(index: Int) -> FridgeFoodInfo {
        get {
            return self.foods[index]
        }
        
        set {
            self.foods[index] = newValue
        }
    }
    
    var count: Int {
        return self.foods.count
    }
    
    // MARK: Save
    
    func savePath() -> String? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let documentPath = documentsPath.first {
            let fridgePath = documentPath.appendingPathComponent("fridge.db")
            return fridgePath.path
        }

        return nil
    }
    
    func saveHistory(){
        sort()
        if let file = savePath() {
            queue.async {
                NSKeyedArchiver.archiveRootObject(self.foods, toFile: file)
            }
        }
    }
    
    func loadHistory(){
        if let file = savePath() {
            let backup = NSKeyedUnarchiver.unarchiveObject(withFile: file)
            if let backup = backup as? [FridgeFoodInfo] {
                self.foods = backup
            } else {
                self.foods = []
            }
        }
    }
}
