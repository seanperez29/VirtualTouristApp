//
//  CoreDataStack.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 9/8/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//

import Foundation
import CoreData

// MARK:  - TypeAliases
typealias BatchTask = (workerContext: NSManagedObjectContext) -> ()

// MARK:  - Notifications
enum CoreDataStackNotifications : String {
    case ImportingTaskDidFinish = "ImportingTaskDidFinish"
}
// MARK:  - Main
struct CoreDataStack {
    // MARK:  - Properties
    private let model: NSManagedObjectModel
    private let coordinator: NSPersistentStoreCoordinator
    private let modelURL: NSURL
    private let dbURL: NSURL
    private let persistingContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    let context: NSManagedObjectContext
    
    // MARK:  - Initializers
    init?(modelName: String) {
        guard let modelURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd") else {
            print("Unable to find \(modelName)in the main bundle")
            return nil}
        self.modelURL = modelURL
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            print("unable to create a model from \(modelURL)")
            return nil
        }
        self.model = model
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        persistingContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        persistingContext.name = "Persisting"
        persistingContext.persistentStoreCoordinator = coordinator
        context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.parentContext = persistingContext
        context.name = "Main"
        backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        backgroundContext.parentContext = context
        backgroundContext.name = "Background"
        let fm = NSFileManager.defaultManager()
        guard let  docUrl = fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first else{
            print("Unable to reach the documents folder")
            return nil
        }
        self.dbURL = docUrl.URLByAppendingPathComponent("model.sqlite")
        do {
            try addStoreTo(coordinator: coordinator,
                           storeType: NSSQLiteStoreType,
                           configuration: nil,
                           storeURL: dbURL,
                           options: nil)
        } catch {
            print("unable to add store at \(dbURL)")
        }
    }
    
    func addStoreTo(coordinator coord : NSPersistentStoreCoordinator,
                                storeType: String,
                                configuration: String?,
                                storeURL: NSURL,
                                options : [NSObject : AnyObject]?) throws{
        try coord.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: dbURL, options: nil)
    }
}

// MARK:  - Removing data
extension CoreDataStack {
    
    func dropAllData() throws {
        try coordinator.destroyPersistentStoreAtURL(dbURL, withType:NSSQLiteStoreType , options: nil)
        try addStoreTo(coordinator: self.coordinator, storeType: NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

// MARK:  - Batch processing in the background
extension CoreDataStack {
    
    func performBackgroundBatchOperation(batch: BatchTask){
        backgroundContext.performBlock(){
            batch(workerContext: self.backgroundContext)
            do{
                try self.backgroundContext.save()
            }catch{
                fatalError("Error while saving backgroundContext: \(error)")
            }
        }
    }
}

// MARK:  - Heavy processing in the background.
// Use this if importing a gazillion objects.
extension CoreDataStack {
    
    func performBackgroundImportingBatchOperation(batch: BatchTask) {
        let tmpCoord = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        do {
            try addStoreTo(coordinator: tmpCoord, storeType: NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
        } catch {
            fatalError("Error adding a SQLite Store: \(error)")
        }
        let moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        moc.name = "Importer"
        moc.persistentStoreCoordinator = tmpCoord
        moc.performBlock(){
            batch(workerContext: moc)
            do {
                try moc.save()
            } catch {
                fatalError("Error saving importer moc: \(moc)")
            }
            let nc = NSNotificationCenter.defaultCenter()
            let n = NSNotification(name: CoreDataStackNotifications.ImportingTaskDidFinish.rawValue,
                object: nil)
            nc.postNotification(n)
        }
    }
}

// MARK:  - Save
extension CoreDataStack {
    
    func save() {
        context.performBlockAndWait(){
            if self.context.hasChanges{
                do {
                    try self.context.save()
                } catch {
                    fatalError("Error while saving main context: \(error)")
                }
                self.persistingContext.performBlock(){
                    do{
                        try self.persistingContext.save()
                    }catch{
                        fatalError("Error while saving persisting context: \(error)")
                    }
                }
            }
        }
    }
    
    func autoSave(delayInSeconds : Int){
        if delayInSeconds > 0 {
            print("Autosaving")
            save()
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInNanoSeconds))
            
            dispatch_after(time, dispatch_get_main_queue(), {
                self.autoSave(delayInSeconds)
            })
        }
    }
    
    static func sharedInstance() -> CoreDataStack {
        struct Static {
            static let instance = CoreDataStack(modelName: "Model")
        }
        return Static.instance!
    }
}