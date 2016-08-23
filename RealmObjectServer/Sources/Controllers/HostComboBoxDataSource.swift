//
//  HostComboBoxDataSource.swift
//  RealmSyncServer
//
//  Created by Marius Rackwitz on 20.7.16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import AppKit

class HostComboBoxDataSource : NSObject, NSComboBoxDataSource {

    var addresses: [String] = []

    override init() {
        super.init()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.addresses = NSHost.currentHost().addresses
        }
    }

    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return addresses.count + 2
    }

    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        if index == 0 {
            return "0.0.0.0"
        } else if index == 1 {
            return "::"
        }
        return addresses[index-2]
    }

}
