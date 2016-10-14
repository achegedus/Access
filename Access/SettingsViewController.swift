//
//  SettingsViewController.swift
//  Access
//
//  Created by Adam Hegedus on 10/13/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import Lock
import SimpleKeychain


class SettingsViewController: UIViewController {
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let releaseVersionNumber = Bundle.main.infoDictionary!["CFBundleShortVersionString"];
        
        let buildVersionNumber = Bundle.main.infoDictionary!["CFBundleVersion"];
        
        self.versionLabel.text = "Version \(releaseVersionNumber!), Build \(buildVersionNumber!)";
        
        let keychain = A0SimpleKeychain(service: "Auth0")
        
        if let data = keychain.data(forKey: "profile"), let profile = NSKeyedUnarchiver.unarchiveObject(with: data) {
            self.usernameLabel.text = (profile as AnyObject).name
            self.emailLabel.text = (profile as AnyObject).email
        }

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutButtonPressed(_ sender: AnyObject) {
        
        let sureAlert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: UIAlertControllerStyle.alert)
        
        let OKAction = UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            let keychain = A0SimpleKeychain(service: "Auth0");
            keychain.clearAll();
            
            self.performSegue(withIdentifier: "unwindToLogout", sender: sender)
        })
        
        let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Logout Cancelled");
        })
        
        sureAlert.addAction(OKAction);
        sureAlert.addAction(CancelAction);
        present(sureAlert, animated: true, completion: nil)
        
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
