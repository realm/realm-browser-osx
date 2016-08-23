//
//  JSONRepresentable.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 03/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation

protocol JSONRepresentable {
    
    var JSONRepresentation: AnyObject { get }
    
}
