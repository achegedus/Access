//
//  AlertsTableViewController.swift
//  Access
//
//  Created by Adam Hegedus on 10/14/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import SimpleKeychain
import Auth0
import Alamofire
import SwiftyJSON
import CoreData

class AlertsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    

    lazy var context: NSManagedObjectContext! = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()
    
    
    lazy var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>! = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "OpsAlert")
        let primarySort = NSSortDescriptor(key: "sendDate", ascending: false)
        
        fetchRequest.sortDescriptors = [primarySort]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()


    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 150
        
        self.getAlerts()
        self.getData()
    }
    
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        getData()
        refreshControl.endRefreshing()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let sectionCount = self.fetchedResultsController.sections?.count else {
            return 0
        }
        return sectionCount
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let sectionData = self.fetchedResultsController.sections?[section] else {
            return 0
        }
        return sectionData.numberOfObjects
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.name
        }
        
        return nil
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let alert = self.fetchedResultsController.object(at: indexPath) as! OpsAlert

        let cell = tableView.dequeueReusableCell(withIdentifier: "alertTableCell") as! AlertsTableViewCell
        
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MMM dd, YYYY @ hh:mm a"
        let thisDate = alert.sendDate! as NSDate
        
        cell.alertLabel?.text = alert.bodyText as String!
        cell.dateLabel?.text = dayTimePeriodFormatter.string(from: thisDate as Date)
        
        if alert.isEmergency == true {
            cell.typeImage.image = UIImage(named:"icon_alert_red")
        }

        return cell
    }


    @IBAction func newAlertButtonPressed(_ sender: AnyObject) {
        print("HELLO NEW ALERT")
    }
    
    
    func getAlerts() {
        do{
            try self.fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FRC - Alerts")
        }
        
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
            "Authorization": "Bearer \(token!)"
        ]
        
        Alamofire.request("https://accesstemp.energycap.com/api/v1/alerts", headers: authHeaders).responseJSON { response in
            if ((response.result.value) != nil) {
                let swiftyJsonVar = JSON(response.result.value!)
                
                if let resData = swiftyJsonVar.arrayObject {
                    
                    // first empty the table
                    let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "OpsAlert")
                    let deleteReq = NSBatchDeleteRequest(fetchRequest: fetchReq)
                    do {
                        try managedContext.execute(deleteReq)
                    } catch {
                        print("COULDN'T DELETE DATA")
                    }
                    
                    // loop through data and populate core data
                    for obj in resData as! [[String:AnyObject]] {
                        
                        debugPrint(obj)
                        let opsAlert = OpsAlert(context: managedContext)
                        
                        if let sender = obj["sender"] as? String {
                            opsAlert.sender = sender
                        } else {
                            opsAlert.sender = ""
                        }
                        
                        if let body = obj["alert_body"] as? String {
                            opsAlert.bodyText = body
                        } else {
                            opsAlert.bodyText = ""
                        }
                        
                        if let sendDate = obj["created_at"] as? String {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            let date = dateFormatter.date(from: sendDate)
                            
                            opsAlert.sendDate = date as NSDate?
                        } else {
                            opsAlert.sendDate = nil
                        }
                        
                        if let alertID = obj["id"] as? Int16 {
                            opsAlert.id = alertID
                        } else {
                            opsAlert.id = 0
                        }
                        
                        if let isEmergency = obj["isEmergency"] as? Int16 {
                            if isEmergency == 1 {
                                opsAlert.isEmergency = true
                            } else {
                                opsAlert.isEmergency = false
                            }
                        } else {
                            opsAlert.isEmergency = false
                        }

                        
                        
                        
                        appDelegate.saveContext()
                    }
                }
                
                print("Downloaded Alert Data")
                self.getAlerts()
            }
        }
    }
}
