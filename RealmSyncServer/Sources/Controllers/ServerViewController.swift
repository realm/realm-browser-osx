//
//  ServerViewController.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/25/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Cocoa

class ServerViewController: NSViewController {
    
    @IBOutlet weak var hostTextField: NSTextField!
    @IBOutlet weak var portTextField: NSTextField!
    
    @IBOutlet weak var realmDirectoryPathTextField: NSTextField!
    @IBOutlet weak var selectRealmDirectoryPathButton: NSButton!
    
    @IBOutlet weak var publicKeyPathTextField: NSTextField!
    @IBOutlet weak var selectPublicKeyPathButton: NSButton!
    
    @IBOutlet weak var logLevelPopUpButton: NSPopUpButton!
    
    @IBOutlet weak var startServerButton: NSButton!
    @IBOutlet weak var stopServerButton: NSButton!
    
    @IBOutlet var logOutputTextView: NSTextView!
    
    let defaultHost = "127.0.0.1"
    let defaultPort = 7800
    let defaultRealmDirectoryPath = NSFileManager.defaultManager().URLForApplicationDataDirectory().path!
    let defaultLogLevel: SyncServerLogLevel = .Normal
    
    var host: String {
        return hostTextField.stringValue.characters.count > 0 ? hostTextField.stringValue : defaultHost
    }
    
    var port: Int {
        return portTextField.stringValue.characters.count > 0 ? portTextField.integerValue : defaultPort
    }
    
    var realmDirectoryPath: String {
        return realmDirectoryPathTextField.stringValue.characters.count > 0 ? realmDirectoryPathTextField.stringValue : defaultRealmDirectoryPath
    }
    
    var publicKeyPath: String? {
        return publicKeyPathTextField.stringValue.characters.count > 0 ? publicKeyPathTextField.stringValue : nil
    }
    
    var logLevel: SyncServerLogLevel {
        return SyncServerLogLevel(rawValue: logLevelPopUpButton.indexOfSelectedItem) ?? defaultLogLevel
    }
    
    let server = SyncServer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        hostTextField.placeholderString = defaultHost
        portTextField.placeholderString = String(defaultPort)
        realmDirectoryPathTextField.placeholderString = defaultRealmDirectoryPath
        publicKeyPathTextField.placeholderString = "(Optional)"
        logLevelPopUpButton.selectItemAtIndex(defaultLogLevel.rawValue)
        
        logOutputTextView.font = NSFont(name: "Menlo", size: 11)
        logOutputTextView.textContainerInset = NSSize(width: 4, height: 6)
        logOutputTextView.delegate = self
        
        server.delegate = self
        
        updateUI()
    }
    
    private func updateUI() {
        for control in [hostTextField, portTextField, realmDirectoryPathTextField, selectRealmDirectoryPathButton, publicKeyPathTextField, selectPublicKeyPathButton, logLevelPopUpButton] {
            control.enabled = !server.running
        }
        
        startServerButton.enabled = !server.running
        stopServerButton.enabled = server.running
    }
    
    private func outputLog(message: String) {
        logOutputTextView.string = logOutputTextView.string?.stringByAppendingString(message)
        logOutputTextView.scrollToEndOfDocument(nil)
    }

}

extension ServerViewController {
    
    @IBAction func selectRealmDirectoryPath(sender: AnyObject?) {
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.message = "Select a directory where Realm files will be stored"
        openPanel.prompt = "Select"
        
        openPanel.beginSheetModalForWindow(view.window!) { result in
            if let path = openPanel.URL?.path where result == NSFileHandlingPanelOKButton {
                self.realmDirectoryPathTextField.stringValue = path
            }
        }
    }
    
    @IBAction func selectPublicKeyPath(sender: AnyObject?) {
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["pem"]
        openPanel.canChooseDirectories = false
        openPanel.message = "Select a public key file"
        openPanel.prompt = "Select"
        
        openPanel.beginSheetModalForWindow(view.window!) { result in
            if let path = openPanel.URL?.path where result == NSFileHandlingPanelOKButton {
                self.publicKeyPathTextField.stringValue = path
            }
        }
    }
    
    @IBAction func startServer(sender: AnyObject?) {
        clearLog()
        
        server.host = host
        server.port = port
        server.realmDirectoryPath = realmDirectoryPath
        server.publicKeyPath = publicKeyPath
        server.logLevel = logLevel
        
        do {
            try server.start()
        } catch let error as NSError {
            NSAlert(error: error).runModal()
        }
        
        updateUI()
    }
    
    @IBAction func stopServer(sender: AnyObject?) {
        server.stop()
        updateUI()
    }
    
    @IBAction func clearLog(sender: AnyObject? = nil) {
        logOutputTextView.string = ""
    }
    
}

extension ServerViewController: SyncServerDelegate {
    
    func serverDidStop(server: SyncServer) {
        updateUI()
    }
    
    func serverDidOutputLog(server: SyncServer, message: String) {
        outputLog(message)
    }
    
}

extension ServerViewController: NSTextViewDelegate {
    
    func textView(view: NSTextView, menu: NSMenu, forEvent event: NSEvent, atIndex charIndex: Int) -> NSMenu? {
        menu.insertItem(NSMenuItem.separatorItem(), atIndex: 0)
        menu.insertItem(NSMenuItem(title: "Clear log", action: #selector(clearLog), keyEquivalent: ""), atIndex: 0)
        
        return menu
    }
    
}
