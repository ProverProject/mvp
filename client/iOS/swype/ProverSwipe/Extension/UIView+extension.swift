import UIKit

extension UIView {
    
    func drawLine(from start: CGPoint, to end: CGPoint,
                  width: CGFloat, color: UIColor) -> CAShapeLayer {
        
        let shapeLayer = CAShapeLayer()
        
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = width
        
        DispatchQueue.main.async { [weak self] in
            self?.layer.addSublayer(shapeLayer)
        }
        
        return shapeLayer
    }
    
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self!.isHidden = true
        }
    }
    
    func show() {
        DispatchQueue.main.async { [weak self] in
            self?.isHidden = false
        }
    }
    
    var center: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
}
