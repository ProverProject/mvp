import Foundation
import CoreStore

class NEMWallet {
    private lazy var account: Account = {
        if let acc = CoreStore.fetchOne(From<Account>()) {
            return acc
        } else {
            return try! AccountManager.createSync(account: "NEMWallet account", password: Keychain.passphrase)
        }
    }()

    init() {
        AccountManager.initCoreStore()

        var acc: Account? = account
        acc = nil
    }
}

extension NEMWallet: Wallet {
    var hexAddress: String {
        return account.address
    }

    func transactionHex(from data: Data, with info: TransactionInfo) -> Hexadecimal {
        return Hexadecimal("ffffff")!
    }

    func importWallet(_ key: Data, passphrase: String) -> Bool {
        return true
    }

    func exportWallet(passphrase: String) -> Data? {
        return Data()
    }
}
