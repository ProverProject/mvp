//
//  TransferTransactionModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import SwiftyJSON

/// The different transfer types for a transfer transaction.
public enum TransferType {
    case incoming
    case outgoing
}

/** 
    Represents a transfer transaction on the NEM blockchain.
    Visit the [documentation](http://bob.nem.ninja/docs/#transferTransaction)
    for more information.
 */
open class TransferTransaction: Transaction {
    
    // MARK: - Model Properties
    
    /// The type of the transaction.
    open var type = TransactionType.transferTransaction
    
    /// Additional information about the transaction.
    open var metaData: TransactionMetaData?
    
    /// The version of the transaction.
    open var version: Int!
    
    /// The number of seconds elapsed since the creation of the nemesis block.
    open var timeStamp: Int!
    
    /// The amount of micro NEM that is transferred from sender to recipient.
    open var amount: Double!
    
    /// The fee for the transaction.
    open var fee: Int!
    
    /// The transfer type of the transaction.
    open var transferType: TransferType?
    
    /// The address of the recipient.
    open var recipient: String!
    
    /// The message of the transaction.
    open var message: Message?
    
    /// The deadline of the transaction.
    open var deadline: Int!
    
    /// The transaction signature.
    open var signature: String!
    
    /// The public key of the account that created the transaction.
    open var signer: String!
    
    // MARK: - Model Lifecycle
    
    required public init?(version: Int, timeStamp: Int, amount: Double, fee: Int, recipient: String, message: Message?, deadline: Int, signer: String) {
        
        self.version = version
        self.timeStamp = timeStamp
        self.amount = amount
        self.fee = fee
        self.recipient = recipient
        self.message = message
        self.deadline = deadline
        self.signer = signer
    }
    
    required public init?(jsonData: JSON) {
        
        metaData = try? jsonData["meta"].mapObject(TransactionMetaData.self)
        version = jsonData["transaction"]["version"].intValue
        timeStamp = jsonData["transaction"]["timeStamp"].intValue
        amount = jsonData["transaction"]["amount"].doubleValue
        fee = jsonData["transaction"]["fee"].intValue
        recipient = jsonData["transaction"]["recipient"].stringValue
        deadline = jsonData["transaction"]["deadline"].intValue
        signature = jsonData["transaction"]["signature"].stringValue
        signer = jsonData["transaction"]["signer"].stringValue
        message = {
            var messageObject = try! jsonData["transaction"]["message"].mapObject(Message.self)
            if messageObject.payload != nil {
                messageObject.signer = signer
                messageObject.getMessageFromPayload()
                return messageObject
            } else {
                return nil
            }
        }()
    }
}
