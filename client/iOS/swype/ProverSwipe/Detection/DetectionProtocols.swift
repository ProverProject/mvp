import Foundation

protocol Recorder: class {
    func startRecord()
    func stopRecord(handler: (URL?) -> Void)
}

protocol CanMerge {
    func merge(videoURL: URL, audioURL: URL, handler: @escaping (URL, URL, URL) -> Void)
}
