import Foundation

enum APIError: Error {
    
    case convertResponceError(String)
    case networkError
    case notInitialize
    
    static func errorMessage(data: Data) -> String? {
        
        do {
            let json = try JSONSerialization
                .jsonObject(with: data, options: .allowFragments)
            guard let dict = json as? [String: Any],
                let error = dict["error"] as? [String: Any],
                let message = error["message"] as? String else { return nil }
            return message
        } catch {
            return nil
        }
    }
}
