import Foundation
import Geth

class EthereumWallet {
    // MARK: - Filemanager properties
    private var documentURL: URL {
        let url = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask).first!
        return url
    }
    
    private var keystoreURL: URL {
        let appURL = FileManager.default.urls(for: .applicationSupportDirectory,
                                              in: .allDomainsMask).first!
        let url = appURL.appendingPathComponent("keystore")
        return url
    }
    
    // MARK: - Ethereum computed properties
    private lazy var keystore: GethKeyStore = {
        guard let keystore = GethNewKeyStore(keystoreURL.path,
                                             GethLightScryptN,
                                             GethLightScryptP) else {
            fatalError("Can't create keystore")
        }
        return keystore
    }()
    
    private var account: GethAccount {
        // swiftlint:disable force_try
        let accounts = keystore.getAccounts()!

        if accounts.size() == 1 {
            return try! accounts.get(0)
        }

        if accounts.size() == 0 {
            return try! keystore.newAccount(Keychain.passphrase)
        }
        // swiftlint:enable force_try
        
        fatalError("More than one accounts")
    }
}

extension EthereumWallet: Wallet {
    var hexAddress: String {
        guard let hex = account.getAddress().getHex() else {
            fatalError("Can't get hex from account address")
        }
        return hex
    }
    
    func transactionHex(from data: Data, with info: TransactionInfo) -> Hexadecimal {
        
        var contractAddressError: NSError?
        let contractAddress = GethNewAddressFromHex(info.contractAddress.withPrefix,
                                                    &contractAddressError)
        guard contractAddressError == nil else {
            fatalError("Can't create contract address from hex")
        }
        
        let amount = GethNewBigInt(Int64(0))
        let gasLimit = Int64(1000000)
        
        let transaction = GethNewTransaction(info.nonce.toInt64!,
                                             contractAddress,
                                             amount,
                                             gasLimit,
                                             GethBigInt(info.gasPrice.toInt64!),
                                             data)
        
        let signer = account
        let chain = GethNewBigInt(3)
        
        guard let signed = try? keystore
            .signTxPassphrase(signer,
                              passphrase: Keychain.passphrase,
                              tx: transaction,
                              chainID: chain) else {
                                fatalError("[Ethereum service] Can't sign transaction")
        }
        
        guard let signedTxData = try? signed.encodeRLP() else {
            fatalError("[Ethereum service] Can't encode RLP from transaction")
        }
        
        return Hexadecimal(signedTxData.hexDescription)!
    }

    func importWallet(_ key: Data, passphrase: String) -> Bool {
        
        guard let oldKey = try? keystore.exportKey(account,
                                                   passphrase: passphrase,
                                                   newPassphrase: passphrase) else {
                                                    fatalError("Can't backup old account")
        }
        
        guard (try? keystore.delete(account, passphrase: passphrase)) != nil else {
            fatalError("Can't delete old account")
        }
        
        if (try? keystore.importKey(key,
                                    passphrase: passphrase,
                                    newPassphrase: passphrase)) != nil {
            print("Import succeeded!")
            return true
        } else {
            print("Import failed!")
            // swiftlint:disable force_try
            _ = try! keystore.importKey(oldKey,
                                        passphrase: passphrase,
                                        newPassphrase: passphrase)
            // swiftlint:enable force_try
            return false
        }
    }

    func exportWallet(passphrase: String) -> Data? {
        do {
            let key = try keystore.exportKey(account,
                                             passphrase: passphrase,
                                             newPassphrase: passphrase)
            let filename = documentURL.appendingPathComponent("wallet \(hexAddress)")
            try key.write(to: filename)
            return key
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

