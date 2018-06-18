import UIKit

class InfoView: UIView {
    
    // MARK: - IBOutlet
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    
    func message(_ text: String) {
        messageLabel.setText(text)
    }
}

// MARK: - SwypeScreenState
extension InfoView: SwypeScreenState {
    
    func update(by state: SwypeViewController.State) {
        
        print("[InfoView] switch to \(state)")
        
        switch state {
        case .readyToRecord:
            titleLabel.setText("Press button to start record")
        case .waitSwype:
            titleLabel.setText("Wait responce with swype code")
        case .waitRoundMovement:
            titleLabel.setText("Make round move")
        case .prepareForStart:
            titleLabel.setText("Do not move the phone")
        case .detection:
            titleLabel.setText("Connect circles")
        case .finishDetection:
            titleLabel.setText("Detection is finished")
        case .submitVideo:
            titleLabel.setText("Submitting video")
        }
    }
}

// MARK: - VideoSubmitterDelegate
extension InfoView: VideoSubmitterDelegate {
    
    func updateVideoSubmitterStatus(status: VideoSubmitterStatus) {
        
        let text: String
        
        switch status {
        case .getInfo:
            text = "Get info from ethereum node"
        case .createTransaction:
            text = "Create transaction from video"
        case .sendSubmitRequest:
            text = "Send submit request"
        case .endError:
            text = "End submit with error"
        case .endSuccess:
            text = "Success submit video"
        }
        
//        message(text)
    }
    
    func updateVideoSubmitterMessage(message: String) {
        print("[SwypeViewController] get message from video submitter: \(message)")
        
        switch message {
        case "insufficient funds for gas * price + value":
            self.message("insufficient funds on the balance")
        case "replacement transaction underpriced":
            self.message("You can not execute the query until the previous transaction is placed in the blockchain")
        default:
            self.message(message)
        }
    }
}
