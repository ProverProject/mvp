import UIKit
import SafariServices

class WalletViewController: UITableViewController, UpdateBalanceBehaviour {
    /*
    private let balanceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Balance"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 11)
        label.alpha = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
     */
    
    private let balanceLabel: UILabel = {
        let label = UILabel()
        
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 30)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.tag = 100
        return label
    }()

    private lazy var navLabelsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [self.balanceLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        return stack
    }()

    // MARK: - IBOutlet
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    @IBOutlet weak var walletAddress: UILabel! {
        didSet {
            walletAddress.text = store.wallet.hexAddress
        }
    }
    
    // MARK: - IBAction
    @IBAction func backButtonAction(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refreshButtonAction(_ sender: UIBarButtonItem) {
        refreshBalance(button: sender, label: balanceLabel, queue: queue, store: store)
    }
    
    @IBAction func copyButtonAction(_ sender: UIButton) {
        UIPasteboard.general.string = walletAddress.text
        showAlert(with: "Successfully copy wallet address to clipboard", title: "Success", handler: nil)
    }
    
    // MARK: - Private properties
    let queue = OperationQueue()
    
    // MARK: - Dependency
    var store: DependencyStore!

    var shouldHideLeftButton: Bool = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let backImage = #imageLiteral(resourceName: "Rectangle")
        let resizable = backImage.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)

        UINavigationBar.appearance().setBackgroundImage(resizable, for: .default)

        let navBar = navigationController!.navigationBar
        navBar.barStyle = .black
        navBar.tintColor = .white

        if (shouldHideLeftButton) {
            navigationItem.leftBarButtonItem = nil
        }

        navigationItem.prompt = "Balance"

        configureNavigationBarLabels()

        tableView.backgroundColor = view.backgroundColor
        // this is for hide separator lines beneath table
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        balanceLabel.attributedText = balanceText(from: store.balance)
    }
    
    // MARK: - Segue
    enum Segue: String {
        case importWalletSegue
        case exportWalletSegue
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueStrID = segue.identifier,
              let segueID = Segue(rawValue: segueStrID)
            else { fatalError("[WalletViewController] Wrong segue ID!") }

        switch segueID {
        case Segue.importWalletSegue:
            if let destination = segue.destination as? ImportWalletViewController {
                destination.store = store
            } else {
                fatalError("[WalletViewController] Cast to ImportWalletViewController failed!")
            }
        case Segue.exportWalletSegue:
            if let destination = segue.destination as? ExportWalletViewController {
                destination.store = store
            } else {
                fatalError("[WalletViewController] Cast to ExportWalletViewController failed!")
            }
        }
    }
}

// MARK: - Private methods
private extension WalletViewController {
    
    func configureNavigationBarLabels() {
        
        let navBar = navigationController!.navigationBar

        navBar.addSubview(navLabelsStack)

        navLabelsStack.centerXAnchor.constraint(equalTo: navBar.centerXAnchor)
                .isActive = true
        navLabelsStack.bottomAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -4)
                .isActive = true
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
    
    func balanceText(from balance: Double) -> NSMutableAttributedString {
        
        let text = NSMutableAttributedString(string: "\(String(balance)) ")
        let attachment = NSTextAttachment()
        attachment.image = #imageLiteral(resourceName: "proofSymbol")
        let imageString = NSAttributedString(attachment: attachment)
        text.append(imageString)
        
        return text
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
