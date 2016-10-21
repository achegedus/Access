//
//  ServersTableViewController.swift
//  Access
//
//  Created by Adam Hegedus on 10/17/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ServersTableViewController: UITableViewController {

    var arrRes = [[[String:AnyObject]]]()
    let sections = ["Pittsburgh", "State College"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        arrRes = [[],[]]
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 150
        self.getData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (arrRes[section]).count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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

    
    func getData() {
        
        
        let authHeaders : HTTPHeaders = [
            "App-Key": "45hgnn8m0zlib3het48gzp4a97oqaduh"
        ]
        
        let user = "osc@energycap.com"
        let password = "faser1217"
        
        var pittServers = [[String:AnyObject]]()
        var StateCollegeServers = [[String:AnyObject]]()
        
        Alamofire.request("https://api.pingdom.com/api/2.0/checks?include_tags=true&tags=pittsburgh", headers: authHeaders)
            .authenticate(user: user, password: password)
            .responseJSON { response in
                if ((response.result.value) != nil) {
                    let swiftyJsonVar = JSON(response.result.value!)
                    
                    if let resData = swiftyJsonVar["checks"].arrayObject {
                        pittServers = resData as! [[String:AnyObject]]
                    }
                    
                    self.arrRes = [pittServers]
                }
                
                Alamofire.request("https://api.pingdom.com/api/2.0/checks?include_tags=true&tags=state-college", headers: authHeaders)
                    .authenticate(user: user, password: password)
                    .responseJSON { response in
                        if ((response.result.value) != nil) {
                            let swiftyJsonVar = JSON(response.result.value!)
                            
                            
                            if let resData = swiftyJsonVar["checks"].arrayObject {
                                StateCollegeServers = resData as! [[String:AnyObject]]
                            }
                            
                            self.arrRes.append(StateCollegeServers)
                        }
                        
                        if (self.arrRes[0].count > 0 || self.arrRes[1].count > 0) {
                            self.tableView.reloadData()
                        }
                }
        }
        
        
    }
}
