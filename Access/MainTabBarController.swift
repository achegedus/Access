//
//  MainTabBarController.swift
//  Access
//
//  Created by Adam Hegedus on 10/18/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import SimpleKeychain
import CoreData
import SwiftyJSON
import Alamofire

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //let userDefaults = UserDefaults.standard
        
        //if userDefaults.bool(forKey: "isAdmin") != true {
        //    let index = 5
        //    viewControllers?.remove(at: index)
        //}
        
        //self.tabBarController?.tabBar.tintColor = UIColor.red
        
        guard (UIApplication.shared.delegate as? AppDelegate) != nil else {
            return
        }
        
        self.getDepartmentsFromAPI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func getDepartmentsFromAPI()
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let keychain = A0SimpleKeychain(service: "Auth0")
        
        let token = keychain.string(forKey: "id_token")
        
        let authHeaders : HTTPHeaders = [
            "Authorization": "Bearer \(token!)"
        ]
        
        Alamofire.request("https://accesstemp.energycap.com/api/v1/departments", headers: authHeaders).responseJSON { response in
            if ((response.result.value) != nil) {
                let swiftyJsonVar = JSON(response.result.value!)
                
                // first empty the table
                let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Department")
                let deleteReq = NSBatchDeleteRequest(fetchRequest: fetchReq)
                do {
                    try managedContext.execute(deleteReq)
                } catch {
                    print("COULDN'T DELETE DATA")
                }
                
                if let resData = swiftyJsonVar.arrayObject {
                    
                    // loop through data and populate core data
                    for obj in resData as! [[String:AnyObject]] {
                        
                        let thisName = obj["name"] as? String
                        
                        
                        if (self.fetchDepartment(name: thisName!) == nil) {
                            let dept = Department(context: managedContext)
                            
                            if let deptName = obj["name"] as? String {
                                dept.name = deptName
                            }
                            
                            // save object
                            appDelegate.saveContext()
                        }
                    }
                }
            }
        }
    }
    
    
    func fetchDepartment(name: String) -> [Department]?
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Department> = Department.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        return try? managedContext.fetch(fetchRequest)
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
