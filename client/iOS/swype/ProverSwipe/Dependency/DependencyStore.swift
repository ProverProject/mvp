import Foundation
import Moya

class DependencyStore {
    let wallet: Wallet = EthereumWallet()
    let wallet2: Wallet = NEMWallet()
    
    let apiProvider = MoyaProvider<ProverAPI>()
    
    var balance = 0.0
    
    init() {
        print("path to documents: \(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!)")
        print("wallet address: \(wallet.hexAddress)")
    }
}
