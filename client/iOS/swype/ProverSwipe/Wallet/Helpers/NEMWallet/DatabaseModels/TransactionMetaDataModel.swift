//
//  TransactionMetaDataModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import SwiftyJSON

/**
    Represents a transaction meta data object on the NEM blockchain.
    Visit the [documentation](http://bob.nem.ninja/docs/#transactionMetaData)
    for more information.
 */
public struct TransactionMetaData: SwiftyJSONMappable {
    
    // MARK: - Model Properties
    
    /// The id of the transaction.
    public var id: Int?
    
    /// The hash of the transaction.
    public var hash: String?
    
    /// The height of the block in which the transaction was included.
    public var height: Int?
    
    /// The transaction hash of the multisig transaction.
    public var data: String?
    
    // MARK: - Model Lifecycle
    
    public init?(jsonData: JSON) {
        
        id = jsonData["id"].int
        height = jsonData["height"].int
        data = jsonData["data"].string
        
        if jsonData["innerHash"]["data"].string == nil {
            hash = jsonData["hash"]["data"].stringValue
        } else {
            hash = jsonData["innerHash"]["data"].stringValue
        }
    }
}
