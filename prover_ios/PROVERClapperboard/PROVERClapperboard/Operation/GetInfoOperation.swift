import Foundation

class GetInfoOperation: AsyncOperation {
  
  let apiService: APIService
  let hex: String
  var result: APIInfoResult?
  
  init(apiService: APIService, hex: String) {
    self.apiService = apiService
    self.hex = hex
  }
  
  override func main() {
    print("Start get info operation")
    apiService.getInfo(hex: hex) { (result) in
      self.result = result
      self.state = .finished
    }
  }
  
  deinit {
    print("Deinit get info operation")
  }
}

extension GetInfoOperation: SubmitOperationDataProvider {
  var outputToSubmit: APIInfoResult? {
    return result
  }
}
