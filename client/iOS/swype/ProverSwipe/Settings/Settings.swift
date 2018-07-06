import Foundation

class Settings {

    private static var defaultVideoPreset: AVOutputSettingsPreset {
        let availablePresets = AVOutputSettingsAssistant.availableOutputSettingsPresets()
                                                        .reversed()
        guard availablePresets.contains(.preset1920x1080) else {
            return availablePresets.first!
        }

        return .preset1920x1080
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
}
