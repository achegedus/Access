//
//  ServerDetailsViewController.swift
//  Access
//
//  Created by Adam Hegedus on 10/17/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import Alamofire

class ServerDetailsViewController: UIViewController {

    var serverId : Int = 0
    var serverName : String = ""
    
    @IBOutlet weak var thumbImage: UIImageView!
    @IBOutlet weak var serverNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var lastCheckLabel: UILabel!
    @IBOutlet weak var lastErrorLabel: UILabel!
    @IBOutlet weak var downtimeLabel: UILabel!
    @IBOutlet weak var uptimeLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.serverName
        
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
        
        let authHeaders : HTTPHeaders = [
            "App-Key": "45hgnn8m0zlib3het48gzp4a97oqaduh"
        ]
        
        let user = "osc@energycap.com"
        let password = "faser1217"
        
        Alamofire.request("https://api.pingdom.com/api/2.0/checks/494719", headers: authHeaders)
            .authenticate(user: user, password: password)
            .responseJSON { response in
                if ((response.result.value) != nil) {
                    //let swiftyJsonVar = JSON(response.result.value!)
                    
                    
            }
        }
    }
}
