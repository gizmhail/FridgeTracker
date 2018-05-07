//
//  OpenFoodFactsRequest.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 28/07/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

import Foundation

struct OpenFoodFactsProduct {
    let json:[String:Any]
    
    var productInfo:[String:Any]? {
        return json["product"] as? [String:Any]
    }
    
    var productName:String? {
        return productInfo?["product_name"] as? String
    }
    
    var imageUrlStr:String? {
        return productInfo?["image_url"] as? String
    }
    
    var barcode: String? {
        return json["code"] as? String
    }
    
    var nutritionGrade: String? {
        return productInfo?["nutrition_grades"] as? String
    }
}


extension URLSession {
    func openFoodFactTask(forBarcode barcode:String, completionHandler: @escaping (OpenFoodFactsProduct?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        let urlStr = "https://ssl-api.openfoodfacts.org/api/v0/product/\(barcode)"
        guard let url = URL(string: urlStr) else {
            return nil
        }
        let request = URLRequest(url: url)
        return self.dataTask(with: request) { (data, response, error) in
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let productInfo = json as? [String:Any]{
                DispatchQueue.main.async {
                    completionHandler(OpenFoodFactsProduct(json: productInfo), response, error)
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler(nil, response, error)
                }
            }
        }
    }

}
