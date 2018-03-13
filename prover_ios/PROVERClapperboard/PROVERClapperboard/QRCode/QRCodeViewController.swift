import UIKit

class QRCodeViewController: UIViewController {
  
  // MARK: - IBOutlet
  @IBOutlet weak var qrText: UILabel! {
    didSet {
      qrText.text = text
    }
  }
  @IBOutlet weak var qrImage: UIImageView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  // MARK: - IBAction
  @IBAction func closeButtonAction(_ sender: UIButton) {
    queue.cancelAllOperations()
    dismiss(animated: true, completion: nil)
  }
  
  // MARK: - Dependency
  var store: Store!
  
  // MARK: - Public properties
  var text: String?
  
  // MARK: - Private properties
  private let queue = OperationQueue()
  
  private var state: State = .loading {
    didSet {
      switch state {
      case .loading:
        DispatchQueue.main.async {
          self.qrImage.isHidden = true
          self.activityIndicator.isHidden = false
          self.activityIndicator.startAnimating()
        }
      case .load(let image):
        DispatchQueue.main.async {
          self.activityIndicator.stopAnimating()
          self.activityIndicator.isHidden = true
          self.qrImage.isHidden = false
          self.qrImage.image = image
        }
      }
    }
  }
  private enum State {
    case loading
    case load(UIImage)
  }
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    generateQR()
  }
  
  // MARK: - Private methods
  func generateQR() {
    
    state = .loading
    
    guard let text = text else { return }
    
    let qrDataOperation = QRCodeDataOperation(apiService: store.apiService,
                                              ethereumService: store.ethereumService,
                                              text: text)
    qrDataOperation.completionBlock = { [unowned self, unowned operation = qrDataOperation] in
      guard let result = operation.result else {
        print("qrDataOperation return nil")
        return
      }
      switch result {
      case .success(let data):
        self.state = .load(QRCoder().encode(data))
      case .failure(let error):
        print(error)
      }
    }
    queue.addOperation(qrDataOperation)
  }
}
