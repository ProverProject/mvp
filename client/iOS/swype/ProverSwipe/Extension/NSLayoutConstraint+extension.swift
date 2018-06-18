import UIKit

extension NSLayoutConstraint {
    
    func set(value: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.constant = CGFloat(value)
        }
    }
}
