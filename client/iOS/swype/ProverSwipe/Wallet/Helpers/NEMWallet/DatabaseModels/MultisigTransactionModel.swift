//
//  MultisigTransactionModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import SwiftyJSON

/**
    Represents a multisig transaction on the NEM blockchain.
    Visit the [documentation](http://bob.nem.ninja/docs/#multisigTransaction)
    for more information.
 */
open class MultisigTransaction: Transaction {
    
    // MARK: - Model Properties
    
    /// The type of the transaction.
    open var type = TransactionType.multisigTransaction
    
    /// Additional information about the transaction.
    open var metaData: TransactionMetaData?
    
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
    
    /// The array of MulsigSignatureTransaction objects.
    open var signatures: [MultisigSignatureTransaction]?
    
    /// The public key of the account that created the transaction.
    open var signer: String!
    
    /// The inner transaction of the multisig transaction.
    open var innerTransaction: Transaction!
    
    // MARK: - Model Lifecycle
    
    required public init?(version: Int, timeStamp: Int, fee: Int, deadline: Int, signer: String, innerTransaction: Transaction) {
        
        self.version = version
        self.timeStamp = timeStamp
        self.fee = fee
        self.deadline = deadline
        self.signer = signer
        self.innerTransaction = innerTransaction
    }
    
    required public init?(jsonData: JSON) {
        
        metaData = try! jsonData["meta"].mapObject(TransactionMetaData.self)
        timeStamp = jsonData["transaction"]["timeStamp"].intValue
        fee = jsonData["transaction"]["fee"].intValue
        deadline = jsonData["transaction"]["deadline"].intValue
        signature = jsonData["transaction"]["signature"].stringValue
        signatures = try! jsonData["transaction"]["signatures"].mapArray(MultisigSignatureTransaction.self)
        signer = jsonData["transaction"]["signer"].stringValue
        
        switch jsonData["transaction"]["otherTrans"]["type"].intValue {
        case TransactionType.transferTransaction.rawValue:
            
            innerTransaction = try! JSON(data: "{\"transaction\":\(jsonData["transaction"]["otherTrans"].rawString()!)}".data(using: String.Encoding.utf8)!).mapObject(TransferTransaction.self)
            (innerTransaction as! TransferTransaction).metaData = metaData
            
        case TransactionType.multisigAggregateModificationTransaction.rawValue:
            
            innerTransaction = try! JSON(data: "{\"transaction\":\(jsonData["transaction"]["otherTrans"].rawString()!)}".data(using: String.Encoding.utf8)!).mapObject(MultisigAggregateModificationTransaction.self)
            (innerTransaction as! MultisigAggregateModificationTransaction).metaData = metaData
            
        default:
            break
        }
    }
}
