import Foundation

enum AudioSamplerError: LocalizedError {
    case appGroupUnavailable
    case unsupportedAudio
    case invalidTrimRange
    case cannotReadAudio
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "The shared import folder is unavailable. Check the App Group entitlement before using the share extension."
        case .unsupportedAudio:
            return "This file does not look like a supported audio recording."
        case .invalidTrimRange:
            return "Set a trim range with a real duration before exporting."
        case .cannotReadAudio:
            return "The recording could not be opened."
        case .exportFailed:
            return "The WAV export failed."
        }
    }
}
