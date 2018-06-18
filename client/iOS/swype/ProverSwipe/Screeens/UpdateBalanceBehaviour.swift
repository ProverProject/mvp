import Foundation
import UIKit

protocol UpdateBalanceBehaviour: class {
    func refreshBalance(button: UIBarButtonItem?,
                        label: UILabel,
                        queue: OperationQueue,
                        store: DependencyStore,
                        withSymbol: Bool)
}

extension UpdateBalanceBehaviour {
    func refreshBalance(button: UIBarButtonItem?,
                        label: UILabel,
                        queue: OperationQueue,
                        store: DependencyStore,
                        withSymbol: Bool = true) {
        print("[UpdateBalanceBehaviour] refresh")
        
        if let button = button {
            startAnimationUIBarButtonItem(button: button)
        }
        
        let operation = HelloOperation(apiProvider: store.apiProvider,
                                       input: store.wallet.hexAddress)
        
        operation.completionBlock = { [weak self] in
            
            if let button = button {
                self?.stopAnimationUIBarButtonItem(button: button)
            }
            
            DispatchQueue.main.async {
                
                guard let balance = operation.output.value?.balance else { return }
                
                let significantDigits = Int(Double(balance.toInt64!) * pow(10, -10))
                let actualNumber = Double(significantDigits) * pow(10, -8)
                
                store.balance = actualNumber
                
                let text = NSMutableAttributedString(string: "\(actualNumber) ")
                
                // prover symbol
                if withSymbol {
                    let attachment = NSTextAttachment()
                    attachment.image = #imageLiteral(resourceName: "proofSymbol")
                    let imageString = NSAttributedString(attachment: attachment)
                    text.append(imageString)
                }
                
                UIView.animate(withDuration: 0.5, animations: {
                    label.alpha = 0.0
                }, completion: { finished in
                    if finished {
                        UIView.animate(withDuration: 0.5, animations: {
                            label.attributedText = text
                            label.alpha = 1.0
                        })
                    }
                })
            }
        }
        queue.addOperation(operation)
    }
    
    fileprivate func startAnimationUIBarButtonItem(button: UIBarButtonItem) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1,
                           delay: 0,
                           options: [.repeat, .curveLinear],
                           animations: {
                            let transform = CGAffineTransform(rotationAngle: .pi)
                            guard let view = button.value(forKey: "view") as? UIView else {
                                print("Can't get view from UIBarButtonItem")
                                return
                            }
                            view.transform = transform
            }, completion: nil)
        }
    }
    
    fileprivate func stopAnimationUIBarButtonItem(button: UIBarButtonItem) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveLinear],
                           animations: {
                            
                            guard let view = button.value(forKey: "view") as? UIView else {
                                print("Can't get view from UIBarButtonItem")
                                return
                            }
                            view.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }
}
