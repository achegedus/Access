//
//  ContactDetailViewController.swift
//  Access
//
//  Created by Adam Hegedus on 11/7/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import Alamofire
import MessageUI
import AvatarImageView

import UIKit

class ContactDetailViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var cityStateLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var homeLabel: UILabel!
    @IBOutlet weak var userImage: AvatarImageView! {
        didSet {
            configureRoundAvatar()
            showInitials()
        }
    }
    
    var currentContact: Contact!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.userImage.layer.cornerRadius = self.userImage.frame.size.width/2
        //self.userImage.clipsToBounds = true
        
        self.firstNameLabel.text = self.currentContact.first_name
        self.lastNameLabel.text = self.currentContact.last_name
        self.titleLabel.text = self.currentContact.title
        self.addressLabel.text = self.currentContact.address
        self.cityStateLabel.text = self.currentContact.city! + ", " + self.currentContact.state! + " " + self.currentContact.zipcode!
        self.emailLabel.text = self.currentContact.email
        self.cellLabel.text = self.currentContact.cell_number
        self.homeLabel.text = self.currentContact.home_number
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func callButtonWasPressed(_ sender: Any) {
        guard let number = URL(string: "telprompt://" + self.currentContact.cell_number!) else { return }
        UIApplication.shared.open(number, options: [:], completionHandler: nil)
    }

    @IBAction func emailButtonWasPressed(_ sender: Any) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    @IBAction func closeButtonWasPressed(_ sender: Any) {
    }
    
    // MARK: - Mail

    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        let toAddress = self.currentContact.email
        
        mailComposerVC.setToRecipients([toAddress!])
        
        return mailComposerVC
    }
    
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: - Avatar
    
    func configureRoundAvatar() {
        struct Config: AvatarImageViewConfiguration {
            var shape: Shape = .circle
            let bgColor: UIColor? = UIColor.init(hex: "#C1CF00")
        }
        self.userImage.configuration = Config()
    }
    
    func showInitials() {
        let name = self.currentContact.first_name! + " " + self.currentContact.last_name!
        self.userImage.dataSource = AvatarImageData(inputName: name)
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
