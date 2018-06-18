import Foundation

extension FileManager {
    static var documentURL: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return url
    }

    static func clearTempDirectory() {
        let instance = self.default
        let dir = NSTemporaryDirectory()
        let contents = try! instance.contentsOfDirectory(atPath: dir)

        try! contents.forEach {[unowned instance] basename in
            let filePath = String(format: "%@%@", dir, basename)
            try instance.removeItem(atPath: filePath)
        }
    }
}
