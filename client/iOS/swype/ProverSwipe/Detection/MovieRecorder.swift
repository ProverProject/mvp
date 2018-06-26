import UIKit

protocol MovieRecorderDelegate: class {
    var state: SwypeViewController.State { get }
    func processVideo(at url: URL)
    func changeState(to state: SwypeViewController.State)
    func showAlert(text: String)
    func save(url: URL)
}

class MovieRecorder {
    
    private var videoRecorder: VideoRecorder!
    private var audioRecorder: AudioRecorder!
    private var swypeDetector: SwypeDetector!
    private let merger = Merger()
    
    private weak var delegate: MovieRecorderDelegate!
    private weak var coordinateDelegate: SwypeDetectorCoordinateDelegate!
    
    private var recordedVideoURL: URL!
    private var recordedAudioURL: URL!
    
    init(preview: UIView,
         coordinateDelegate: SwypeDetectorCoordinateDelegate,
         delegate: MovieRecorderDelegate) {
        
        videoRecorder = VideoRecorder(withParent: preview)
        videoRecorder.delegate = self

        self.coordinateDelegate = coordinateDelegate
        resetSwypeDetector()
        
        self.delegate = delegate
        self.audioRecorder = AudioRecorder(delegate: self)
    }
}

// MARK: - Public methods (Detector)
extension MovieRecorder {
    
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
extension MovieRecorder {
    
    func startCapture() {
        videoRecorder.startCapture()
    }
    
    func stopCapture() {
        videoRecorder.stopCapture()
    }
    
    func startRecord() {
        FileManager.clearTempDirectory()

        videoRecorder.startRecord()
        audioRecorder.startRecord()
    }
    
    func stopRecord(allowSubmit: Bool) {
        self.recordedVideoURL = nil
        self.recordedAudioURL = nil
        
        videoRecorder.stopRecord { [unowned self] recordedVideoURL in
            self.recordedVideoURL = recordedVideoURL

            if (self.recordedAudioURL != nil) {
                self.merge(allowSubmit)
            }
        }
        
        audioRecorder.stopRecord { [unowned self] recordedAudioURL in
            self.recordedAudioURL = recordedAudioURL

            if (self.recordedVideoURL != nil) {
                self.merge(allowSubmit)
            }
        }
    }
    
    private func merge(_ allowSubmit: Bool) {
        merger.merge(videoURL: recordedVideoURL, audioURL: recordedAudioURL) {
            [unowned self] videoURL, audioURL, resultURL in
            let fm = FileManager.default

            try! fm.removeItem(at: audioURL)
            try! fm.removeItem(at: videoURL)

            if (allowSubmit) {
                self.delegate.processVideo(at: resultURL)
                self.delegate.save(url: resultURL)
            }
        }
    }
}

// MARK: - VideoCameraDelegate
extension MovieRecorder: VideoRecorderDelegate {
    
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
extension MovieRecorder: SwypeDetectorStateDelegate {    
    
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

// MARK: - AudioRecorderDelegate
extension MovieRecorder: AudioRecorderDelegate {
    func showAlert(text: String) {
        delegate.showAlert(text: text)
    }
}
