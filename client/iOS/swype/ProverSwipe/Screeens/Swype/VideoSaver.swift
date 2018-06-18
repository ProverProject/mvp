import Foundation
import Photos

protocol VideoSaverNotifier: class {
    func showAlert(text: String)
}

class VideoSaver: NSObject {
    weak var delegate: VideoSaverNotifier?

    func saveVideo(url: URL) {
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
            switch status {
            case .authorized:
                self?.delegate?.showAlert(text: "Video will be saved to camera roll.")
                UISaveVideoAtPathToSavedPhotosAlbum(url.relativePath,
                                                    self,
                                                    #selector(self!.onVideoSaved),
                                                    nil)
            case .denied:
                self?.delegate?.showAlert(text: "Video will be saved to documents folder. If you want to save video to camera roll allow access to Photos in Settings")
                self?.saveToDocuments(from: url, withExtension: "mp4")
                FileManager.clearTempDirectory()
            case .notDetermined, .restricted:
                print("[VideoDetector] authorization status: \(status)")
                FileManager.clearTempDirectory()
            }
        }
    }
    
    private func saveToDocuments(from url: URL, withExtension fileExtension: String) {
        
        guard let data = try? Data(contentsOf: url) else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let name = dateFormatter.string(from: Date())
        
        let urlToSave = FileManager.documentURL.appendingPathComponent("\(name).\(fileExtension)")
        try? data.write(to: urlToSave)
    }

    @objc private func onVideoSaved(video: String?, didFinishSavingWithError: Error?, contextInfo: Any?) {
        FileManager.clearTempDirectory()
    }
}
