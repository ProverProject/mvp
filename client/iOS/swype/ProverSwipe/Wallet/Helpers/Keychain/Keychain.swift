import Foundation
import KeychainSwift

class Keychain {
    static var passphrase: String = {
        let keyString = "ethereum passphrase"
        let keychain = KeychainSwift()
        keychain.synchronizable = true

        var currentPassphrase = keychain.get(keyString)
        
        if (currentPassphrase == nil) {
            currentPassphrase = UUID().uuidString.lowercased()
            keychain.set(currentPassphrase!, forKey: keyString)
        }
        
        return currentPassphrase!
    }()
}
