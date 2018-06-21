import UIKit

class TargetView: UIView {
    
    // MARK: - IBOutlet
    @IBOutlet private weak var targetPoint: UIImageView!
    @IBOutlet private weak var targetX: NSLayoutConstraint!
    @IBOutlet private weak var targetY: NSLayoutConstraint!
    
    @IBOutlet private weak var centralPoint: UIImageView!
    @IBOutlet private weak var roundMovement: UIImageView! {
        didSet {
            var images = [UIImage]()
            for index in 1...90 {
                let path = Bundle.main.path(forResource: "round_move_\(index)", ofType: "png")
                if let path = path, let image = UIImage(contentsOfFile: path) {
                    images.append(image)
                }
            }
            roundMovement.animationImages = images
            roundMovement.animationDuration = 3
        }
    }
    
    // MARK: - Private properties
    private let pointDistance: CGFloat = 100
    private var currentPoint: SwypePoint = .five
    private var swypeTrack: CAShapeLayer?
}

// MARK: - Public methods
extension TargetView {
    
    func setTargetHidden(_ value: Bool) {
        if value {
            targetPoint.hide()
            centralPoint.hide()
        } else {
            targetPoint.show()
            centralPoint.show()
        }
    }
}

// MARK: - Private methods
private extension TargetView {
    
    func drawLine(to point: SwypePoint) {
        
        guard point != currentPoint else { return }
        
        DispatchQueue.main.async {
            let start = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            let end = CGPoint(x: start.x + CGFloat(point.coordinates.x) * self.pointDistance,
                              y: start.y + CGFloat(point.coordinates.y) * self.pointDistance)
            
            CAShapeLayer.erase(shape: self.swypeTrack)
            self.swypeTrack = self.drawLine(from: start, to: end,
                                            width: 1, color: .gray)
        }
    }
    
    func hideTarget() {
        setTargetHidden(true)
        reset()
    }
    
    func showTargets() {
        setTargetHidden(false)
        reset()
    }
    
    func reset() {
        targetX.set(value: 0)
        targetY.set(value: 0)
        CAShapeLayer.erase(shape: swypeTrack)
    }
}

// MARK: - DetectorCoordinateDelegate
extension TargetView: SwypeDetectorCoordinateDelegate {
    
    func updateTargetCoordinate(x: CGFloat, y: CGFloat, for point: SwypePoint) {
        drawLine(to: point)
        targetX.set(value: Int(pointDistance * x))
        targetY.set(value: Int(pointDistance * y))
    }
}

extension TargetView: SwypeScreenState {
    
    func update(by state: SwypeViewController.State) {
        
        print("[TargetView] switch to \(state)")
        
        switch state {
        case .readyToRecord:
            hideTarget()
            roundMovement.stop()
        case .waitSwype:
            hideTarget()
            roundMovement.stop()
        case .waitRoundMovement:
            hideTarget()
            roundMovement.start()
        case .prepareForStart:
            showTargets()
            roundMovement.stop()
        case .detection:
            setTargetHidden(false)
            roundMovement.stop()
        case .finishDetection:
            showTargets()
            roundMovement.stop()
        case .submitVideo:
            hideTarget()
            roundMovement.stop()
        }
    }
}
