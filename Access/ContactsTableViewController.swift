//
//  ContactsTableViewController.swift
//  Access
//
//  Created by Adam Hegedus on 11/7/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import SimpleKeychain
import Auth0
import Alamofire
import SwiftyJSON
import CoreData
import AvatarImageView


class ContactsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var contacts : [Contact] = []
    
    lazy var context: NSManagedObjectContext! = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()
    
    
    lazy var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>! = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Contact")
        let primarySort = NSSortDescriptor(key: "department.name", ascending: true)
        
        let deptHeadSort = NSSortDescriptor(key: "isDeptHead", ascending: false)
        let lastnameSort = NSSortDescriptor(key: "last_name", ascending: true)
        
        fetchRequest.sortDescriptors = [primarySort, deptHeadSort, lastnameSort]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: "department.name", cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()self.refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 150
        
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        
        do{
            try self.fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FRC - Contacts")
        }
        
        
        self.getContacts()
        self.getData()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
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

        let contact = self.fetchedResultsController.object(at: indexPath) as! Contact
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactTableCell") as! ContactTableViewCell
        
        cell.nameLabel?.text = "\(contact.first_name!) \(contact.last_name!)"
        cell.titleLabel?.text = contact.title! as String
        
        cell.userImage.dataSource = AvatarImageData(inputName: "\(contact.first_name!) \(contact.last_name!)")
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Staff"
        backItem.tintColor = UIColor.white
        navigationItem.backBarButtonItem = backItem
        
        if let indexPath = self.tableView.indexPathForSelectedRow {
            let detail = segue.destination as! ContactDetailViewController
            let contact = self.fetchedResultsController.object(at: indexPath) as! Contact
            detail.currentContact = contact
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        getData()
        refreshControl.endRefreshing()
    }
    
    
    func getContacts() {
        
        let fetchRequest = Contact.fetchRequest() as NSFetchRequest<Contact>
        //fetchRequest.propertiesToGroupBy = ["department"]
        
        do {
            self.contacts = try self.context.fetch(fetchRequest) as [Contact]
            print(contacts)
        } catch {}
        
        self.tableView.reloadData()
    }
    
    
    
    func getData() {
        
        // data was recieved now store in core data
        let keychain = A0SimpleKeychain(service: "Auth0")
        
        let token = keychain.string(forKey: "id_token")
        
        let authHeaders : HTTPHeaders = [
            "Authorization": "Bearer \(token!)"
        ]
        
        Alamofire.request("https://accesstemp.energycap.com/api/v1/contacts", headers: authHeaders).responseJSON { response in
            if ((response.result.value) != nil) {
                let swiftyJsonVar = JSON(response.result.value!)
                
                if let resData = swiftyJsonVar.arrayObject {
                    
                    // first empty the table
                    let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Contact")
                    
                    let deleteReq = NSBatchDeleteRequest(fetchRequest: fetchReq)
                    do {
                        try self.context.execute(deleteReq)
                    } catch {
                        print("COULDN'T DELETE DATA")
                    }
                    
                    // loop through data and populate core data
                    for obj in resData as! [[String:AnyObject]] {
                        
                        debugPrint(obj)
                        let contact = Contact(context: self.context)
                        
                        let deptName = obj["department"]?["name"] as? String
                        let dept = self.fetchDepartment(name: deptName!)
                        
                        contact.department = dept
                        
                        if let first_name = obj["first_name"] as? String {
                            contact.first_name = first_name
                        } else {
                            contact.first_name = ""
                        }
                        
                        if let last_name = obj["last_name"] as? String {
                            contact.last_name = last_name
                        } else {
                            contact.last_name = ""
                        }
                        
                        if let email = obj["email"] as? String {
                            contact.email = email
                        } else {
                            contact.email = ""
                        }
                        
                        if let address = obj["address"] as? String {
                            contact.address = address
                        } else {
                            contact.address = ""
                        }
                        
                        if let address2 = obj["address2"] as? String {
                            contact.address2 = address2
                        } else {
                            contact.address2 = ""
                        }
                        
                        if let city = obj["city"] as? String {
                            contact.city = city
                        } else {
                            contact.city = ""
                        }
                        
                        if let state = obj["state"] as? String {
                            contact.state = state
                        } else {
                            contact.state = ""
                        }
                        
                        if let zipcode = obj["zipcode"] as? String {
                            contact.zipcode = zipcode
                        } else {
                            contact.zipcode = ""
                        }
                        
                        if let title = obj["title"] as? String {
                            contact.title = title
                        } else {
                            contact.title = ""
                        }
                        
                        if let cell_number = obj["cell_number"] as? String {
                            contact.cell_number = cell_number
                        } else {
                            contact.cell_number = ""
                        }
                        
                        if let home_number = obj["home_number"] as? String {
                            contact.home_number = home_number
                        } else {
                            contact.home_number = ""
                        }
                        
                        if let contactID = obj["id"] as? Int16 {
                            contact.id = contactID
                        } else {
                            contact.id = 0
                        }
                        
                        if let isDeptHead = obj["isDeptHead"] as? Int8 {
                            if isDeptHead == 1 {
                                contact.isDeptHead = true
                            } else {
                                contact.isDeptHead = false
                            }
                        } else {
                            contact.isDeptHead = false
                        }
                        
                        (UIApplication.shared.delegate as! AppDelegate).saveContext()
                    }
                }
                
                print("Downloaded Alert Data")
                self.getContacts()
            }
        }
    }
    
    
    func fetchDepartment(name: String) -> Department?
    {
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<Department>(entityName: "Department")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let dept = try self.context.fetch(fetchRequest)
            if dept.count == 0 {
                return nil
            } else {
                return dept[0] as Department
            }
        } catch {
            print("Department search failed")
        }
        
        return nil
    }
    
}
