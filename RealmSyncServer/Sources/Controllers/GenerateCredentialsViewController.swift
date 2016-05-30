//
//  GenerateCredentialsViewController.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/28/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Cocoa

private struct DefaultValues {
    static let passphrase = "OutOfThePark"
    static let appBundleID = "io.realm.Example"
    static let uploadAllowed = true
    static let downloadAllowed = true
}

private struct DefaultsKeys {
    static let passphrase = "CredentialsPassphrase"
    static let appBundleID = "CredentialsAppBundleID"
    static let uploadAllowed = "CredentialsUploadAllowed"
    static let downloadAllowed = "CredentialsDownloadAllowed"
}

class GenerateCredentialsViewController: NSViewController {
    
    @IBOutlet weak var passphraseTextField: NSTextField!
    @IBOutlet weak var appBundleIDTextField: NSTextField!
    @IBOutlet weak var allowUploadCheckbox: NSButton!
    @IBOutlet weak var allowDownloadCheckbox: NSButton!
    
    var passphrase: String {
        return NSUserDefaults.standardUserDefaults().stringForKey(DefaultsKeys.passphrase) ?? DefaultValues.passphrase
    }
    
    var appBundleID: String {
        return NSUserDefaults.standardUserDefaults().stringForKey(DefaultsKeys.appBundleID) ?? DefaultValues.appBundleID
    }
    
    var accessRights: CredentialsAccessRights {
        var accessRights: CredentialsAccessRights = []
        
        if NSUserDefaults.standardUserDefaults().boolForKey(DefaultsKeys.uploadAllowed) {
            accessRights.insert(.Upload)
        }
        
        if NSUserDefaults.standardUserDefaults().boolForKey(DefaultsKeys.downloadAllowed) {
            accessRights.insert(.Download)
        }
        
        return accessRights
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey(DefaultsKeys.uploadAllowed) == nil {
            userDefaults.setBool(DefaultValues.uploadAllowed, forKey: DefaultsKeys.uploadAllowed)
        }
        
        if userDefaults.objectForKey(DefaultsKeys.downloadAllowed) == nil {
            userDefaults.setBool(DefaultValues.downloadAllowed, forKey: DefaultsKeys.downloadAllowed)
        }
        
        passphraseTextField.bind(NSValueBinding, toStandardUserDefaultsKey: DefaultsKeys.passphrase, options: [NSNullPlaceholderBindingOption: DefaultValues.passphrase])
        appBundleIDTextField.bind(NSValueBinding, toStandardUserDefaultsKey: DefaultsKeys.appBundleID, options: [NSNullPlaceholderBindingOption: DefaultValues.appBundleID])
        allowUploadCheckbox.bind(NSValueBinding, toStandardUserDefaultsKey: DefaultsKeys.uploadAllowed)
        allowDownloadCheckbox.bind(NSValueBinding, toStandardUserDefaultsKey: DefaultsKeys.downloadAllowed)
    }
    
    private func generateCredentialsAtURL(url: NSURL) {
        let credentialsGenerator = CredentialsGenerator(passphrase: passphrase, appID: appBundleID, accessRights: accessRights)
        
        do {
            try credentialsGenerator.generateCredentialsAtURL(url)
            
            NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([url])
        } catch let error as NSError {
            NSAlert(error: error).beginSheetModalForWindow(view.window!, completionHandler: nil)
        }
    }
    
}

extension GenerateCredentialsViewController {
    
    @IBAction func generateCredentials(sender: AnyObject?) {
        let savePanel = NSOpenPanel()
        
        savePanel.message = "Select destination directory for the authentication files"
        savePanel.prompt = "Generate"
        savePanel.canChooseDirectories = true
        savePanel.canCreateDirectories = true
        savePanel.canChooseFiles = false
        
        savePanel.beginSheetModalForWindow(view.window!) { result in
            if let url = savePanel.URL where result == NSFileHandlingPanelOKButton {
                dispatch_async(dispatch_get_main_queue()) {
                    self.generateCredentialsAtURL(url)
                }
            }
        }
    }
    
}
