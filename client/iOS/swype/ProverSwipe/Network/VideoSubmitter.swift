import Foundation

protocol VideoSubmitterDelegate: class {
    func updateVideoSubmitterStatus(status: VideoSubmitterStatus)
    func updateVideoSubmitterMessage(message: String)
}

enum VideoSubmitterStatus {
    case getInfo
    case createTransaction
    case sendSubmitRequest
    case endSuccess
    case endError
}

class VideoSubmitter {
    
    // MARK: - Dependencies
    let store: DependencyStore
    weak var delegate: VideoSubmitterDelegate?
    
    let queue = OperationQueue()
    
    init(store: DependencyStore) {
        self.store = store
    }
    
    func submit(videoURL: URL, with swypeBlock: Hexadecimal,
                handler: @escaping (String?) -> Void) {
        
        delegate?.updateVideoSubmitterStatus(status: .getInfo)
        
        let helloOperation = HelloOperation(apiProvider: store.apiProvider,
                                            input: store.wallet.hexAddress)
        //helloOperation.input = store.ethereumService.hexAddress
        
        let videoTransactionOperation =
            VideoTransactionOperation(videoURL: videoURL,
                                      swypeBlock: swypeBlock,
                                      wallet: store.wallet)
        
        let helloToVideoTransactionOperation = connect(helloOperation,
                                                       with: videoTransactionOperation)
        
        let submitMediaOperation = SubmitMediaOperation(apiProvider: store.apiProvider)
        submitMediaOperation.completionBlock = { [weak delegate = self.delegate,
            weak submitMediaOperation] in
            
            guard let submitMediaOperation = submitMediaOperation else {
                print("[VideoSubmitter] SubmitMediaOperation is nil")
                delegate?.updateVideoSubmitterMessage(message: "Unknown error while send submit request")
                return
            }
            
            switch submitMediaOperation.output {
            case .success(let result):
                delegate?.updateVideoSubmitterMessage(message: "")
                handler(result)
            case .failure(let error):
                switch error {
                case .notInitialize:
                    delegate?.updateVideoSubmitterMessage(message: "Submit request unknown error")
                case .networkError:
                    delegate?.updateVideoSubmitterMessage(message: "There is netwok issues")
                case .convertResponceError(let text):
                    delegate?.updateVideoSubmitterMessage(message: text)
                }
                print("[VideoSubmitter] submit operation error: \(error)")
                handler(nil)
            }
        }
        
        let videoTransactionToSubmitMediaOperation = connect(videoTransactionOperation,
                                                             with: submitMediaOperation)
        
        queue.addOperations([helloOperation,
                             helloToVideoTransactionOperation,
                             videoTransactionOperation,
                             videoTransactionToSubmitMediaOperation,
                             submitMediaOperation], waitUntilFinished: false)
        
    }
    
    private func connect(_ hello: HelloOperation,
                         with videoTransaction: VideoTransactionOperation) -> BlockOperation {
        
        let interOperation =
            BlockOperation { [weak delegate = self.delegate, weak queue = self.queue,
                weak hello, weak videoTransaction] in
                
                guard let hello = hello else {
                    print("[VideoSubmitter] HelloOperation is nil")
                    delegate?.updateVideoSubmitterMessage(message: "Unknown error")
                    videoTransaction?.info = nil
                    queue?.cancelAllOperations()
                    return
                }
                
                switch hello.output {
                case .success(let result):
                    delegate?.updateVideoSubmitterStatus(status: .createTransaction)
                    delegate?.updateVideoSubmitterMessage(message: "")
                    videoTransaction?.info = result.info
                case .failure(let error):
                    switch error {
                    case .notInitialize:
                        delegate?.updateVideoSubmitterMessage(message: "Hello request unknown error")
                    case .networkError:
                        delegate?.updateVideoSubmitterMessage(message: "There is netwok issues")
                    case .convertResponceError(let text):
                        delegate?.updateVideoSubmitterMessage(message: text)
                    }
                    print("[VideoSubmitter] hello operation error: \(error)")
                    videoTransaction?.info = nil
                    queue?.cancelAllOperations()
                }
        }
        
        interOperation.addDependency(hello)
        videoTransaction.addDependency(interOperation)
        
        return interOperation
    }
    
    private func connect(_ videoTransaction: VideoTransactionOperation,
                         with submitMedia: SubmitMediaOperation) -> BlockOperation {
        
        let interOperation =
            BlockOperation { [weak delegate = self.delegate, weak queue = self.queue,
                weak videoTransaction, weak submitMedia] in
                
                guard let videoTransaction = videoTransaction else {
                    print("[VideoSubmitter] VideoTransactionOperation is nil")
                    delegate?.updateVideoSubmitterMessage(message: "Unknown error")
                    submitMedia?.hex = nil
                    queue?.cancelAllOperations()
                    return
                }
                
                switch videoTransaction.output {
                case .success(let result):
                    delegate?.updateVideoSubmitterStatus(status: .sendSubmitRequest)
                    delegate?.updateVideoSubmitterMessage(message: "")
                    submitMedia?.hex = result.withPrefix
                case .failure(let error):
                    switch error {
                    case .notInitialize, .networkError:
                        delegate?.updateVideoSubmitterMessage(message: "Unknown error while create transaction")
                    case .convertResponceError(let text):
                        delegate?.updateVideoSubmitterMessage(message: text)
                    }
                    print("[VideoSubmitter] transaction operation error: \(error)")
                    submitMedia?.hex = nil
                    queue?.cancelAllOperations()
                }
        }
        
        interOperation.addDependency(videoTransaction)
        submitMedia.addDependency(interOperation)
        
        return interOperation
    }
}
