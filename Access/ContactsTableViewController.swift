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

class ContactsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var contacts : [Contact] = []
    var context: NSManagedObjectContext!
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()self.refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 150
        
        self.getContacts()
        self.getData()
    }
    
    
    func initializeFetchedResultsController() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Contact")
        let departmentSort = NSSortDescriptor(key: "department.name", ascending: true)
        request.sortDescriptors = [departmentSort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: "department.name", cacheName: "rootCache")
        fetchedResultsController.delegate = self
        
        do{
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FRC - Contacts")
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return fetchedResultsController.sections!.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "contactTableCell") as! ContactTableViewCell
        
        cell.nameLabel?.text = contacts[indexPath.row].first_name as String!
        
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func getContacts() {
        
        let fetchRequest = Contact.fetchRequest() as NSFetchRequest<Contact>
        fetchRequest.propertiesToGroupBy = ["department"]
        
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
                        
                        if let contactID = obj["id"] as? Int16 {
                            contact.id = contactID
                        } else {
                            contact.id = 0
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
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Department> = Department.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        return try! managedContext.fetch(fetchRequest)[0]
    }
    
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
        case .delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }
    

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, indexPath: indexPath!)
        case .move:a
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
}
