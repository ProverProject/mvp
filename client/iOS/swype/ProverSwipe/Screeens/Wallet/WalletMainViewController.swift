import UIKit
import SafariServices

class WalletViewController: UITableViewController {
  
  // MARK: - IBOutlet
  private let balanceTitleLabel: UILabel = {
    let label = UILabel()
    label.text = "Balance"
    label.textColor = .white
    label.font = UIFont.systemFont(ofSize: 11)
    label.alpha = 0.5
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  private let balanceLabel: UILabel = {
    let label = UILabel()
    let text = NSMutableAttributedString(string: "0.0 ")
    let attachment = NSTextAttachment()
    attachment.image = #imageLiteral(resourceName: "proofSymbol")
    let imageString = NSAttributedString(attachment: attachment)
    text.append(imageString)
    label.attributedText = text
    label.textColor = .white
    label.font = UIFont.systemFont(ofSize: 30)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  @IBOutlet weak var refreshButton: UIBarButtonItem!
  
  @IBOutlet weak var walletAddress: UILabel! {
    didSet {
      walletAddress.text = store.ethereumService.hexAddress
    }
  }
  
  // MARK: - IBAction
  @IBAction func backButtonAction(_ sender: UIBarButtonItem) {
    navigationController?.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func refreshButtonAction(_ sender: UIBarButtonItem) {
    
    startAnimationUIBarButtonItem(button: refreshButton)
    
    let operation = GetInfoOperation(hex: store.ethereumService.hexAddress,
                                     apiProvider: store.apiProvider)
    
    operation.completionBlock = { [weak self] in
      
      self?.stopAnimationUIBarButtonItem(button: self!.refreshButton)
      
      DispatchQueue.main.async {
        
        guard let balance = operation.output?.value?.ethBalance else { return }
        
        let significantDigits = Int(Double(balance.toInt64!) * pow(10, -10))
        let actualNumber = Double(significantDigits) * pow(10, -8)
        
        let text = NSMutableAttributedString(string: "\(actualNumber) ")
        let attachment = NSTextAttachment()
        attachment.image = #imageLiteral(resourceName: "proofSymbol")
        let imageString = NSAttributedString(attachment: attachment)
        text.append(imageString)
        
        UIView.animate(withDuration: 0.5, animations: {
          self?.balanceLabel.alpha = 0.0
        }, completion: { finished in
          if finished {
            UIView.animate(withDuration: 0.5, animations: {
              self?.balanceLabel.attributedText = text
              self?.balanceLabel.alpha = 1.0
            })
          }
        })
      }
    }
    queue.addOperation(operation)
  }
  
  @IBAction func copyButtonAction(_ sender: UIButton) {
    UIPasteboard.general.string = walletAddress.text
    showAlert(with: "Successfully copy wallet address to clipboard", title: "Success", handler: nil)
  }
  
  // MARK: - Private properties
  let queue = OperationQueue()
  
  // MARK: - Dependency
  var store: DependencyStore!
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureNavigationBar()
    configureNavigationTitle()
    
    tableView.backgroundColor = view.backgroundColor
    // this is for hide separator lines beneath table
    tableView.tableFooterView = UIView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  private func configureNavigationBar() {
    guard let navigationBar = navigationController?.navigationBar else { return }
    let size = CGSize(width: navigationBar.bounds.width,
                      height: navigationBar.bounds.height + UIApplication.shared.statusBarFrame.height)
    let image = #imageLiteral(resourceName: "Rectangle").resizedImage(newSize: size)
    navigationBar.barTintColor = UIColor(patternImage: image)
    navigationBar.tintColor = .white
    
  }
  
  // MARK: - Segue
  enum Segue: String {
    case importWalletSegue
    case exportWalletSegue
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    guard let identifier = segue.identifier else { return }
    
    switch identifier {
    case Segue.importWalletSegue.rawValue:
      if let destination = segue.destination as? ImportWalletViewController {
        destination.store = store
      }
    case Segue.exportWalletSegue.rawValue:
      if let destination = segue.destination as? ExportWalletViewController {
        destination.store = store
      }
    default:
      fatalError("Unexpected segue")
    }
  }
}

// MARK: - Private methods
private extension WalletViewController {
  
  func configureNavigationTitle() {
    
    guard let bar = navigationController?.navigationBar else { return }
    
    bar.addSubview(balanceTitleLabel)
    bar.addSubview(balanceLabel)
    
    balanceTitleLabel.topAnchor
      .constraint(equalTo: bar.topAnchor, constant: 10).isActive = true
    balanceTitleLabel.leftAnchor
      .constraint(equalTo: bar.leftAnchor, constant: 100).isActive = true
    balanceTitleLabel.rightAnchor
      .constraint(equalTo: bar.rightAnchor, constant: 100).isActive = true
    
    balanceLabel.topAnchor
      .constraint(equalTo: balanceTitleLabel.bottomAnchor, constant: 2).isActive = true
    balanceLabel.leftAnchor
      .constraint(equalTo: balanceTitleLabel.leftAnchor).isActive = true
    balanceLabel.rightAnchor
      .constraint(equalTo: balanceTitleLabel.rightAnchor).isActive = true
  }
  
  func showSafariView() {
    print("show safari view")
    guard let url = URL(string: "https://mvp.prover.io/#get_ropsten_testnet_ether") else {
      print("Can't create URL")
      return
    }
    let safariView = SFSafariViewController(url: url)
    present(safariView, animated: true, completion: nil)
  }
  
  func showAlert(with text: String,
                 title: String = "Error",
                 handler: ((UIAlertAction) -> Void)? = nil) {
    let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handler))
    self.present(alert, animated: true, completion: nil)
  }
}

// MARK: - UITableViewDelegate
extension WalletViewController {
  
  override func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.row == 0 {
      return UITableViewAutomaticDimension
    } else {
      return 48
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    tableView.deselectRow(at: indexPath, animated: true)
    
    switch indexPath.row {
    case 1:
      performSegue(withIdentifier: Segue.importWalletSegue.rawValue, sender: nil)
    case 2:
      performSegue(withIdentifier: Segue.exportWalletSegue.rawValue, sender: nil)
    case 3:
      showSafariView()
    default:
      print(indexPath)
    }
  }
}

// MARK: - Animation
extension WalletViewController {
  
  func startAnimationUIBarButtonItem(button: UIBarButtonItem) {
    
    DispatchQueue.main.async {
      UIView.animate(withDuration: 0.1,
                     delay: 0,
                     options: [.repeat, .curveLinear],
                     animations: {
                      let transform = CGAffineTransform(rotationAngle: .pi)
                      guard let view = button.value(forKey: "view") as? UIView else {
                        print("Can't get view from UIBarButtonItem")
                        return
                      }
                      view.transform = transform
      }, completion: nil)
    }
  }
  
  func stopAnimationUIBarButtonItem(button: UIBarButtonItem) {
    
    DispatchQueue.main.async {
      UIView.animate(withDuration: 0.1,
                     delay: 0,
                     options: [.beginFromCurrentState, .curveLinear],
                     animations: {
                      
                      guard let view = button.value(forKey: "view") as? UIView else {
                        print("Can't get view from UIBarButtonItem")
                        return
                      }
                      view.transform = CGAffineTransform.identity
      }, completion: nil)
    }
  }
}
