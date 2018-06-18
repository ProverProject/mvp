import Foundation
import Moya

enum ProverAPI {
    case hello(hex: String)
    case swype(hex: String)
    case submitMedia(hex: String)
}

extension ProverAPI: TargetType {
    
    var baseURL: URL {
        
        guard let url = URL(string: "http://mvp.prover.io/cgi-bin") else {
            fatalError("[ProverAPI] Can't create base url")
        }
        
        return url
    }
    
    var path: String {
        
        switch self {
        case .hello:
            return "/hello"
        case .swype:
            return "/fast-request-swype-code"
        case .submitMedia:
            return "/submit-media-hash"
        }
    }
    
    var method: Moya.Method {
        
        switch self {
        case .hello, .swype, .submitMedia:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        
        switch self {
        case let .hello(hex):
            return .requestParameters(parameters: ["user": hex],
                                      encoding: URLEncoding.default)
        case .swype(let hex):
            return .requestParameters(parameters: ["user": hex],
                                      encoding: URLEncoding.default)
        case .submitMedia(hex: let hex):
            return .requestParameters(parameters: ["hex": hex],
                                      encoding: URLEncoding.default)
        }
    }
    
    var headers: [String: String]? {
        
        switch self {
        case .hello, .swype, .submitMedia:
            return ["Content-Type": "application/x-www-form-urlencoded",
                    "Accept": "application/json"]
        }
    }
}
