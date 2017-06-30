//
//  AppDelegate.swift
//  ExportImportDemo
//
//  Created by Rene Skov on 30/06/2017.
//  Copyright © 2017 Simpelapps. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate,NSWindowDelegate {

     lazy var coreDataManager = CoreDataManager()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
        CoreDataManager().saveContext()
    }
    
    func applicationDidHide(_ aNotification: Notification) {
        
        CoreDataManager().saveContext()
    }

    @IBAction func saveContex(_ sender:AnyObject) {
        
        do {
            // save the data
            CoreDataManager().saveContext()
            
            //refresh the table with the updated data
            
        }
        
    }

}

