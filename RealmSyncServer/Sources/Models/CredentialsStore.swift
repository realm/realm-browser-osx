//
//  CredentialsStore.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 01/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation

class CredentialsStore {
    
    private var credentialsArray: [Credentials] = []
    private let userDefaultsKey: String
    
    init(userDefaultsKey: String) {
        self.userDefaultsKey = userDefaultsKey
        
        reloadCredentials()
    }
    
    var numberOfCredentials: Int {
        return credentialsArray.count
    }
    
    func credentialsAtIndex(index: Int) -> Credentials? {
        return credentialsArray[index]
    }
    
    func addCredentials(credentials: Credentials) {
        credentialsArray.insert(credentials, atIndex: 0)
        saveCredentials()
    }
    
    func removeCredentialsAtIndex(index: Int) {
        credentialsArray.removeAtIndex(index)
        saveCredentials()
    }
    
    func reloadCredentials() {
        if let credentialsData = NSUserDefaults.standardUserDefaults().objectForKey(userDefaultsKey) as? NSData {
            credentialsArray = NSKeyedUnarchiver.unarchiveObjectWithData(credentialsData) as? [Credentials] ?? []
        }
    }
    
    func saveCredentials() {
        let credentialsData = NSKeyedArchiver.archivedDataWithRootObject(credentialsArray)
        
        NSUserDefaults.standardUserDefaults().setObject(credentialsData, forKey: userDefaultsKey)
    }
    
}
