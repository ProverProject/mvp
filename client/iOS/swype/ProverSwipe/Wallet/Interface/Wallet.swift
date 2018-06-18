import Foundation
import KeychainSwift

protocol Wallet {
    var hexAddress: String { get }
    
    func transactionHex(from data: Data, with info: TransactionInfo) -> Hexadecimal
    func importWallet(_ key: Data, passphrase: String) -> Bool
    func exportWallet(passphrase: String) -> Data?
}
