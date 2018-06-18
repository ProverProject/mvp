//
//  MultisigSignatureTransactionModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import SwiftyJSON

/**
    Represents a multisig signature transaction on the NEM blockchain.
    Visit the [documentation](http://bob.nem.ninja/docs/#multisigSignatureTransaction)
    for more information.
 */
open class MultisigSignatureTransaction: Transaction {
    
    // MARK: - Model Properties
    
    /// The type of the transaction.
    open var type = TransactionType.multisigSignatureTransaction
    
    /// The version of the transaction.
    open var version: Int!
    
    /// The number of seconds elapsed since the creation of the nemesis block.
    open var timeStamp: Int!
    
    /// The fee for the transaction.
    open var fee: Int!
    
    /// The deadline of the transaction.
    open var deadline: Int!
    
    /// The transaction signature.
    open var signature: String!
    
    /// The public key of the account that created the transaction.
    open var signer: String!
    
    /// The length of the hash of the corresponding multisig transaction.
    open var hashObjectLength = 36
    
    /// The length of the transaction hash.
    open var hashLength = 32
    
    /// The length of the address of the corresponding multisig account.
    open var multisigAccountLength = 40
    
    /// The hash of the inner transaction of the corresponding multisig transaction.
    open var otherHash: String!
    
    /// The address of the corresponding multisig account.
    open var otherAccount: String!
    
    // MARK: - Model Lifecycle
    
    required public init?(version: Int, timeStamp: Int, fee: Int, deadline: Int, signer: String, otherHash: String, otherAccount: String) {
        
        self.version = version
        self.timeStamp = timeStamp
        self.fee = fee
        self.deadline = deadline
        self.signer = signer
        self.otherHash = otherHash
        self.otherAccount = otherAccount
    }
    
    required public init?(jsonData: JSON) {
        
        timeStamp = jsonData["timeStamp"].intValue
        fee = jsonData["fee"].intValue
        deadline = jsonData["deadline"].intValue
        signature = jsonData["signature"].stringValue
        signer = jsonData["signer"].stringValue
        otherHash = jsonData["otherHash"].stringValue
        otherAccount = jsonData["otherAccount"].stringValue
    }
}
