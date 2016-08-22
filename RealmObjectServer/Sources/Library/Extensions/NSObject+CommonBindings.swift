//
//  NSObject+CommonBindings.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/30/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation
import Cocoa

extension NSObject {
    
    func bind(binding: String, toStandardUserDefaultsKey key: String, options: [String : AnyObject]? = nil) {
        bind(binding, toObject: NSUserDefaultsController.sharedUserDefaultsController(), withKeyPath: "values.\(key)", options: options)
    }
    
}
