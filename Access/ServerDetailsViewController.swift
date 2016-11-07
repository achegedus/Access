//
//  ServerDetailsViewController.swift
//  Access
//
//  Created by Adam Hegedus on 10/17/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import SimpleKeychain
import Auth0
import Alamofire
import SwiftyJSON


class ServerDetailsViewController: UIViewController {

    var serverId : Int = 0
    var serverName : String = ""
    
    @IBOutlet weak var thumbImage: UIImageView!
    @IBOutlet weak var serverNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var currentResponseLabel: UILabel!
    @IBOutlet weak var lastCheckLabel: UILabel!
    @IBOutlet weak var lastErrorLabel: UILabel!
    @IBOutlet weak var totalDownLabel: UILabel!
    @IBOutlet weak var uptimePercLabel: UILabel!
    @IBOutlet weak var avgResponseLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.getData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func getData()
    {
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
        
        Alamofire.request("https://accesstemp.energycap.com/api/v1/servers/\(self.serverId)", headers: authHeaders).responseJSON { response in
            if ((response.result.value) != nil) {
                let json = JSON(response.result.value!)
                
                let inputDateFormatter = DateFormatter()
                inputDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                let outputDateFormatter = DateFormatter()
                outputDateFormatter.dateFormat = "MMM dd, YYYY @ hh:mm a"
                
                let status = json["status"].stringValue
                
                if status == "up" {
                    self.thumbImage.image = UIImage(named:"ThumbsUp_big")
                } else {
                    self.thumbImage.image = UIImage(named:"ThumbsDown_big")
                }
                
                self.locationLabel.text = json["location"].stringValue
                self.serverNameLabel.text = json["name"].stringValue.uppercased()
                self.currentResponseLabel.text = "\(json["lastResponseTime"].stringValue) ms"
                self.uptimePercLabel.text = "\(json["uptime_percentage"].stringValue)%"
                self.avgResponseLabel.text = "\(json["avg_response"].stringValue) ms"
                
                self.totalDownLabel.text = json["total_downtime"].stringValue
                
                let lastError = json["lastErrorTime"].stringValue
                let lastErrorDate = inputDateFormatter.date(from: lastError)
                self.lastErrorLabel?.text = outputDateFormatter.string(from: lastErrorDate! as Date)
                
                let lastCheck = json["lastTestTime"].stringValue
                let lastCheckDate = inputDateFormatter.date(from: lastCheck)
                self.lastCheckLabel?.text = outputDateFormatter.string(from: lastCheckDate! as Date)
                
                print("Downloaded Server Detail")
            }
        }

    }
}
