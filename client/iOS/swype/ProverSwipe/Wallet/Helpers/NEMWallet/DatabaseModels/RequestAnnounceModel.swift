//
//  RequestAnnounceModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import SwiftyJSON

/**
    A RequestAnnounce object is used to transfer the transaction data 
    and the signature to NIS in order to initiate and broadcast a transaction.
 */
open class RequestAnnounce {
    
    // MARK: - Model Properties
    
    /**
        The transaction data as string. The string is created by first 
        creating the corresponding byte array and then converting the byte array 
        to a hexadecimal string.
     */
    open var data: String!
    
    /// The signature for the transaction as hexadecimal string.
    open var signature: String!
    
    // MARK: - Model Lifecycle
    
    required public init?(data: String, signature: String) {
        
        self.data = data
        self.signature = signature
    }
}
