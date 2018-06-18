import Foundation

class HashManager: NSObject
{
    final class func AES256Encrypt(inputText :String ,key :String) -> String {
        let messageBytes = inputText.asByteArray()
        var messageData = NSData(bytes: messageBytes, length: messageBytes.count)

        let ivData = NSData().generateRandomIV(16)
        messageData = messageData.aesEncrypt(key: key.asByteArray(), iv: ivData!.bytes)!
        
        return ivData!.bytes.toHexString() + messageData.toHexString()
    }
    
    final class func AES256Decrypt(inputText :String ,key :String) -> String? {
        let inputBytes = inputText.asByteArray()
        let customizedIV =  Array(inputBytes[0..<16])
        let encryptedBytes = Array(inputBytes[16..<inputBytes.count])
        var data :NSData? = NSData(bytes: encryptedBytes, length: encryptedBytes.count)
        data = data!.aesDecrypt(key: key.asByteArray(), iv: customizedIV)
        
        return data!.toHexString()
    }
    
    final class func SHA256Encrypt(_ data :[UInt8])->String {
        var outBuffer: Array<UInt8> = Array(repeating: 0, count: 64)
        var inBuffer: Array<UInt8> = Array(data)
        let len :Int32 = Int32(inBuffer.count)
        SHA256_hash(&outBuffer, &inBuffer, len)
        
        let hash :String = NSString(bytes: outBuffer, length: outBuffer.count, encoding: String.Encoding.utf8.rawValue) as! String
        
        return hash
    }
    
    final func RIPEMD160Encrypt(_ inputText: String)->String {
        return RIPEMD.asciiDigest(inputText) as String
    }
    
    final class func generateAesKeyForString(_ string: String, salt: NSData, roundCount: Int?) throws -> NSData? {
        let error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        let nsDerivedKey = NSMutableData(length: 32)
        var actualRoundCount: UInt32
        
        let algorithm: CCPBKDFAlgorithm        = CCPBKDFAlgorithm(kCCPBKDF2)
        let prf:       CCPseudoRandomAlgorithm = CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1)
        let saltBytes  = salt.bytes
        let saltLength = size_t(salt.length)

        let nsPassword        = string as NSString
        let nsPasswordPointer = UnsafePointer<Int8>(nsPassword.cString(using: String.Encoding.utf8.rawValue))
        let nsPasswordLength  = size_t(nsPassword.lengthOfBytes(using: String.Encoding.utf8.rawValue))

        let nsDerivedKeyPointer = nsDerivedKey!.mutableBytes
        let nsDerivedKeyLength = size_t(nsDerivedKey!.length)

        let msec: UInt32 = 300
        
        if roundCount != nil {
            actualRoundCount = UInt32(roundCount!)
        }
        else {
            actualRoundCount = CCCalibratePBKDF(
                algorithm,
                nsPasswordLength,
                saltLength,
                prf,
                nsDerivedKeyLength,
                msec);
        }
        
        let result = CCKeyDerivationPBKDF(
            algorithm,
            nsPasswordPointer,   nsPasswordLength,
            saltBytes.assumingMemoryBound(to: UInt8.self),
            saltLength,
            prf,                 actualRoundCount,
            nsDerivedKeyPointer.assumingMemoryBound(to: UInt8.self), nsDerivedKeyLength)
        
        if result != 0 {            
            throw error
        }
        
        return nsDerivedKey
    }
}


