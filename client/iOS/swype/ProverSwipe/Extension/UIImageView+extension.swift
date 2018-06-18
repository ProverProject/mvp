import UIKit

extension UIImageView {
    
    func start() {
        DispatchQueue.main.async { [weak self] in
            self?.show()
            self?.startAnimating()
        }
    }
    
    func stop() {
        DispatchQueue.main.async { [weak self] in
            self?.stopAnimating()
            self!.hide()
        }
    }
}
