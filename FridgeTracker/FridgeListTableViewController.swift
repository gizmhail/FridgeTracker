//
//  FridgeListTableViewController.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 28/07/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

import UIKit

class FridgeListTableViewController: UIViewController {
    @IBOutlet weak var fridgePickerView: UIPickerView!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.tableView.backgroundColor = self.navigationController?.viewControllers.first?.view.backgroundColor
        if let lastSelectedFridge = UserDefaults.standard.object(forKey: "BrowseLastSelectedRow") as? String {
            var i = 0
            while i < pickerView(fridgePickerView, numberOfRowsInComponent: 0) {
                if fridgeNameFor(row: i) == lastSelectedFridge {
                    fridgePickerView.selectRow(i, inComponent: 0, animated: false)
                    break
                }
                i += 1
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
}

// MARK: - Table view data source
extension FridgeListTableViewController:UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let count = foods.count
        if count > 0 {
            self.tableView.backgroundView = nil
        } else {
            let label = UILabel()
            label.text = "Aucun aliment ajouté au frigo"
            label.numberOfLines = 3
            label.textAlignment = .center
            label.textColor = UIColor.white
            self.tableView.backgroundView = label
        }
        return count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodHistoryCell", for: indexPath)
        if let cell = cell as? FridgeHistoryTableViewCell {
            let food = foods[indexPath.row]
            cell.food = food
        }
        return cell
    }
    

    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let food = foods[indexPath.row]
            FoodHistory.shared.remove(food: food)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.fridgePickerView.reloadAllComponents()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}



extension FridgeListTableViewController:UIPickerViewDelegate {
    var foods:[FridgeFoodInfo] {
        let row = fridgePickerView.selectedRow(inComponent: 0)
        if row == 0 {
            return FoodHistory.shared.allFoods()
        } else {
            let fridgeName = (fridgeNameFor(row: row) ?? "Autre")
            return FoodHistory.shared.foodByFridge[fridgeName] ?? []
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 35
    }

    func fridgeNameFor(row: Int) -> String? {
        if row == 0 {
            return "N'importe où"
        }
        let fridge = row - 1
        if FoodHistory.shared.fridges.count > fridge {
            return FoodHistory.shared.fridges[fridge]
        }
        return nil
    }
    
    // func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {}
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        let fridgeContent:[FridgeFoodInfo]?
        let fridgeName = (fridgeNameFor(row: row) ?? "Autre")
        if row == 0 {
            fridgeContent = FoodHistory.shared.allFoods()
        } else {
            fridgeContent = FoodHistory.shared.foodByFridge[fridgeName]
        }
        let fridgeContentCount:Int
        if let fridgeContent = fridgeContent {
            fridgeContentCount = fridgeContent.count
        } else {
            fridgeContentCount = 0
        }
        
        pickerLabel.textAlignment = NSTextAlignment.center
        let fridgeContentStr = "\(String(format: "%02d", fridgeContentCount)) "
        let str:String =  fridgeName + " " + fridgeContentStr
        
        let indiceFont = UIFont.systemFont(ofSize: 15)
        
        let attString = NSMutableAttributedString(string: str, attributes: [NSForegroundColorAttributeName:UIColor.white, NSFontAttributeName:UIFont.systemFont(ofSize: 28)])
        let indexRange = (str as NSString).range(of: fridgeContentStr)
        
        attString.setAttributes([NSFontAttributeName:indiceFont,NSBaselineOffsetAttributeName:-6,NSForegroundColorAttributeName:UIColor.white], range: indexRange)
        pickerLabel.attributedText = attString
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.tableView.reloadData()
        UserDefaults.standard.set(fridgeNameFor(row: row), forKey: "BrowseLastSelectedRow")

    }
    
}

extension FridgeListTableViewController:UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return FoodHistory.shared.fridges.count + 1
    }
}
