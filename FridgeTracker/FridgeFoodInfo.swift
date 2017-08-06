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

class FoodHistory {
    private var foods:[FridgeFoodInfo] = []
    var foodByFridge:[String:[FridgeFoodInfo]] = [:]
    var fridges:[String] = ["Frigo", "Placard", "Congélateur", "Frigo 2", "Autre"]
    static let shared:FoodHistory = FoodHistory()
    let queue = DispatchQueue.global(qos: .background)
    
    init() {
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
    
    func allFoods() -> [FridgeFoodInfo] {
        return foods
    }
    
    func append(_ food: FridgeFoodInfo) {
        self.foods.append(food)
        DispatchQueue.main.async {
            self.saveHistory()
        }
    }

    func remove(food: FridgeFoodInfo) {
        if let index = self.foods.index(of: food) {
            remove(at: index)
        }
    }
    
    func remove(at index: Int) {
        let food = self.foods[index]
        if let imagePath = food.imagePath {
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: imagePath))
                print("Deleted image file \(imagePath)")
            } catch {
                print("Unable to delete image file \(imagePath)")
            }
        }
        NotificationScheduler.shared.cancelNotification(food: food)
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
    
    func saveDirectoryURL() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let documentPath = documentsPath.first {
            return documentPath
        }
        
        return nil
    }
    
    func databasePath() -> String? {
        if let saveDirectoryURL = saveDirectoryURL() {
            let fridgePath = saveDirectoryURL.appendingPathComponent("fridge.db")
            return fridgePath.path
        }

        return nil
    }
    
    func backupHistory() {
        if let dbPath = databasePath() {
            do {
                try FileManager.default.copyItem(at: URL(fileURLWithPath: dbPath) , to: URL(fileURLWithPath: dbPath + ".backup"))
            } catch {
                print("Unableto backup db")
            }
        }
    }
    
    func saveHistory(){
        sort()
        if let file = databasePath() {
            DispatchQueue.main.async {
                print("Saving...")
                // Saving images
                if let saveDirectoryURL = self.saveDirectoryURL() {
                    for food in self.foods {
                        if food.foodId == nil {
                            food.foodId = FridgeFoodInfo.generateNewId()
                        }
                        if let image = food.image, let foodId = food.foodId {
                            let imagePath = saveDirectoryURL.appendingPathComponent(foodId)
                            if FileManager.default.isReadableFile(atPath: imagePath.path) {
                                // Already saved
                            } else {
                                do {
                                    food.imagePath = imagePath.path.replacingOccurrences(of: saveDirectoryURL.path, with: "")
                                    try UIImagePNGRepresentation(image)?.write(to: imagePath)
                                    let size = try FileManager.default.attributesOfItem(atPath: imagePath.path)[FileAttributeKey.size]
                                    print("Saved image at \(imagePath). Size: \(size.debugDescription)")
                                } catch {
                                    print("Unable to save image")
                                }
                            }
                        }
                        NotificationScheduler.shared.scheduleNotification(food: food, completionHandler: { (schedlued) in
                            print("Scheduled: \(schedlued)")
                        })
                    }
                }
                // Saving metadata
                NSKeyedArchiver.archiveRootObject(self.foods, toFile: file)
                print("History saved !")
            }
        }
        updateFoodByFridge()
    }
    
    func updateFoodByFridge() {
        foodByFridge = [:]
        for food in foods {
            let fridgeName = food.fridgeName ?? "Autre"
            if !fridges.contains(fridgeName) {
                fridges.append(fridgeName)
            }
            if foodByFridge[fridgeName] == nil {
                foodByFridge[fridgeName] = []
            }
            foodByFridge[fridgeName]?.append(food)
        }
    }
    
    func loadHistory(){
        if let file = databasePath() {
            let backup = NSKeyedUnarchiver.unarchiveObject(withFile: file)
            if let backup = backup as? [FridgeFoodInfo] {
                self.foods = backup
                updateFoodByFridge()
            } else {
                self.foods = []
            }
        }
    }
}
