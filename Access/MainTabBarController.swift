//
//  MainTabBarController.swift
//  Access
//
//  Created by Adam Hegedus on 10/18/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import SimpleKeychain

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
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
