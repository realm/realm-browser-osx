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
        
        handleCommandLineArguments(NSProcessInfo.processInfo().arguments)
    }
    
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindow?.makeKeyAndOrderFront(self)
        
        return true
    }
    
    func application(application: NSApplication, willPresentError error: NSError) -> NSError {
        NSLog("%@: %@", error.localizedDescription, error.localizedRecoverySuggestion ?? "")
        
        return error
    }

}

extension AppDelegate {
    
    private func handleCommandLineArguments(arguments: [String]) {
        guard let serverViewController = mainWindow?.contentViewController as? ServerViewController else {
            NSLog("Unnable to handle command line arguments: bad window content view controller")
            
            return
        }
        
        if arguments.contains("-start") {
            serverViewController.startStopServer(nil)
            
            guard serverViewController.server.running else {
                exit(1)
            }
        }
    }
    
}
