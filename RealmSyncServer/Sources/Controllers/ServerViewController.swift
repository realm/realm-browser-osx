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
    
    @IBOutlet weak var startServerButton: NSButton!
    @IBOutlet weak var stopServerButton: NSButton!
    
    @IBOutlet weak var logOutputTextView: NSTextField!
    
    let defaultHost = "127.0.0.1"
    let defaultPort = 7800
    let defaultRealmDirectoryPath = NSFileManager.defaultManager().URLForApplicationDataDirectory().path!
    
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
    
    let server = SyncServer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        hostTextField.placeholderString = defaultHost
        portTextField.placeholderString = String(defaultPort)
        realmDirectoryPathTextField.placeholderString = defaultRealmDirectoryPath
        publicKeyPathTextField.placeholderString = "(Optional)"
        
        server.delegate = self
        
        updateUI()
    }
    
    private func updateUI() {
        for control in [hostTextField, portTextField, realmDirectoryPathTextField, selectRealmDirectoryPathButton, publicKeyPathTextField, selectPublicKeyPathButton] {
            control.enabled = !server.running
        }
        
        startServerButton.enabled = !server.running
        stopServerButton.enabled = server.running
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
        logOutputTextView.stringValue = ""
        
        server.host = host
        server.port = port
        server.realmDirectoryPath = realmDirectoryPath
        server.publicKeyPath = publicKeyPath
        
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
    
}

extension ServerViewController: SyncServerDelegate {
    
    func serverDidStop(server: SyncServer) {
        updateUI()
    }
    
    func serverDidOutputLog(server: SyncServer, message: String) {
        logOutputTextView.stringValue = logOutputTextView.stringValue.stringByAppendingString(message)
    }
    
}
