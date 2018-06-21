import Foundation

protocol MergerDelegate: class {
    func showAlert(text: String)
}

class Merger: CanMerge {
    
    weak var delegate: MergerDelegate?
    
    private var fileURL: URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent("merged_video.mp4")
    }
    
    func merge(videoURL: URL, audioURL: URL, handler: @escaping (URL, URL, URL) -> Void) {
        
        let mixComposition = AVMutableComposition()
        
        let videoAsset = AVAsset(url: videoURL)
        guard let videoTrack = mixComposition
            .addMutableTrack(withMediaType: .video,
                             preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        // Force the resulted video to be always played in landscape mode
        videoTrack.preferredTransform = CGAffineTransform(rotationAngle: .pi*3/2)

        do {
            try videoTrack
                .insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration),
                                 of: videoAsset.tracks(withMediaType: .video)[0],
                                 at: kCMTimeZero)
        } catch {
            delegate?.showAlert(text: "Can't merge video and audio")
            print("[Merger] failed to load video track with error: \(error)")
        }
        
        let audioAsset = AVAsset(url: audioURL)
        guard let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio,
                                                              preferredTrackID: 0) else { return }
        do {
            try audioTrack
                .insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration),
                                 of: audioAsset.tracks(withMediaType: .audio)[0],
                                 at: kCMTimeZero)
        } catch {
            delegate?.showAlert(text: "Can't merge video and audio")
            print("[Merger] failed to load audio track with error: \(error)")
        }
        
        guard let exporter =
            AVAssetExportSession(asset: mixComposition,
                                 presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = fileURL
        exporter.outputFileType = AVFileType.mp4
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronously { [unowned self] in handler(videoURL, audioURL, self.fileURL) }
    }
}
