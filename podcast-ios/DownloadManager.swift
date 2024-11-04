//
//  DownloadManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 02..
//

import Alamofire
import Foundation
import CoreData

final class DownloadManager: Sendable {
    static let shared = DownloadManager()

    @DownloadManagerActor
    func downloadAudio(item: (any PlayableItemProtocol)?) {
        guard let item else {
            PODLogError("Failed: There is no item to download")
            return
        }
        guard let streamURL = item.streamURL else {
            PODLogError("Failed: Item does not have content to download")
            return
        }
        
        // Generate a unique identifier for the file (use UUID to ensure no special characters)
        let uniqueID = UUID().uuidString
        let fileExtension = streamURL.pathExtension.isEmpty ? "mp3" : streamURL.pathExtension
        
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            // Set the filename to be unique by using the UUID and append the correct file extension
            let fileURL = documentsURL.appendingPathComponent("\(uniqueID).\(fileExtension)")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        AF.download(streamURL, to: destination).response { [weak self] response in
            guard let self else { return }
            if response.error == nil, let filePath = response.fileURL?.path {
                // Save using the unique identifier and item title as metadata
                self.saveDownloadedFile(fileName: uniqueID, filePath: filePath, url: streamURL.absoluteString, title: item.title)
            } else {
                PODLogError("Download failed for item: \(item.title)")
            }
        }
    }

    nonisolated func saveDownloadedFile(fileName: String, filePath: String, url: String, title: String) {
        let context = CoreDataStack.shared.context
        let file = Audio(context: context)
        file.id = UUID()
        file.filePath = filePath
        file.url = url
        file.date = Date()
        file.title = title  // Store the original title as metadata for display
        do {
            try context.save()
            PODLogInfo("Successfully saved downloaded file with ID: \(fileName)")
        } catch {
            PODLogError("Failed to save downloaded file: \(error)")
        }
    }
    
    @globalActor final actor DownloadManagerActor: Sendable {
        static let shared = DownloadManagerActor()
    }
}

extension DownloadManager {
    @DownloadManagerActor
    func printAllDownloadedFiles() {
        let downloadedFiles = fetchDownloadedFiles()
        for file in downloadedFiles {
            PODLogInfo("Downloaded file: \(file.title ?? "Unknown title"), Path: \(file.filePath ?? "Unknown path")")
        }
    }

    @DownloadManagerActor
    func fetchDownloadedFiles() -> [Audio] {
        let context = CoreDataStack.shared.context
        let fetchRequest: NSFetchRequest<Audio> = Audio.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            PODLogError("Failed to fetch downloaded files: \(error)")
            return []
        }
    }

    @DownloadManagerActor
    func fetchDownloadedFile(withTitle title: String) -> Audio? {
        let context = CoreDataStack.shared.context
        let fetchRequest: NSFetchRequest<Audio> = Audio.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        fetchRequest.fetchLimit = 1

        do {
            return try context.fetch(fetchRequest).first
        } catch {
            PODLogError("Failed to fetch file with title \(title): \(error)")
            return nil
        }
    }

    func deleteAllRecords() {
        let context = CoreDataStack.shared.context
        let entities = ["Audio"]

        do {
            for entityName in entities {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try context.execute(batchDeleteRequest)
            }
            try context.save()
            PODLogInfo("All records deleted successfully.")
        } catch {
            PODLogError("Failed to delete records: \(error)")
        }
    }

    func deleteRecordsByCharacteristic(fileName: String? = nil, dateBefore: Date? = nil, urlContains: String? = nil) {
        let context = CoreDataStack.shared.context
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DownloadedFile")
        
        var predicates: [NSPredicate] = []
        
        if let fileName = fileName {
            predicates.append(NSPredicate(format: "fileName == %@", fileName))
        }
        
        if let dateBefore = dateBefore {
            predicates.append(NSPredicate(format: "date < %@", dateBefore as NSDate))
        }
        
        if let urlContains = urlContains {
            predicates.append(NSPredicate(format: "url CONTAINS[cd] %@", urlContains))
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            try context.save()
            PODLogInfo("Records matching the characteristics deleted successfully.")
        } catch {
            PODLogError("Failed to delete records: \(error)")
        }
    }
}
//
//func playDownloadedAudio(withTitle title: String) {
//    // Fetch the downloaded file from Core Data using its title
//    guard let audioFile = fetchDownloadedFile(withTitle: title),
//          let filePath = audioFile.filePath else {
//        PODLogError("Audio file not found for title: \(title)")
//        return
//    }
//
//    do {
//        let fileURL = URL(fileURLWithPath: filePath)
//        audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
//        audioPlayer?.prepareToPlay()
//        audioPlayer?.play()
//        PODLogInfo("Playing audio: \(title)")
//    } catch {
//        PODLogError("Failed to play audio: \(error)")
//    }
//}
