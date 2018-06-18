//
//  InvoiceModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import CoreData

/// Represents an invoice object.
open class Invoice: NSManagedObject {
    
    // MARK: - Model Properties
    
    /// The id of the invoice.
    @NSManaged var id: NSNumber
    
    /// The title of the recipient account.
    @NSManaged var accountTitle: String
    
    /// The address of the recipient account.
    @NSManaged var accountAddress: String
    
    /// The invoice amount.
    @NSManaged var amount: NSNumber
    
    /// The invoice message.
    @NSManaged var message: String
}
