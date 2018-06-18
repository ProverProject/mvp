import Foundation
import UIKit

protocol DetectorStateDelegate: class {
    func updateFromDetector(detectorState: Detector.State, index: Int)
}

protocol DetectorCoordinateDelegate: class {
    func updateTargetCoordinate(x: CGFloat, y: CGFloat, for point: SwypePoint)
}

class Detector {
    
    // MARK: - Public properties
    
    // MARK: - Public methods
    func setSwype(code: [Int]) {
        points = code
    }
    
    // MARK: - Private properties
    private var points = [Int]()
    private var nextPointIndex: Int32 = 0 {
        didSet {
            print("[Detector] search point with index \(nextPointIndex) value: \(points[Int(nextPointIndex)])")
            stateDelegate?.updateFromDetector(detectorState: detectorState, index: Int(nextPointIndex))
        }
    }
    
    private var _detectoState: State = .notStart {
        didSet {
            print("[Detector] _detectoState: \(_detectoState)")
            stateDelegate?.updateFromDetector(detectorState: detectorState, index: Int(index))
            print("[Detector] index: \(index)")
        }
    }
    private var detectorState: State = .notStart {
        
        didSet {
            
            if _detectoState != detectorState {
                _detectoState = detectorState
            }
            
            print("[Detector] move to state: \(self.state)")
            
            switch detectorState {
            case .waitCircle:
                print("[Detector] wait circle")
                let swypeString = points.reduce(into: "", { (result, number) in
                    result += String(number)
                })
                detector?.setSwype(swypeString)
            case .waitSwypeCode:
                print("[Detector] wait swype code")
            case .prepareForStart:
                print("[Detector] prepare for start")
            case .working:
                if index != nextPointIndex {
                    nextPointIndex = index
                }
                let nextPoint = SwypePoint(rawValue: points[Int(index)])!
                let currentPoint = SwypePoint(rawValue: points[Int(index - 1)])!
                let vector = currentPoint.vector(to: nextPoint)
                coordinateDelegate?
                    .updateTargetCoordinate(x: CGFloat(vector.x) - CGFloat(xValue) / CGFloat(1024),
                                            y: CGFloat(vector.y) - CGFloat(yValue) / CGFloat(1024),
                                            for: SwypePoint.point(from: vector))
                
            case .finish:
                print("[Detector] finish work")
            case .notStart:
                print("[Detector] not start")
            }
        }
    }
    
    // properties for detector
    private var state: Int32 = 0 {
        didSet {
            if state != Int32(detectorState.rawValue) || detectorState == .working {
                print("[Detector] didSet private var state: Int32 = \(state)")
                detectorState = State(rawValue: Int(state))!
            }
        }
    }
    private var index: Int32 = 0
    private var xValue: Int32 = 0
    private var yValue: Int32 = 0
    private var debug: Int32 = 0
    
    // MARK: - Dependencies
    private var detector = SwypeDetector()
    private weak var stateDelegate: DetectorStateDelegate?
    private weak var coordinateDelegate: DetectorCoordinateDelegate?
    
    // MARK: - Lifecycle
    init(stateDelegate: DetectorStateDelegate, coordinateDelegate: DetectorCoordinateDelegate) {
        self.stateDelegate = stateDelegate
        self.coordinateDelegate = coordinateDelegate
        coordinateDelegate.updateTargetCoordinate(x: 0, y: 0, for: .five)
        print("[Detector] init private var state: Int32 = \(state)")
        print("[Detector] init private var detectorState: State = \(detectorState)")
    }
    
    // MARK: - Process frame
    func process(_ imageBuffer: CVImageBuffer, timestamp: CMTime) {
        
        detector?.processFrame(imageBuffer,
                               timestamp: uint(CMTimeGetSeconds(timestamp) * 1000),
                               state: &state,
                               index: &index,
                               x: &xValue,
                               y: &yValue,
                               debug: &debug)
    }
}

// MARK: - Embedded types
extension Detector {
    
    enum State: Int {
        case waitCircle = 0
        case waitSwypeCode = 1
        case prepareForStart = 2
        case working = 3
        case finish = 4
        case notStart = 5
    }
}
