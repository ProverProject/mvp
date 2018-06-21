import UIKit
import AVFoundation
import Accelerate
import Photos

class SwypeViewController: UIViewController, UpdateBalanceBehaviour {
    
    // MARK: - IBOutlet
    @IBOutlet weak var targetView: TargetView!
    @IBOutlet weak var infoView: InfoView!
    
    @IBOutlet weak var progressSwype: UIPageControl!
    
    @IBOutlet weak var preview: UIImageView!
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var balanceLabel: UILabel!
    
    // MARK: - IBAction
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        
        recordButtonUpdateVideoDetector()
        
        switch state {
        case .readyToRecord:
            getSwype()
        case .waitSwype, .finishDetection:
            break
        case .waitRoundMovement, .prepareForStart, .detection:
            self.infoView.message("Detection is not finished")
        case .submitVideo:
            fatalError("Record button have to be non enable")
        }
        
        recordButtonUpdateState()
    }
    
    @IBAction func walletButtonAction(_ sender: UIButton) {
        performSegue(withIdentifier: Segue.showWalletSegue.rawValue, sender: nil)
    }
    
    // MARK: - Dependencies
    var store: DependencyStore!
    var submitter: VideoSubmitter?
    var movieRecorder: MovieRecorder!
    var saver: VideoSaver?
    
    // MARK: - Private properties
    private var swypeBlock = ""
    
    private let queue = OperationQueue()
    
    var state: State = .readyToRecord { didSet { update(by: state) }}
        
    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[SwypeViewController] viewDidLoad")
        configDependencies()
        refreshBalance(button: nil,
                       label: balanceLabel,
                       queue: queue,
                       store: store,
                       withSymbol: false)
        state = .readyToRecord
        subscribeNotefications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("[SwypeViewController] viewWillAppear")
        movieRecorder.startCapture()
        balanceLabel.text = "\(store.balance)"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("[SwypeViewController] viewDidDisappear")
        movieRecorder.stopCapture()
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
    }
}

// MARK: - Private methods
private extension SwypeViewController {
    
    func getSwype() {
        
        let operation = GetSwypeOperation(hex: store.wallet.hexAddress,
                                          apiProvider: store.apiProvider)
        
        operation.completionBlock = { [weak operation] in
            
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
    
    func recordButtonUpdateVideoDetector() {
        
        switch state {
        case .readyToRecord:
            movieRecorder.startRecord()
        case .waitSwype:
            movieRecorder.resetSwypeDetector()
            movieRecorder.stopRecord(allowSubmit: false)
            queue.cancelAllOperations()
        case .waitRoundMovement, .prepareForStart, .detection:
            movieRecorder.resetSwypeDetector()
            movieRecorder.stopRecord(allowSubmit: false)
        case .finishDetection:
            movieRecorder.resetSwypeDetector()
            movieRecorder.stopRecord(allowSubmit: true)
        case .submitVideo:
            fatalError("Record button have to be non enable")
        }
    }
    
    func recordButtonUpdateState() {
        
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
    
    func startRecognize(swype: [Int]) {
        movieRecorder.setSwype(code: swype)
        state = .waitRoundMovement
        progressSwype.setSteps(number: swype.count - 1)
    }
    
    func configDependencies() {
        
        movieRecorder = MovieRecorder(preview: preview,
                                      coordinateDelegate: targetView,
                                      delegate: self)
        
        submitter = VideoSubmitter(store: self.store)
        submitter?.delegate = infoView
        
        saver = VideoSaver()
        saver?.delegate = self
    }
}

// MARK: - Notification
extension SwypeViewController {
    
    func subscribeNotefications() {
        
        print("[SwypeViewController] subscribeNotefications()")
        
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
    
    func unsubscribeNotefications() {
        
        print("[SwypeViewController] unsubscribeNotefications()")
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleDidEnterBackground() {
        
        print("[SwypeViewController] handleDidBackground()")
        movieRecorder.stopCapture()
        movieRecorder.resetSwypeDetector()
    }
    
    @objc func handleWillEnterForeground() {
        
        print("[SwypeViewController] handleWillEnterForeground()")
        
        state = .readyToRecord
        movieRecorder.startCapture()
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
extension SwypeViewController: SwypeScreenState {
    
    func update(by state: SwypeViewController.State) {
        
        targetView.update(by: state)
        infoView.update(by: state)
        progressSwype.update(by: state)
        
        switch state {
        case .readyToRecord:
            recordButton.setImage(image: #imageLiteral(resourceName: "start_record"))
            recordButton.setEnable(true)
        case .waitSwype:
            recordButton.setImage(image: #imageLiteral(resourceName: "stop_record"))
            recordButton.setEnable(true)
        case .waitRoundMovement:
            recordButton.setImage(image: #imageLiteral(resourceName: "stop_record"))
            recordButton.setEnable(true)
        case .prepareForStart:
            recordButton.setImage(image: #imageLiteral(resourceName: "stop_record"))
            recordButton.setEnable(true)
        case .detection:
            recordButton.setImage(image: #imageLiteral(resourceName: "stop_record"))
            recordButton.setEnable(true)
        case .finishDetection:
            recordButton.setImage(image: #imageLiteral(resourceName: "stop_record"))
            recordButton.setEnable(true)
        case .submitVideo:
            recordButton.setImage(image: #imageLiteral(resourceName: "start_record"))
            recordButton.setEnable(false)
        }
    }
}

// MARK: - KSVideoCameraDelegate
extension SwypeViewController: MovieRecorderDelegate, VideoSaverNotifier {
    
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
    
    func processVideo(at url: URL) {
        
        guard state == .submitVideo else {
            return
        }
        
        print("[SwypeViewController] start process video from url: \(url)")
        
        submitter?.submit(videoURL: url,
                          with: Hexadecimal(swypeBlock)!) { [weak self] result in
                            
                            self?.movieRecorder.resetSwypeDetector()
                            self?.state = .readyToRecord
                            print("[SwypeViewController] submit result: \(result ?? "error submit")")
        }
    }
    
    func save(url: URL) {
        saver?.saveVideo(url: url)
    }
}
