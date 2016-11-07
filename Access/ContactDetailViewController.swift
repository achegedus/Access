//
//  ContactDetailViewController.swift
//  Access
//
//  Created by Adam Hegedus on 11/7/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit

class ContactDetailViewController: UIViewController {
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var cityStateLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var homeLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func callButtonWasPressed(_ sender: Any) {
    }

    @IBAction func emailButtonWasPressed(_ sender: Any) {
    }
    
    @IBAction func closeButtonWasPressed(_ sender: Any) {
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
