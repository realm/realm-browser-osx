//
//  GenerateCredentialsViewController.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/28/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Cocoa

protocol GenerateCredentialsViewControllerDelegate: class {
    
    func generateCredentialsViewController(viewController: GenerateCredentialsViewController, didGenerateCredentials credentials: Credentials)
    
}

private struct DefaultValues {
    
    static let appBundleID = "io.realm.Example"
    static let uploadAllowed = true
    static let downloadAllowed = true
    
}

class GenerateCredentialsViewController: NSViewController {
    
    @IBOutlet weak var identityTextField: NSTextField!
    @IBOutlet weak var appBundleIDTextField: NSTextField!
    @IBOutlet weak var allowUploadCheckbox: NSButton!
    @IBOutlet weak var allowDownloadCheckbox: NSButton!
    @IBOutlet var tokenTextView: NSTextView!
    @IBOutlet weak var saveButton: NSButton!
    
    weak var delegate: GenerateCredentialsViewControllerDelegate?
    
    private let tokenGenerator = TokenGenerator(privateKeyURL: NSBundle.mainBundle().URLForResource("private", withExtension: "pem")!)!
    
    private var identity: String {
        return identityTextField.stringValue
    }
    
    private var appBundleID: String {
        return appBundleIDTextField.stringValue.characters.count > 0 ? appBundleIDTextField.stringValue : DefaultValues.appBundleID
    }
    
    private var accessRights: CredentialsAccessRights {
        var accessRights: CredentialsAccessRights = []
        
        if allowUploadCheckbox.state == NSOnState {
            accessRights.insert(.Upload)
        }
        
        if allowDownloadCheckbox.state == NSOnState {
            accessRights.insert(.Download)
        }
        
        return accessRights
    }
    
    private var token: String {
        return tokenTextView.string ?? ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        appBundleIDTextField.placeholderString = DefaultValues.appBundleID
        allowUploadCheckbox.state = DefaultValues.uploadAllowed ? NSOnState : NSOffState
        allowDownloadCheckbox.state = DefaultValues.downloadAllowed ? NSOnState : NSOffState
        
        tokenTextView.font = NSFont(name: "Menlo", size: 12)
        
        updateUI()
    }
    
    private func updateUI() {
        saveButton.enabled = token.characters.count > 0
    }
    
    private func updateToken() {
        tokenTextView.string = ""
        
        let manifest = CredentialsManifest(identity: identity, appID: appBundleID, access: accessRights)
        
        if manifest.valid {
            do {
                tokenTextView.string = try tokenGenerator.generateTokenForJSONObject(manifest)
            } catch let error as NSError {
                NSAlert(error: error).runModal()
            }
        }
        
        updateUI()
    }
    
}

extension GenerateCredentialsViewController {
    
    @IBAction func updateAccessRights(sender: AnyObject?) {
        updateToken()
    }
    
    @IBAction func saveCredentials(sender: AnyObject?) {
        if let delegate = delegate {
            let credentials = Credentials(identity: identity, appID: appBundleID, accessRights: accessRights, token: token)
            delegate.generateCredentialsViewController(self, didGenerateCredentials: credentials)
        }
        
        dismissController(sender)
    }
    
}

extension GenerateCredentialsViewController: NSTextFieldDelegate {
    
    override func controlTextDidChange(obj: NSNotification) {
        updateToken()
    }
    
}
