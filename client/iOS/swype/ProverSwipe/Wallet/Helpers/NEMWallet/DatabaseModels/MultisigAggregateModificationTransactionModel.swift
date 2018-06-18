//
//  MultisigAggregateModificationTransactionModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import SwiftyJSON

/**
    Represents a multisig aggregate modification transaction on the NEM blockchain.
    Visit the [documentation](http://bob.nem.ninja/docs/#multisigAggregateModificationTransaction)
    for more information.
 */
open class MultisigAggregateModificationTransaction: Transaction {
    
    // MARK: - Model Properties
    
    /// The type of the transaction.
    open var type = TransactionType.multisigAggregateModificationTransaction
    
    /// Additional information about the transaction.
    open var metaData: TransactionMetaData?
    
    /// The version of the transaction.
    open var version: Int!
    
    /// The number of seconds elapsed since the creation of the nemesis block.
    open var timeStamp: Int!
    
    /// The fee for the transaction.
    open var fee: Int!
    
    /// The array of multisig modifications.
    open var modifications = [MultisigCosignatoryModification]()
    
    /// Value indicating the relative change of the minimum cosignatories.
    open var relativeChange: Int!
    
    /// The deadline of the transaction.
    open var deadline: Int!
    
    /// The transaction signature.
    open var signature: String!
    
    /// The public key of the account that created the transaction.
    open var signer: String!
    
    // MARK: - Model Lifecycle
    
    required public init?(version: Int, timeStamp: Int, fee: Int, relativeChange: Int, deadline: Int, signer: String) {
        
        self.version = version
        self.timeStamp = timeStamp
        self.fee = fee
        self.relativeChange = relativeChange
        self.deadline = deadline
        self.signer = signer
    }
    
    required public init?(jsonData: JSON) {
        
        metaData = try? jsonData["meta"].mapObject(TransactionMetaData.self)
        version = jsonData["transaction"]["version"].intValue
        timeStamp = jsonData["transaction"]["timeStamp"].intValue
        fee = jsonData["transaction"]["fee"].intValue
        deadline = jsonData["transaction"]["deadline"].intValue
        signature = jsonData["transaction"]["signature"].stringValue
        signer = jsonData["transaction"]["signer"].stringValue
        modifications = try! jsonData["transaction"]["modifications"].mapArray(MultisigCosignatoryModification.self)
    }
    
    // MARK: - Model Helper Methods
    
    public func addModification(_ modificationType: ModificationType, cosignatoryAccount: String) {
        
        let modification = MultisigCosignatoryModification(modificationType: modificationType, cosignatoryAccount: cosignatoryAccount)
        
        self.modifications.append(modification!)
    }
}
