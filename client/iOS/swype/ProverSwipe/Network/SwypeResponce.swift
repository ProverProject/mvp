import Foundation

struct SwypeResponce: Decodable {
  
  var swypeID: Int {
    return result.swypeID
  }
  
  var block: String {
    return result.block
  }
  
  var swypeSequence: [Int] {
    return result.swypeSequence
  }
  
  private let result: SwypeResponceResult
}

fileprivate struct SwypeResponceResult: Decodable {
  
  let swypeID: Int
  let block: String
  let swypeSequence: [Int]
  
  enum CodingKeys: String, CodingKey {
    case swypeID = "swype-id"
    case block = "reference-block"
    case swypeSequence = "swype-sequence"
  }
}
