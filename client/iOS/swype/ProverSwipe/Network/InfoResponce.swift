import Foundation

struct InfoResponce: Decodable {

  let nonce: String?
  let contractAddress: String
  let gasPrice: String
  let ethBalance: String?
}
