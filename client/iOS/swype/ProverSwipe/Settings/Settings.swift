import Foundation

class Settings {

    private static var defaultVideoPreset: AVOutputSettingsPreset {
        let availablePresets = AVOutputSettingsAssistant.availableOutputSettingsPresets()

        guard availablePresets.contains(.preset1280x720) else {
            return availablePresets.first!
        }

        return .preset1280x720
    }

    private static let currentVideoPresetKey: String = "currentVideoPreset"

    public static var currentVideoPreset: AVOutputSettingsPreset {
        get {
            guard let presetRawValue = UserDefaults.standard.string(forKey: currentVideoPresetKey) else {
                return defaultVideoPreset
            }
            return AVOutputSettingsPreset(rawValue: presetRawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: currentVideoPresetKey)
        }
    }

    public static var currentVideoQuality: (width: Int, height: Int) {
        return videoQuality(forPreset: currentVideoPreset)
    }

    public static func videoQuality(forPreset preset: AVOutputSettingsPreset) -> (width: Int, height: Int) {
        let assistant = AVOutputSettingsAssistant(preset: preset)
        let settings = assistant!.videoSettings!
        let settingsWidth = settings[AVVideoWidthKey] as! Int
        let settingsHeight = settings[AVVideoHeightKey] as! Int

        return (settingsWidth, settingsHeight)
    }
}
