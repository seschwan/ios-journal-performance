//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataImporter {
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        self.context.perform {
            let identifiers = entries.compactMap { $0.identifier }
            let existingEntries = self.fetchMultipleEntriesFromPersistentStore(with: identifiers, in: self.context)
            
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                //let entry = self.fetchSingleEntryFromPersistentStore(with: identifier, in: self.context)
                if let existingEntry = existingEntries[identifier] {
                    self.update(entry: existingEntry, with: entryRep)
                } else {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            completion(nil)
        }
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
        
        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        
        var result: Entry? = nil
        do {
            result = try context.fetch(fetchRequest).first
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    private func fetchMultipleEntriesFromPersistentStore(with identifiers: [String], in context: NSManagedObjectContext) -> [String : Entry] {
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        var result = [String : Entry]()
        
        do {
            result = try context.fetch(fetchRequest).reduce(into: [String : Entry]()) {
                guard let id = $1.identifier else { return }
                $0[id] = $1
            }
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
}
