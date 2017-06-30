//
//  ViewController.swift
//  ExportImportDemo
//
//  Created by Rene Skov on 30/06/2017.
//  Copyright © 2017 Simpelapps. All rights reserved.
//

import Cocoa
import CoreData
class ViewController: NSViewController {
    
     let managedObjectContext = CoreDataManager().managedObjectContext
    
    
     @IBOutlet weak var namesPopUpButton: NSPopUpButton!
     @IBOutlet weak var nameLbl: NSTextField!
     @IBOutlet weak var ageLbl: NSTextField!
     @IBOutlet weak var delButton: NSButton!
     @IBOutlet weak var addButton: NSButton!
    
      var friendName = ""
      var friendNames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delButton.isEnabled = false
        
        let nc = NotificationCenter.default // Note that default is now a property, not a method call
        nc.addObserver(forName:Notification.Name(rawValue:"addedName"),
                       object:nil, queue:nil,
                       using:catchNotification)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func add(_ sender: NSButton) {
        
        
        let data = Friends(context: managedObjectContext)
                
        data.name    =  nameLbl.stringValue
        data.age     =  ageLbl.stringValue
        
        
        
        do {
            try managedObjectContext.save()
        } catch let error as NSError {
            print("Save error: \(error), description: \(error.userInfo)")
        }
                
        let nc = NotificationCenter.default
        nc.post(name:Notification.Name(rawValue:"addedName"),
                object: nil,
                userInfo: nil )
        
        nameLbl.stringValue = ""
        ageLbl.stringValue = ""
    
    }
    
    // MARK: Export functions
    @IBAction func ExportToCSV(_ sender: AnyObject) {
        
        
        // Turn core data for responses into a .csv file
        
        // Pull core data in
        var CoreDataResultsList = [NSManagedObject]()
        
    
        // Pull the data from core data
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Friends")
        do {
            let results =
                try managedObjectContext.fetch(fetchRequest)
            CoreDataResultsList = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        // Take the managed object array and turn it into a .csv sring to write in the file
        // In doing this, we are writing just like we would to any string
        let csvString = writeCoreObjectsToCSV(objects: CoreDataResultsList)
        let data = csvString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)
        
        let fileName = "Friends"
        let dir = FileManager.default.urls(for: .downloadsDirectory , in: .userDomainMask).first!
        
        
        // If the directory was found, we write a file to it and read it back
        let fileURL = dir.appendingPathComponent(fileName).appendingPathExtension("csv")
        
        // Write to the file Test
        do {
            try data?.write(to: fileURL )
        } catch {
            print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
        }
        
        
    }
    
    // Takes a managed object and writes it to the .csv file ..?
    func writeCoreObjectsToCSV(objects: [NSManagedObject]) -> NSMutableString
    {
        // Make sure we have some data to export
        guard objects.count > 0 else
        {
            
            return ""
        }
        
        let coradataString = NSMutableString()
        
        
        for object in objects
        {
            // Put "\n" at the beginning so you don't have an extra row at the end
            coradataString.append("\n\(object.value(forKey: "name")!),\(object.value(forKey: "age")!)")
        }
        return coradataString
    }
    
    
    // MARK: Import functions
    @IBAction func ImportToCSV(_ sender: AnyObject) {
        
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a file"
        openPanel.begin { (result) -> Void in
            if result.rawValue == NSFileHandlingPanelOKButton {
                let fileURL = openPanel.url!
                //  print(fileURL)
                //do something with the selected file. Its url = fileURL
                do {
                    
                    // run remove all data func......
                    self.removeData()
                    
                    // add new data to core data .....
                    
                    if let items = self.parseCSV(contentsOfURL: fileURL as NSURL, encoding: String.Encoding.utf8 ) {
                        // load the core data items
                        
                        for item in items {
                            let friendsItem = NSEntityDescription.insertNewObject(forEntityName: "Friends", into: self.managedObjectContext) as! Friends
                            
                                friendsItem.name = item.name
                                friendsItem.age = item.age
                            
                            do {
                                try self.managedObjectContext.save()
                                
                                
                            } catch let saveError as NSError {
                                print("insert error: \(saveError.localizedDescription)")
                            }
                            
                        }
                        
                        let nc = NotificationCenter.default
                        nc.post(name:Notification.Name(rawValue:"addedName"),
                                object: nil,
                                userInfo: nil )
                        
                    }
                    
                }
                
            }
        }
        
    }
    
    func removeData () {
        // Remove the existing items
        
        print( " remove coredata ")
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Friends")
        
            let delete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try  self.managedObjectContext.persistentStoreCoordinator?.execute(delete, with: managedObjectContext)
            } catch let error as NSError {
                print("Error occured while deleting: \(error)")
            }
        
    }
    
    
    func parseCSV ( contentsOfURL: NSURL, encoding: String.Encoding) -> [(name:String, age: String)]? {
        // Load the CSV file and parse it
        let delimiter = ","
        
        var items:[(name:String, age: String)]?
        do {
            
            let content = try String(contentsOf:contentsOfURL as URL)
            items = []
            let lines:[String] = content.components(separatedBy: NSCharacterSet.newlines) as [String]
            
            for line in lines {
                var values:[String] = []
                if line != "" {
                    // For a line with double quotes
                    // we use NSScanner to perform the parsing
                    if line.range(of: "\"") != nil {
                        var textToScan:String = line
                        var value:NSString?
                        var textScanner:Scanner = Scanner(string: textToScan)
                        while textScanner.string != "" {
                            
                            if (textScanner.string as NSString).substring(to: 1) == "\"" {
                                textScanner.scanLocation += 1
                                textScanner.scanUpTo("\"", into: &value)
                                textScanner.scanLocation += 1
                            } else {
                                textScanner.scanUpTo(delimiter, into: &value)
                            }
                            
                            // Store the value into the values array
                            values.append(value! as String)
                            
                            // Retrieve the unscanned remainder of the string
                            if textScanner.scanLocation < (textScanner.string.count) {
                                textToScan = (textScanner.string as NSString).substring(from: textScanner.scanLocation + 1)
                            } else {
                                textToScan = ""
                            }
                            textScanner = Scanner(string: textToScan)
                        }
                        
                        // For a line without double quotes, we can simply separate the string
                        // by using the delimiter (e.g. comma)
                    } else  {
                        values = line.components(separatedBy:delimiter)
                    }
                    
                    // Put the values into the tuple and add it to the items array
                    let item = (name: values[0], age: values[1])
                    items?.append(item)
                }
                
            }
        } catch {
            print(error)
        }
        
        return items
    }

    // MARK: Delete Data Records
    
    @IBAction func deleteRecord(sender: NSButton)  {
        
        let predicate = NSPredicate(format: "name == %@", friendName)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Friends")
        fetchRequest.predicate = predicate
        
        let result = try? managedObjectContext.fetch(fetchRequest)
        let resultData = result as! [Friends]
        
        for object in resultData {
            managedObjectContext.delete(object)
        }
        
        do {
            try managedObjectContext.save()
            print("saved!")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {
            
        }
        let nc = NotificationCenter.default
        nc.post(name:Notification.Name(rawValue:"addedName"),
                object: nil,
                userInfo: nil )
        
        
    }
    
    @IBAction func myPopUpButton(sender: AnyObject) {
        
        friendName = (namesPopUpButton.selectedItem?.title)!
        
        if friendName != "" {
            
            delButton.isEnabled = true
        }
        
    }
    
    func catchNotification(notification:Notification) -> Void {
        print("Catch notification")
        
        self.opdateArray()
        
    }
    
    func opdateArray(){
        // Setup the pop up button with names from coredata
        friendNames = []
        
        let request: NSFetchRequest<Friends>
        
            request = Friends.fetchRequest()
        
        do {
            let results = try managedObjectContext.fetch(request)
            for task in results {
                
                let names =  task.name
                
                friendNames.append(names!)
                
                
            }
            
            namesPopUpButton.removeAllItems()
            namesPopUpButton.addItems(withTitles: friendNames)
            namesPopUpButton.selectItem(at: 0)
            
        } catch let error {
            print(error.localizedDescription)
        }
        
    }
}

