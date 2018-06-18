import Moya
import Result

typealias SwypeResult = Result<SwypeResponce, APIError>

class GetSwypeOperation: AsyncOperation {
    
    let apiProvider: MoyaProvider<ProverAPI>
    
    let hex: String
    var output = SwypeResult(error: .notInitialize)
    
    init(hex: String, apiProvider: MoyaProvider<ProverAPI>) {
        self.hex = hex
        self.apiProvider = apiProvider
    }
    
    override func main() {
        
        apiProvider.request(.swype(hex: hex)) { [weak self] result in
            
            guard let isCancelled = self?.isCancelled, !isCancelled else {
                self?.state = .isFinished
                return
            }
            
            switch result {
            case .success(let responce):
                
                do {
                    let swypeResponce = try JSONDecoder().decode(SwypeResponce.self, from: responce.data)
                    self?.output = SwypeResult(swypeResponce)
                } catch {
                    if let message = APIError.errorMessage(data: responce.data) {
                        self?.output = SwypeResult(error: .convertResponceError(message))
                    } else {
                        self?.output = SwypeResult(error: .convertResponceError("Unknown error while get swype"))
                    }
                }
                
            case .failure:
                self?.output = SwypeResult(error: .networkError)
            }
            
            self?.state = .isFinished
        }
    }
}
