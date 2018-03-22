import UIKit

class QRCodeViewController: UIViewController {
  
  // MARK: - IBOutlet
  @IBOutlet weak var qrText: UILabel! {
    didSet {
      qrText.text = text
    }
  }
  @IBOutlet weak var qrImage: UIImageView!
  @IBOutlet weak var logoQRImage: UIImageView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  // MARK: - IBAction
  @IBAction func closeButtonAction(_ sender: UIButton) {
    queue.cancelAllOperations()
    dismiss(animated: true, completion: nil)
  }
  
  // MARK: - Dependency
  var store: DependencyStore!
  
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
          
          self.logoQRImage.image = image
          let maskImageView = UIImageView()
          maskImageView.frame = CGRect(origin: .zero, size: self.logoQRImage.frame.size)
          maskImageView.image = #imageLiteral(resourceName: "symbol")
          maskImageView.contentMode = .center
          self.logoQRImage.mask = maskImageView
        }
      case .failure(let text):
        DispatchQueue.main.async {
          self.activityIndicator.stopAnimating()
          self.activityIndicator.isHidden = true
          self.showAlert(with: text)
        }
      }
    }
  }
  private enum State {
    case loading
    case load(UIImage)
    case failure(String)
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
        print(data)
        self.state = .load(QRCoder().encode(data))
      case .failure(let error):
        print(error)
        switch error {
        case .networkError:
          self.state = .failure("Issue with network connection")
        case .submitError(let submitError):
          switch submitError.message {
          case "insufficient funds for gas * price + value":
            self.state = .failure("insufficient funds on the balance")
          case let text where
            text.contains("known transaction") || text.contains("replacement transaction underpriced"):
            self.state =
              .failure("You can not execute the query until the previous transaction is placed in the blockchain")
          default:
            print(submitError.message)
            print(submitError.code)
            self.state = .failure(submitError.message)
          }
        default:
          print(error)
        }
      }
    }
    queue.addOperation(qrDataOperation)
  }
  
  private func showAlert(with text: String) {
    let alert = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
}
