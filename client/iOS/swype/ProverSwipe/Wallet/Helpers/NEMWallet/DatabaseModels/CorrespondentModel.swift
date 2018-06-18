//
//  CorrespondentModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation

/// Represents a correspondent with whom some sort of transaction was performed.
open class Correspondent {
    
    // MARK: - Model Properties
    
    /// The name of the correspondent if available.
    open var name: String?
    
    /// The account address of the correspondent.
    open var accountAddress: String!
    
    /// The public key of the correspondent.
    open var accountPublicKey: String?
    
    /// All transactions in conjunction with the correspondent.
    open var transactions = [Transaction]()
    
    /// All unconfirmed transactions in conjunction with the correspondent.
    open var unconfirmedTransactions = [Transaction]()
    
    /// The most recently performed transfer transaction.
    open var mostRecentTransaction: Transaction!
}
