import Foundation

protocol AudioRecorderDelegate: class {
    func showAlert(text: String)
}

class AudioRecorder: NSObject, AVAudioRecorderDelegate, Recorder {
    
    var recordingSession = AVAudioSession.sharedInstance()
    var audioRecorder: AVAudioRecorder!
    
    weak var delegate: AudioRecorderDelegate!
    
    private var audioFileURL: URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent("audio_track.mp4")
    }
    
    init(delegate: AudioRecorderDelegate) {
        self.delegate = delegate
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { allowed in
                if !allowed {
                    delegate.showAlert(text: "Can't set up audio recording.")
                    print("[AudioRecorder] recording not allowed")
                }
            }
        } catch {
            delegate.showAlert(text: "Can't set up audio recording.")
            print("[AudioRecorder] can't set category or active")
        }
    }
    
    func startRecord() {
        
        checkOutput()
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
        } catch {
            delegate.showAlert(text: "Can't set up audio recording.")
            print("[AudioRecorder] create audio recorder")
        }
    }
    
    func stopRecord(handler: (URL?) -> Void) {
        
        audioRecorder.stop()
        audioRecorder = nil
        handler(audioFileURL)
    }
    
    private func checkOutput() {
        if FileManager.default.fileExists(atPath: audioFileURL.relativePath) {
            do {
                try FileManager.default.removeItem(at: audioFileURL)
            } catch {
                print("[AudioRecorder] FileManager can't delete file at \(audioFileURL)")
            }
        }
    }
}
