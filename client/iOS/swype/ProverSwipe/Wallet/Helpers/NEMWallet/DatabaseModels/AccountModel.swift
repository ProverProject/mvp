//
//  AccountModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import CoreData

/// Represents an account object.
open class Account: NSManagedObject {
    
    // MARK: - Model Properties
    
    /// The title of the account.
    @NSManaged var title: String
    
    /// The address of the account.
    @NSManaged var address: String
    
    /// The public key of the account.
    @NSManaged var publicKey: String
    
    /// The encrypted private key of the account.
    @NSManaged var privateKey: String
    
    /// The position of the account in the accounts list.
    @NSManaged var position: NSNumber
    
    /// The hash of the latest transaction for the account.
    @NSManaged var latestTransactionHash: String
}
