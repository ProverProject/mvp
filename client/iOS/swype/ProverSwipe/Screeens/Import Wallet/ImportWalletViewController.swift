import UIKit
import FileBrowser

class ImportWalletViewController: UIViewController, UpdateBalanceBehaviour {
  
  // MARK: - IBOutlet
  @IBOutlet weak var walletFileLabel: UILabel!
  @IBOutlet weak var showHidePasswordButton: UIButton!
  @IBOutlet weak var passwordTextField: UITextField!
  
  // MARK: - IBAction
  @IBAction func backButtonAction(_ sender: UIBarButtonItem) {
    navigationController?.popViewController(animated: true)
  }
  
  @IBAction func refreshButtonAction(_ sender: UIBarButtonItem) {
    guard let label = navigationController?.navigationBar.viewWithTag(100) as? UILabel else {
      print("Can't find balance label")
      return
    }
    refreshBalance(button: sender, label: label, queue: queue, store: store)
  }
  
  @IBAction func endInputText(_ sender: UITextField) {
  }
  
  @IBAction func browserButtonAction(_ sender: UIButton) {

    let fileBrowser = FileBrowser()
    fileBrowser.didSelectFile = { (file: FBFile) in
      self.walletFileLabel.text = file.displayName
      self.walletPath = file.filePath
    }
    present(fileBrowser, animated: true, completion: nil)
  }

  @IBAction func showHidePasswordButtonAction(_ sender: UIButton) {
    isPasswordSecured = !isPasswordSecured
  }
  
  @IBAction func openButtonAction(_ sender: UIButton) {
    
    guard let filePath = walletPath else {
      showAlert(with: "First choose file")
      return
    }
    
    guard let data = try? Data(contentsOf: filePath) else {
      showAlert(with: "Can't read file")
      return
    }
    
    guard let password = passwordTextField.text, password != "" else {
      showAlert(with: "Please type password")
      return
    }
    
    let result = store.wallet.importWallet(data, passphrase: password)
    switch result {
    case true:
      showAlert(with: "Successfully import new wallet", title: "Success") { [weak self] (_) in
        self?.walletFileLabel.text = nil
        self?.walletPath = nil
        self?.passwordTextField.text = nil
      }
    case false:
      showAlert(with: "Can't import new wallet") { [weak self] (_) in
        self?.walletFileLabel.text = nil
        self?.walletPath = nil
        self?.passwordTextField.text = nil
      }
    }
  }
  
  @IBAction func cancelButtonAction(_ sender: UIButton) {
    navigationController?.popViewController(animated: true)
  }
  
  // MARK: - Private properties
  let queue = OperationQueue()

  var walletPath: URL?
  
  var isPasswordSecured = true {
    didSet {
      passwordTextField.isSecureTextEntry = isPasswordSecured
      switch isPasswordSecured {
      case true:
        showHidePasswordButton.setImage(#imageLiteral(resourceName: "show"), for: .normal)
      case false:
        showHidePasswordButton.setImage(#imageLiteral(resourceName: "hide"), for: .normal)
      }
    }
  }
  
  // MARK: - Dependency
  var store: DependencyStore!
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
  }
}

// MARK: - Private methods
private extension ImportWalletViewController {
  
  func showAlert(with text: String,
                 title: String = "Error",
                 handler: ((UIAlertAction) -> Void)? = nil) {
    let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handler))
    self.present(alert, animated: true, completion: nil)
  }
}

// MARK: - UIDocumentPickerDelegate
extension ImportWalletViewController: UIDocumentPickerDelegate {
  
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    
    print("import result : \(url)")
  }
  
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    
    print("view was cancelled")
    dismiss(animated: true, completion: nil)
  }
}
