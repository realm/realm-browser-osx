//
//  Credentials.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 01/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation

struct CredentialsAccessRights: OptionSetType {

    let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    static let Upload = CredentialsAccessRights(rawValue: 1 << 0)
    static let Download = CredentialsAccessRights(rawValue: 1 << 1)

}

class Credentials: NSObject, NSCoding {

    var identity: String
    var appID: String
    var accessRights: CredentialsAccessRights
    var token: String
    
    init(identity: String, appID: String, accessRights: CredentialsAccessRights, token: String) {
        self.identity = identity
        self.appID = appID
        self.accessRights = accessRights
        self.token = token
    }
    
    // MARK: NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        guard
            let identity = aDecoder.decodeObjectForKey("identity") as? String,
            let appID = aDecoder.decodeObjectForKey("appID") as? String,
            let rawAccessRights = aDecoder.decodeObjectForKey("accessRights") as? Int,
            let token = aDecoder.decodeObjectForKey("token") as? String
        else {
            return nil
        }
        
        self.identity = identity
        self.appID = appID
        self.accessRights = CredentialsAccessRights(rawValue: rawAccessRights)
        self.token = token
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(identity, forKey: "identity")
        aCoder.encodeObject(appID, forKey: "appID")
        aCoder.encodeObject(accessRights.rawValue, forKey: "accessRights")
        aCoder.encodeObject(token, forKey: "token")
    }

}
