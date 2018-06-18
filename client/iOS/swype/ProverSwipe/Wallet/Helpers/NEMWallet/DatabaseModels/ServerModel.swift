//
//  ServerModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import CoreData

/// Represents a server object.
open class Server: NSManagedObject {
    
    // MARK: - Model Properties
    
    /// The address of the server.
    @NSManaged var address: String
    
    /// The NIS port of the server.
    @NSManaged var port: String
    
    /// The protocol type to use (http/https).
    @NSManaged var protocolType: String
    
    /// A bool indicating whether the server is a default server or not.
    @NSManaged var isDefault: Bool
}
