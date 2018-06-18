import Foundation
import CryptoSwift
import Result

typealias VideoTransactionResult = Result<Hexadecimal, APIError>

class VideoTransactionOperation: Operation {
    
    // MARK: - Dependencies
    let wallet: Wallet
    
    // MARK: - Input / Output
    let videoURL: URL
    let swypeBlock: Hexadecimal
    var info: TransactionInfo?
    var output = VideoTransactionResult(error: .notInitialize)
    
    // MARK: - Initialization
    init(videoURL: URL, swypeBlock: Hexadecimal, wallet: Wallet) {
        self.videoURL = videoURL
        self.swypeBlock = swypeBlock
        self.wallet = wallet
    }
    
    override func main() {
        
        guard let info = info,
            let data = try? Data(contentsOf: videoURL) else {
                print("[VideoTransactionOperation] can't get data from input")
                output = Result(error: .convertResponceError("No input data to create transaction"))
                return
        }
        
        let operation = Hexadecimal("0xa0ee3ecf")!.toBytes
        print("[VideoTransactionOperation] video file sha256: \(data.sha256().hexDescription)")
        let bytes = operation + [UInt8](data.sha256()) + swypeBlock.toBytes
        
        let transactionHex = wallet.transactionHex(from: Data(bytes: bytes), with: info)
        output = Result(transactionHex)
    }
}
