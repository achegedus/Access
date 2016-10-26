//
//  TicketsTableViewController.swift
//  Access
//
//  Created by Adam Hegedus on 10/17/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import SimpleKeychain
import SwiftyJSON
import CoreData
import Alamofire

class TicketsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userDefaults = UserDefaults.standard
        
        if userDefaults.bool(forKey: "isAdmin") == true {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 150
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UserChatSegue"
        {
            let userDefaults = UserDefaults.standard
            
            if let destinationVC = segue.destination as? ChatViewController {
                destinationVC.username = ((userDefaults.object(forKey: "fullname") as! String).replacingOccurrences(of: " ", with: "_"))
            }
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            backItem.tintColor = UIColor.white
            navigationItem.backBarButtonItem = backItem
        }
    }
    

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func getTickets() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let fetchRequest = Ticket.fetchRequest() as NSFetchRequest<Ticket>
        
        do {
            self.getTickets = try context.fetch(fetchRequest) as [Ticket]
        } catch {}
        
        self.tableView.reloadData()
    }
    
    
    func getData() {
        
        // data was recieved now store in core data
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let keychain = A0SimpleKeychain(service: "Auth0")
        
        let token = keychain.string(forKey: "id_token")
        
        let authHeaders : HTTPHeaders = [
            "Authorization": "Basic YWRhbWg6Q2hhcmwhZQ=="
        ]
        
        Alamofire.request("https://jira.energycap.com/rest/api/2/search?jql=reporter='scottb' AND status!='Closed'&issuetype='Support Ticket'&fields=summary,key,status,description,created,updated,comment,assignee,priority", headers: authHeaders).responseJSON { response in
            if ((response.result.value) != nil) {
                let swiftyJsonVar = JSON(response.result.value!)
                
                if let resData = swiftyJsonVar.arrayObject {
                    
                    // first empty the table
                    let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Ticket")
                    let deleteReq = NSBatchDeleteRequest(fetchRequest: fetchReq)
                    do {
                        try managedContext.execute(deleteReq)
                    } catch {
                        print("COULDN'T DELETE TICKET DATA")
                    }
                    
                    // loop through data and populate core data
                    for obj in resData as! [[String:AnyObject]] {
                        
                        debugPrint(obj)
                        let opsTicket = Ticket(context: managedContext)
                        
                        if let id = obj["id"] as? Int16 {
                            opsTicket.id = id
                        } else {
                            opsTicket.id = 0
                        }
                        
                        if let key = obj["key"] as? String {
                            opsTicket.key = key
                        } else {
                            opsTicket.key = ""
                        }

                        appDelegate.saveContext()
                    }
                }
                
                print("Downloaded Ticket Data")
                self.getTickets()
            }
        }
    }

}
