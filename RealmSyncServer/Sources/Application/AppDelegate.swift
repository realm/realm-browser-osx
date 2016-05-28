//
//  AppDelegate.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/25/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        mainWindow = NSApp.windows.first
    }
    
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindow?.makeKeyAndOrderFront(self)
        
        return true
    }

}
