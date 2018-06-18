import Moya
import Result

typealias HelloResult = Result<HelloOperation.Output, APIError>

class HelloOperation: AsyncOperation {
    
    // MARK: - Dependencies
    let apiProvider: MoyaProvider<ProverAPI>
    
    // MARK: - Input/Output
    let input: String
    var output = HelloResult(error: .notInitialize)
    
    init(apiProvider: MoyaProvider<ProverAPI>, input: String) {
        self.apiProvider = apiProvider
        self.input = input
    }
    
    override func main() {
        
//        guard let hex = input else {
//            self.state = .isFinished
//            return
//        }
        
        apiProvider.request(.hello(hex: input)) { (result) in
            
            switch result {
            case .success(let responce):
                
                guard let infoResponce = try? JSONDecoder().decode(InfoResponce.self, from: responce.data) else {
                    if let message = APIError.errorMessage(data: responce.data) {
                        self.output = HelloResult(error: .convertResponceError(message))
                    } else {
                        self.output = HelloResult(error: .convertResponceError("Unknown error while info from node"))
                    }
                    self.state = .isFinished
                    return
                }
                
                guard let output = Output(from: infoResponce) else {
                    if let message = APIError.errorMessage(data: responce.data) {
                        self.output = HelloResult(error: .convertResponceError(message))
                    } else {
                        self.output = HelloResult(error: .convertResponceError("Unknown error while info from node"))
                    }
                    self.state = .isFinished
                    return
                }
                
                self.output = HelloResult(output)
                
            case .failure:
                self.output = HelloResult(error: .networkError)
            }
            
            self.state = .isFinished
        }
    }
}

// MARK: - Embedded
extension HelloOperation {
    
    struct Output {
        
        let balance: Hexadecimal
        let info: TransactionInfo
        
        init?(from data: InfoResponce) {
            
            guard let nonceString = data.nonce,
                let balanceString = data.ethBalance else {
                    return nil
            }
            
            guard let nonce = Hexadecimal(nonceString),
                let contractAddress = Hexadecimal(data.contractAddress),
                let gasPrice = Hexadecimal(data.gasPrice),
                let balance = Hexadecimal(balanceString) else {
                    return nil
            }
            
            info = TransactionInfo(nonce: nonce,
                                   contractAddress: contractAddress,
                                   gasPrice: gasPrice)
            self.balance = balance
        }
    }
}
