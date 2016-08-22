//
//  ManageCredentialsViewController.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 01/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Cocoa

class ManageCredentialsViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    
    private let addCredentialsSegment = 0
    private let removeCredentialsSegment = 1
    
    private let credentialsStore = CredentialsStore(userDefaultsKey: "Credentials")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
    }
    
    private func updateUI() {
        tableView.reloadData()
        
        segmentedControl.setEnabled(tableView.numberOfSelectedRows > 0, forSegment: removeCredentialsSegment)
    }
    
}

extension ManageCredentialsViewController {
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if let viewController = segue.destinationController as? GenerateCredentialsViewController {
            viewController.delegate = self
        }
    }
    
}

extension ManageCredentialsViewController {
    
    @IBAction func addOrRemoveCredentials(sender: NSSegmentedControl) {
        if sender.selectedSegment == addCredentialsSegment {
            performSegueWithIdentifier("GenerateCredentials", sender: sender)
        } else {
            let indexes = NSMutableIndexSet(indexSet:tableView.selectedRowIndexes)
            
            while indexes.count > 0 {
                credentialsStore.removeCredentialsAtIndex(indexes.firstIndex)
                indexes.removeIndex(indexes.firstIndex)
                indexes.shiftIndexesStartingAtIndex(0, by: -1)
            }
            
            updateUI()
        }
    }
    
}

extension ManageCredentialsViewController: NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return credentialsStore.numberOfCredentials
    }
    
}

extension ManageCredentialsViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("CredentialsCell", owner: self) as! CredentialsCellView
        
        cell.configureWithCredentials(credentialsStore.credentialsAtIndex(row)!)
        
        return cell
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        segmentedControl.setEnabled(tableView.numberOfSelectedRows > 0, forSegment: removeCredentialsSegment)
    }
    
}

extension ManageCredentialsViewController: GenerateCredentialsViewControllerDelegate {
    
    func generateCredentialsViewController(viewController: GenerateCredentialsViewController, didGenerateCredentials credentials: Credentials) {
        credentialsStore.addCredentials(credentials)
        
        updateUI()
    }
    
}
