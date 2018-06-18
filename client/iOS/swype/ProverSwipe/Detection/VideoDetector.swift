import UIKit

protocol VideDetectoDelegate: class {
    var state: SwypeViewController.State { get }
    func processVideo(at url: URL)
    func changeState(to state: SwypeViewController.State)
    func showAlert(text: String)
    func save(url: URL)
}

class VideoDetector {
    
    private var camera: VideoRecorder?
    private var detector: Detector?
    private var audioRecorder: AudioRecorder!
    private let merger = Merger()
    
    private weak var delegate: VideDetectoDelegate?
    private weak var coordinateDelegate: DetectorCoordinateDelegate?
    
    private var allowSubmit = false
    private var videoURL: URL?
    private var audioURL: URL?
    
    var mergeCompletionHandler: ((URL, URL, URL) -> Void)?
    
    init(preview: UIView,
         coordinateDelegate: DetectorCoordinateDelegate,
         delegate: VideDetectoDelegate) {
        
        camera = VideoRecorder(withParent: preview)
        camera?.delegate = self
        camera?.recordVideo = true
        
        self.coordinateDelegate = coordinateDelegate
        resetDetector()
        
        self.delegate = delegate
        self.audioRecorder = AudioRecorder(delegate: self)

        mergeCompletionHandler = { [weak self] videoURL, audioURL, resultURL in
            let fm = FileManager.default

            try! fm.removeItem(at: audioURL)
            try! fm.removeItem(at: videoURL)

            guard let allowSubmit = self?.allowSubmit, allowSubmit else { return }

            delegate.processVideo(at: resultURL)
            delegate.save(url: resultURL)
        }
    }
}

// MARK: - Public methods (Detector)
extension VideoDetector {
    
    func setSwype(code: [Int]) {
        detector?.setSwype(code: code)
    }
    
    func resetDetector() {
        guard let coordinateDelegate = coordinateDelegate else { return }
        detector = Detector(stateDelegate: self,
                            coordinateDelegate: coordinateDelegate)
    }
}

// MARK: - Public methods (Detector)
extension VideoDetector {
    
    func start() {
        camera?.start()
    }
    
    func stop() {
        camera?.stop()
    }
    
    func startRecord() {
        camera?.startRecord()
        audioRecorder.startRecord()
    }
    
    func stopRecord(allowSubmit: Bool) {
        self.allowSubmit = allowSubmit
        camera?.stopRecord { [weak self] fileURL in
            self?.videoURL = fileURL
            if let videoURL = self?.videoURL,
                let audioURL = self?.audioURL,
                let handler = self?.mergeCompletionHandler {
                self?.merger.merge(videoURL: videoURL, audioURL: audioURL, handler: handler)
            }
        }
        audioRecorder.stopRecord { [weak self] fileURL in
            self?.audioURL = fileURL
            if let videoURL = self?.videoURL,
                let audioURL = self?.audioURL,
                let handler = self?.mergeCompletionHandler {
                self?.merger.merge(videoURL: videoURL, audioURL: audioURL, handler: handler)
            }
        }
    }
}

// MARK: - VideoCameraDelegate
extension VideoDetector: VideoRecorderDelegate {
    
    func process(buffer: CVImageBuffer, timestamp: CMTime) {
        
        guard let delegate = delegate else { return }
        
        switch delegate.state {
        case .waitRoundMovement, .prepareForStart, .detection:
            detector?.process(buffer, timestamp: timestamp)
        default:
            break
        }
    }
}

// MARK: - DetectorStateDelegate
extension VideoDetector: DetectorStateDelegate {    
    
    func updateFromDetector(detectorState: Detector.State, index: Int) {
        
        switch detectorState {
        case .waitCircle:
            delegate?.changeState(to: .waitRoundMovement)
        case .prepareForStart:
            delegate?.changeState(to: .prepareForStart)
        case .working:
            delegate?.changeState(to: .detection(index))
        case .finish:
            delegate?.changeState(to: .finishDetection)
        default:
            break
        }
    }
}

// MARK: - AudioRecorderDelegate
extension VideoDetector: AudioRecorderDelegate {
    func showAlert(text: String) {
        delegate?.showAlert(text: text)
    }
}
