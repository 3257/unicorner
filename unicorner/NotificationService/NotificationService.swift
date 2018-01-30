//
//  NotificationService.swift
//  NotificationService
//
//  Created by Deyan Aleksandrov on 1/30/18.
//  Copyright © 2018 centroida. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent, // 1. make sure bestAttemptContent is not nil
            let apsData = bestAttemptContent.userInfo["aps"] as? [String: Any], // 2. dig in the payload to get the
            let attachmentURLAsString = apsData["attachment-url"] as? String, // 3. the attachment-url
            let attachmentURL = URL(string: attachmentURLAsString) else { // 4. and parse it to URL object
                return
        }

        do {
            let imageData = try Data(contentsOf: attachmentURL) // 5. Try converting to imageData
            if let attachment = saveImageDataToDisk(imageFileIdentifier: "image.jpg", data: imageData) {
                bestAttemptContent.attachments = [attachment]
            }
        } catch {
            print("Image data not initialized properly")
        }
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}


// MARK: - Helper Functions
extension NotificationService {
    func saveImageDataToDisk(imageFileIdentifier: String, data: Data) -> UNNotificationAttachment? {

        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let fileURLPath = URL(fileURLWithPath: NSTemporaryDirectory())
        let tmpSubFolderURL = fileURLPath.appendingPathComponent(tmpSubFolderName, isDirectory: true)
        let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)

        do {
            try FileManager.default.createDirectory(at: tmpSubFolderURL,
                                            withIntermediateDirectories: true,
                                            attributes: nil)

            try data.write(to: fileURL, options: [])
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier,
                                                                    url: fileURL,
                                                                    options: nil)
            return imageAttachment
        } catch let error {
            print("error \(error)")
        }
        return nil
    }
}
