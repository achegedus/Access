//
//  ChatTableViewController.swift
//  Access
//
//  Created by Adam Hegedus on 10/17/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ChatTableViewController: UITableViewController {

    let ref = FIRDatabase.database().reference(fromURL: "https://energycap-access.firebaseio.com/")
    
    var chats:[FIRDataSnapshot] = []
    var selectedUser:FIRDataSnapshot? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    
        ref.observe(.childAdded, with: { (snapshot) -> Void in
            self.chats.append(snapshot)
            self.tableView.insertRows(at: [IndexPath(row: self.chats.count - 1, section: 0)], with: UITableViewRowAnimation.automatic)
        })
        
        ref.observe(.childRemoved, with: { (snapshot) -> Void in
            let index = self.index(ofAccessibilityElement: snapshot)
            self.chats.remove(at: index)
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
        })
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
        return chats.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        selectedUser = chats[indexPath.row]
        
        performSegue(withIdentifier: "ChatWindowSegue", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChatWindowSegue"
        {
            print("YYYYYY - selectedUser: \(selectedUser?.key)")
            
            if let destinationVC = segue.destination as? ChatViewController {
                destinationVC.username = (selectedUser?.key)!
            }
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell") as! ChatTableViewCell
        
        let user:String = chats[indexPath.row].key
        
        cell.chatLabel?.text = user.replacingOccurrences(of: "_", with: " ")
        
        return cell
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
