//
//  FridgeHistoryTableViewCell.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 28/07/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

import UIKit

class FridgeHistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var expirationDateLabel: UILabel!
    @IBOutlet weak var foodImageview: UIImageView!
    var food:FridgeFoodInfo? = nil {
        didSet {
            if let expirationDate = self.food?.expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .none
                self.expirationDateLabel.text = formatter.string(from: expirationDate)
            }
            
            self.productNameLabel.text = self.food?.productName ?? ""
            self.foodImageview?.image = self.food?.image ?? FridgeFoodInfo.noImageIcon
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
