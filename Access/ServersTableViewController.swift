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
import CoreData


class ServersTableViewController: UITableViewController {

    var opsServers : [ServerStat] = []
    
    let sections = ["Pittsburgh", "State College"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 150
        
        self.getStats()
        self.getData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.opsServers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "serverTableCell") as! ServersTableViewCell
        
        cell.serverId = Int(opsServers[indexPath.row].serverId)
        cell.serverName = opsServers[indexPath.row].serverName!
        
        cell.serverNameLabel?.text = opsServers[indexPath.row].serverName!.uppercased()
        cell.responseTimeLabel?.text = "\(opsServers[indexPath.row].responseTime)ms"
        cell.locationLabel?.text = opsServers[indexPath.row].location!
        
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MMM dd, YYYY @ hh:mm a"
        
        cell.lastCheckLabel?.text = "Last Check: \(dayTimePeriodFormatter.string(from: opsServers[indexPath.row].lastCheck as! Date))"
        
        // Configure the cell...
        
        return cell
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Servers"
        backItem.tintColor = UIColor.white
        navigationItem.backBarButtonItem = backItem
    }
    
    
    func getStats() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let fetchRequest = ServerStat.fetchRequest() as NSFetchRequest<ServerStat>
        
        do {
            self.opsServers = try context.fetch(fetchRequest) as [ServerStat]
            print(opsServers)
        } catch {}
        
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
        
        let authHeaders : HTTPHeaders = [
            "App-Key": "45hgnn8m0zlib3het48gzp4a97oqaduh"
        ]
        
        let user = "osc@energycap.com"
        let password = "faser1217"
        
        Alamofire.request("https://api.pingdom.com/api/2.0/checks?include_tags=true&tags=pittsburgh,state-college", headers: authHeaders)
            .authenticate(user: user, password: password)
            .responseJSON { response in
                if ((response.result.value) != nil) {
                    let swiftyJsonVar = JSON(response.result.value!)
                    
//                    if let resData = swiftyJsonVar["checks"].arrayObject {
                    
                        // first empty the table
                        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "ServerStat")
                        let deleteReq = NSBatchDeleteRequest(fetchRequest: fetchReq)
                        do {
                            try managedContext.execute(deleteReq)
                        } catch {
                            print("COULDN'T DELETE DATA")
                        }
                        
                        // loop through data and populate core data
                        for obj in swiftyJsonVar["checks"] {
                            let server = ServerStat(context: managedContext)
                            
                            guard
                                let serverID = obj["id"] as? Int64,
                                let created = obj["created"] as? TimeInterval,
                                let name = obj["name"] as? String,
                                let hostname = obj["hostname"] as? String,
                                let lastErrorTime = obj["lasterrortime"] as? TimeInterval,
                                let lastCheck = obj["lasttesttime"] as? TimeInterval,
                                let lastResponseTime = obj["lastresponsetime"] as? Int64,
                                let status = obj["status"] as? String
                                else {
                                    return
                            }
                            
                            for (key, subJson) in obj["tags"] {
                                if let title = subJson["name"].string {
                                    if title == "Pittsburgh" {
                                        server.location = "Pittsburgh"
                                    }
                                    else {
                                        server.location = "State College"
                                    }
                                } else {
                                    server.location = "Unknown"
                                }
                            }
                            
                            // save object
                            server.serverName = name
                            server.serverId = serverID
                            server.lastCheck = NSDate(timeIntervalSince1970: lastCheck)
                            server.location = ""
                            server.responseTime = lastResponseTime
                            appDelegate.saveContext()
                        }
//                    }
                }
            }
        
    }
}
