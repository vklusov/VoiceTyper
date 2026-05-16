import SwiftUI

struct VTConfig {
    var serverHost: String = "127.0.0.1"
    var serverPort: Int = 9001
    var whisperModel: WhisperModelSize = .small
    var cleanWithLLM: Bool = false
    var language: VTTranscriptionLanguage = .auto
}

enum WhisperModelSize: String, CaseIterable {
    case tiny = "tiny"
    case base = "base"
    case small = "small"
    case medium = "medium"
    case largeV3 = "large-v3"

    var displayName: String {
        switch self {
        case .tiny: return "Tiny (быстрый)"
        case .base: return "Base"
        case .small: return "Small (рекомендуется)"
        case .medium: return "Medium"
        case .largeV3: return "Large v3 (точный)"
        }
    }
}

enum VTTranscriptionLanguage: String, CaseIterable {
    case auto = "auto"
    case ru = "ru"
    case en = "en"

    var displayName: String {
        switch self {
        case .auto: return "Автоопределение"
        case .ru: return "Русский"
        case .en: return "English"
        }
    }
}
