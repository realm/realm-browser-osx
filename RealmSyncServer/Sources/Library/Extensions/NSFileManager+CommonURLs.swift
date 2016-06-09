//
//  NSFileManager+CommonURLs.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/26/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation

extension NSFileManager {
    
    func URLForApplicationDataDirectory(directoryName: String = NSBundle.mainBundle().bundleIdentifier!) -> NSURL {
        let applicationSupportDirectoryURL = URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).first!
        
        return applicationSupportDirectoryURL.URLByAppendingPathComponent(directoryName)
    }
    
}
