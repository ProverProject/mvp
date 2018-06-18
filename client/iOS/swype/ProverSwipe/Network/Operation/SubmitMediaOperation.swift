import Moya
import Result

typealias SubmitMediaResult = Result<String, APIError>

class SubmitMediaOperation: AsyncOperation {
    
    let apiProvider: MoyaProvider<ProverAPI>
    
    var hex: String?
    var output = SubmitMediaResult(error: .notInitialize)
    
    init(apiProvider: MoyaProvider<ProverAPI>) {
        self.apiProvider = apiProvider
    }
    
    override func main() {
        
        guard let hex = hex else {
            print("[SubmitMediaOperation] hex is nil")
            return
        }
        
        print("[SubmitMediaOperation] start request with hex: \(hex)")
        
        apiProvider.request(.submitMedia(hex: hex)) { [weak self] result in
            
            switch result {
            case .success(let responce):
                
                do {
                    let responce = try JSONDecoder().decode(SubmitMediaResponce.self, from: responce.data)
                    self?.output = SubmitMediaResult(responce.result)
                } catch {
                    if let message = APIError.errorMessage(data: responce.data) {
                        self?.output = SubmitMediaResult(error: .convertResponceError(message))
                    } else {
                        self?.output =
                            SubmitMediaResult(error: .convertResponceError("Unknown error while submit video"))
                    }
                }
                
            case .failure:
                self?.output = SubmitMediaResult(error: .networkError)
            }
            
            self?.state = .isFinished
        }
    }
}
