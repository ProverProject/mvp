import UIKit

extension CAShapeLayer {
    
    static func erase(shape: CAShapeLayer?) {
        DispatchQueue.main.async { [weak shape] in
            shape?.removeFromSuperlayer()
            shape = nil
        }
    }
    
}
