//
//  Audio+CoreDataProperties.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 03..
//
//

import Foundation
import CoreData

extension Audio {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Audio> {
        return NSFetchRequest<Audio>(entityName: "Audio")
    }

    @NSManaged public var title: String?
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var url: String?
    @NSManaged public var filePath: String?

}

extension Audio : Identifiable {

}
