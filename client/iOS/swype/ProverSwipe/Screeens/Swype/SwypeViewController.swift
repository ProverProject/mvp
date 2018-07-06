import UIKit
import AVFoundation
import Accelerate
import Photos

class SwypeViewController: UIViewController, UpdateBalanceBehaviour {
    
    // MARK: - IBOutlet
    @IBOutlet weak var targetView: TargetView!
    @IBOutlet weak var infoView: InfoView!
    
    @IBOutlet weak var progressSwype: UIPageControl!
    
    @IBOutlet weak var videoPreviewView: VideoPreviewView!
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var balanceLabel: UILabel!
    
    // MARK: - IBAction
    @IBAction func recordButtonPressed(_ sender: UIButton) {

        switch state {
        case .readyToRecord:
            videoProcessor.startRecord()
            getSwype()
        case .waitSwype:
            videoProcessor.stopRecord(allowSubmit: false)
            queue.cancelAllOperations()
        case .waitRoundMovement, .prepareForStart, .detection:
            videoProcessor.stopRecord(allowSubmit: false)
        case .finishDetection:
            videoProcessor.stopRecord(allowSubmit: true)
        case .submitVideo:
            fatalError("Record button have to be non enable")
        }

        switch state {
        case .readyToRecord, .waitSwype, .finishDetection:
            break
        case .waitRoundMovement, .prepareForStart, .detection:
            self.infoView.message("Detection is not finished")
        case .submitVideo:
            fatalError("Record button have to be non enable")
        }

        // Do switch to the next state
        switch state {
        case .readyToRecord:
            state = .waitSwype
        case .waitSwype, .waitRoundMovement, .prepareForStart, .detection:
            state = .readyToRecord
        case .finishDetection:
            state = .submitVideo
        case .submitVideo:
            fatalError("Record button have to be non enable")
        }
    }
    
    @IBAction func walletButtonAction(_ sender: UIButton) {
        performSegue(withIdentifier: Segue.showWalletSegue.rawValue, sender: nil)
    }
    
    // MARK: - Dependencies
    var store: DependencyStore!
    var submitter: VideoSubmitter?
    var videoProcessor: VideoProcessor!
    var saver: VideoSaver?
    
    // MARK: - Private properties
    private var canStartVideoProcessing: Bool {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        return videoStatus == .authorized && audioStatus != .notDetermined
    }
    private var swypeBlock = ""
    private let queue = OperationQueue()

    var state: State = .readyToRecord { didSet { update() }}

    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[SwypeViewController] viewDidLoad")
        refreshBalance(button: nil,
                       label: balanceLabel,
                       queue: queue,
                       store: store,
                       withSymbol: false)
        state = .readyToRecord
        addBackgroundNotificationObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("[SwypeViewController] viewWillAppear")
        super.viewWillAppear(animated)
        balanceLabel.text = "\(store.balance)"

        if videoProcessor != nil {
            videoProcessor.startCapture()
        }
        else if canStartVideoProcessing {
            createVideoProcessingStuff()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        print("[SwypeViewController] viewDidAppear")
        super.viewDidAppear(animated)

        if videoProcessor == nil && !canStartVideoProcessing {
            requestAuthorizationForAudioCapture()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("[SwypeViewController] viewDidDisappear")
        videoProcessor?.stopCapture()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        videoProcessor?.viewWillLayoutSubviews()
    }

    // MARK: - Segue
    enum Segue: String {
        case showWalletSegue
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueStrID = segue.identifier, Segue(rawValue: segueStrID) != nil
            else { fatalError("[SwypeViewController] Wrong segue ID!") }
        
        guard let navigationVC = segue.destination as? UINavigationController
            else { fatalError("[SwypeViewController] Cast to UINavigationController failed!") }
        
        guard let walletVC = navigationVC.viewControllers.first as? WalletViewController
            else { fatalError("[SwypeViewController] Cast to WalletViewController failed!") }
        
        walletVC.store = store
        walletVC.shouldHideLeftButton = videoProcessor == nil
    }
}

// MARK: - Private methods
private extension SwypeViewController {
    
    func getSwype() {
        
        let operation = GetSwypeOperation(hex: store.wallet.hexAddress,
                                          apiProvider: store.apiProvider)
        
        operation.completionBlock = { [unowned self, weak operation] in
            
            guard let output = operation?.output else {
                self.infoView.message("Unknown error while get swype")
                self.state = .readyToRecord
                return
            }
            
            switch output {
            case let .success(responce):
                self.swypeBlock = responce.block
                self.infoView.message(responce.swypeSequence.map { "\($0)" }.joined())
                self.startRecognize(swype: responce.swypeSequence)
            case let .failure(error):
                switch error {
                case .notInitialize:
                    self.infoView.message("")
                case .networkError:
                    self.infoView.message("Service temporarily unavailable, please try again later")
                case .convertResponceError(let text):
                    self.infoView.message(text)
                }
                self.state = .readyToRecord
            }
        }
        
        queue.addOperation(operation)
    }
    
    func startRecognize(swype: [Int]) {
        videoProcessor.setSwype(code: swype)
        state = .waitRoundMovement
        progressSwype.setSteps(number: swype.count - 1)
    }

    func requestAuthorizationForAudioCapture() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined: // The user has not yet been asked for microphone access.
            AVCaptureDevice.requestAccess(for: .audio) { [unowned self] granted in
                self.requestAuthorizationForVideoCapture()
            }

        default: // The user has previously denied access.
            requestAuthorizationForVideoCapture()
        }
    }

    func requestAuthorizationForVideoCapture() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            createVideoProcessingStuff()

        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                if granted {
                    self.createVideoProcessingStuff()
                }
                else {
                    self.skipSwypeViewController()
                }
            }

        case .denied: // The user has previously denied access.
            skipSwypeViewController()
        case .restricted: // The user can't grant access due to restrictions.
            skipSwypeViewController()
        }
    }

    func createVideoProcessingStuff() {
        if !Thread.isMainThread {
            DispatchQueue.main.async(execute: createVideoProcessingStuff)
            return
        }

        videoProcessor = VideoProcessor(videoPreviewView: videoPreviewView,
                                        coordinateDelegate: targetView,
                                        delegate: self)
        
        submitter = VideoSubmitter(store: store)
        submitter!.delegate = infoView
        
        saver = VideoSaver()
        saver!.delegate = self

        videoProcessor.startCapture()
    }

    func skipSwypeViewController() {
        if !Thread.isMainThread {
            DispatchQueue.main.async(execute: skipSwypeViewController)
            return
        }

        let message = "The access to camera has been denied, so you will NOT be able " +
                      "to record and submit video.  You can re-enable the access to camera " +
                      "in your iPhone's Settings"
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel) { [unowned self] _ in
            self.performSegue(withIdentifier: Segue.showWalletSegue.rawValue, sender: nil)
        }

        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Notification
extension SwypeViewController {
    
    func addBackgroundNotificationObservers() {
        
        print("[SwypeViewController] addBackgroundNotificationObservers()")
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(handleDidEnterBackground),
                         name: NSNotification.Name.UIApplicationDidEnterBackground,
                         object: nil)
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(handleWillEnterForeground),
                         name: NSNotification.Name.UIApplicationWillEnterForeground,
                         object: nil)
    }
    
    func removeBackgroundNotificationObservers() {
        
        print("[SwypeViewController] removeBackgroundNotificationObservers()")
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleDidEnterBackground() {
        
        print("[SwypeViewController] handleDidBackground()")
        videoProcessor?.stopCapture()
        videoProcessor?.resetSwypeDetector()
    }

    @objc func handleWillEnterForeground() {
        
        print("[SwypeViewController] handleWillEnterForeground()")
        
        state = .readyToRecord
        videoProcessor?.startCapture()
    }
}

// MARK: - Embedded
extension SwypeViewController {
    enum State: Equatable {
        case readyToRecord
        case waitSwype
        case waitRoundMovement
        case prepareForStart
        case detection(Int)
        case finishDetection
        case submitVideo
        
        static func == (lhs: SwypeViewController.State, rhs: SwypeViewController.State) -> Bool {
            switch (lhs, rhs) {
            case (.readyToRecord, .readyToRecord),
                 (.waitSwype, .waitSwype),
                 (.waitRoundMovement, .waitRoundMovement),
                 (.prepareForStart, .prepareForStart),
                 (.finishDetection, .finishDetection),
                 (.submitVideo, .submitVideo):
                return true
            case (.detection(let lhsIndex), .detection(let rhsIndex)):
                return lhsIndex == rhsIndex
            default:
                return false
            }
        }
    }
}

// MARK: - State machine
extension SwypeViewController {
    
    func update() {
        if !Thread.isMainThread {
            DispatchQueue.main.async(execute: update)
            return
        }

        targetView.update(by: state)
        infoView.update(by: state)
        progressSwype.update(by: state)
        
        switch state {
        case .readyToRecord:
            recordButton.isEnabled = !(videoProcessor?.isRecordingAlive ?? false)
        case .waitSwype, .waitRoundMovement, .prepareForStart, .detection, .finishDetection:
            recordButton.setImage(image: #imageLiteral(resourceName: "stop_record"))
            recordButton.isEnabled = true
        case .submitVideo:
            recordButton.setImage(image: #imageLiteral(resourceName: "start_record"))
            recordButton.isEnabled = false
        }
    }
}

// MARK: - KSVideoCameraDelegate
extension SwypeViewController: VideoProcessorDelegate, VideoSaverNotifier {
    
    func showAlert(text: String) {
        let alertController = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func changeState(to state: SwypeViewController.State) {
        self.state = state
        switch state {
        case .detection(let index):
            progressSwype.setCurrentStep(index - 2)
        default:
            break
        }
    }

    func recordingStopped() {
        if !Thread.isMainThread {
            DispatchQueue.main.async(execute: recordingStopped)
            return
        }

        print("[SwypeViewController] recordingStopped()")

        videoProcessor.resetSwypeDetector()

        recordButton.setImage(image: #imageLiteral(resourceName: "start_record"))
        recordButton.isEnabled = true
    }

    func processVideo(at url: URL) {
        
        guard state == .submitVideo else {
            return
        }
        
        print("[SwypeViewController] start process video from url: \(url)")
        
        submitter?.submit(videoURL: url,
                          with: Hexadecimal(swypeBlock)!) { [unowned self] result in
                            
                            self.videoProcessor.resetSwypeDetector()
                            self.state = .readyToRecord
                            print("[SwypeViewController] submit result: \(result ?? "error submit")")
        }
    }
    
    func save(url: URL) {
        saver?.saveVideo(url: url)
    }
}
