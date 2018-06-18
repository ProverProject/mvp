//
//  BlockModel.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import Foundation
import SwiftyJSON

/**
    Represents a block on the NEM blockchain.
    Visit the [documentation](http://bob.nem.ninja/docs/#harvestInfo)
    for more information.
 */
public class Block: SwiftyJSONMappable {
    
    // MARK: - Model Properties
    
    /// The id of the block.
    public var id: Int!
    
    /// The height of the block.
    public var height: Int!
    
    /// The total fee collected by harvesting the block.
    public var totalFee: Int!
    
    /// The number of seconds elapsed since the creation of the nemesis block.
    public var timeStamp: Int!
    
    /// The block difficulty.
    public var difficulty: Int!
    
    // MARK: - Model Lifecycle
    
    public required init?(jsonData: JSON) {
        
        id = jsonData["id"].intValue
        height = jsonData["height"].intValue
        totalFee = jsonData["totalFee"].intValue
        timeStamp = jsonData["timeStamp"].intValue
        difficulty = jsonData["difficulty"].intValue
    }
}
