import UIKit

protocol VideoProcessorDelegate: class {
    var state: SwypeViewController.State { get }
    func processVideo(at url: URL)
    func changeState(to state: SwypeViewController.State)
    func showAlert(text: String)
    func save(url: URL)
}

class VideoProcessor {
    
    private var videoRecorder: VideoRecorder!
    private var swypeDetector: SwypeDetector!

    private weak var delegate: VideoProcessorDelegate!
    private weak var coordinateDelegate: SwypeDetectorCoordinateDelegate!
    
    init(videoPreviewView: VideoPreviewView,
         coordinateDelegate: SwypeDetectorCoordinateDelegate,
         delegate: VideoProcessorDelegate) {
        
        videoRecorder = VideoRecorder(withParent: videoPreviewView)
        videoRecorder.delegate = self

        self.coordinateDelegate = coordinateDelegate
        resetSwypeDetector()
        
        self.delegate = delegate
    }
}

// MARK: - Public methods (Detector)
extension VideoProcessor {

    func viewWillLayoutSubviews() {
        videoRecorder.viewWillLayoutSubviews()
    }

    func setSwype(code: [Int]) {
        swypeDetector.setSwype(code: code)
    }
    
    func resetSwypeDetector() {
        guard let coordinateDelegate = coordinateDelegate else { return }
        swypeDetector = SwypeDetector(stateDelegate: self,
                                      coordinateDelegate: coordinateDelegate)
    }
}

// MARK: - Public methods (Detector)
extension VideoProcessor {
    
    func startCapture() {
        videoRecorder.startCapture()
    }
    
    func stopCapture() {
        videoRecorder.stopCapture()
    }
    
    func startRecord() {
        videoRecorder.startRecord()
    }
    
    func stopRecord(allowSubmit: Bool) {
        videoRecorder.stopRecord { [unowned self] recordedVideoURL in
            if (allowSubmit) {
                self.delegate.processVideo(at: recordedVideoURL)
                self.delegate.save(url: recordedVideoURL)
            }
        }
    }
}

// MARK: - VideoCameraDelegate
extension VideoProcessor: VideoRecorderDelegate {
    
    func process(buffer: CVImageBuffer, timestamp: CMTime) {
        
        guard let delegate = delegate else { return }
        
        switch delegate.state {
        case .waitRoundMovement, .prepareForStart, .detection:
            swypeDetector.process(buffer, timestamp: timestamp)
        default:
            break
        }
    }
}

// MARK: - DetectorStateDelegate
extension VideoProcessor: SwypeDetectorStateDelegate {
    
    func updateFromDetector(detectorState: SwypeDetector.State, index: Int) {
        
        switch detectorState {
        case .waitCircle:
            delegate.changeState(to: .waitRoundMovement)
        case .prepareForStart:
            delegate.changeState(to: .prepareForStart)
        case .working:
            delegate.changeState(to: .detection(index))
        case .finish:
            delegate.changeState(to: .finishDetection)
        default:
            break
        }
    }
}
