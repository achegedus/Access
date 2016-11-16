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
import SimpleKeychain
import Auth0
import CoreData


class ServersTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    
    lazy var context: NSManagedObjectContext! = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()
    
    
    lazy var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>! = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ServerStat")
        let primarySort = NSSortDescriptor(key: "location", ascending: true)
        
        fetchRequest.sortDescriptors = [primarySort]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: "location", cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 150
        
        self.getStats()
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
        
        let server = self.fetchedResultsController.object(at: indexPath) as! ServerStat
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "serverTableCell") as! ServersTableViewCell
        
        cell.serverId = Int(server.serverId)
        cell.serverName = server.serverName!
        
        cell.serverNameLabel?.text = server.serverName!.uppercased()
        cell.responseTimeLabel?.text = "\(server.responseTime)ms"
        cell.locationLabel?.text = server.location!
        
        if server.status == "up" {
            cell.thumbImage.image = UIImage(named: "ThumbsUp_small")
        } else {
            cell.thumbImage.image = UIImage(named: "ThumbsDown_small")
        }
        
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MMM dd, YYYY @ hh:mm a"
        let thisDate = server.lastCheck! as NSDate
        
        cell.lastCheckLabel?.text = "Last Check: \(dayTimePeriodFormatter.string(from: thisDate as Date))"
        
        return cell
    }
    
    
    func getStats() {
        
        // initialize frc
        do{
            try self.fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FRC - Server Stats")
        }
        
        self.tableView.reloadData()
        
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
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
        
        Alamofire.request("https://accesstemp.energycap.com/api/v1/servers", headers: authHeaders).responseJSON { response in
            if ((response.result.value) != nil) {
                let swiftyJsonVar = JSON(response.result.value!)
                
                if let resData = swiftyJsonVar.arrayObject {
                    
                    // first empty the table
                    let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "ServerStat")
                    let deleteReq = NSBatchDeleteRequest(fetchRequest: fetchReq)
                    do {
                        try managedContext.execute(deleteReq)
                    } catch {
                        print("COULDN'T DELETE DATA")
                    }
                    
                    // loop through data and populate core data
                    for obj in resData as! [[String:AnyObject]] {
                        
                        let server = ServerStat(context: managedContext)
                        
                        if let serverID = obj["pingdom_id"] as? Int64 {
                            server.serverId = serverID
                        } else {
                            server.serverId = 0
                        }
                        
                        if let name = obj["name"] as? String {
                            server.serverName = name
                        } else {
                            server.serverName = ""
                        }
                        
                        if let hostname = obj["hostname"] as? String {
                            server.hostname = hostname
                        } else {
                            server.hostname = ""
                        }
                        
                        if let lastErrorTime = obj["lastErrorTime"] as? String {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            let date = dateFormatter.date(from: lastErrorTime)
                            
                            server.lastError = date as NSDate?
                        } else {
                            server.lastError = nil
                        }
                        
                        if let lastCheck = obj["lastTestTime"] as? String {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            let date = dateFormatter.date(from: lastCheck)
                            
                            server.lastCheck = date as NSDate?
                        } else {
                            server.lastCheck = nil
                        }
                        
                        if let lastResponseTime = obj["lastResponseTime"] as? Int64 {
                            server.responseTime = lastResponseTime
                        } else {
                            server.responseTime = 0
                        }
                        
                        if let status = obj["status"] as? String {
                            server.status = status
                        } else {
                            server.status = nil
                        }
                        
                        if let location = obj["location"] as? String {
                            server.location = location
                        } else {
                            server.location = nil
                        }
                        
                        // save object
                        appDelegate.saveContext()
                    }
                }
                
                print("Downloaded Alert Data")
                self.getStats()
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Servers"
        backItem.tintColor = UIColor.white
        navigationItem.backBarButtonItem = backItem

        
        if let indexPath = self.tableView.indexPathForSelectedRow {
            let server = self.fetchedResultsController.object(at: indexPath) as! ServerStat
            
            let detail = segue.destination as! ServerDetailsViewController
            detail.serverId = Int(server.serverId)
            detail.serverName = server.serverName!
        }
        
    }

}
