import Foundation

struct AudioClip: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let displayName: String
    let duration: TimeInterval
    let sampleRate: Double
    let channelCount: Int

    var detailLine: String {
        "\(Self.timeString(duration)) · \(Int(sampleRate)) Hz · \(channelCount) ch"
    }

    static func timeString(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "00:00.000" }
        let totalMilliseconds = max(0, Int((seconds * 1000).rounded()))
        let minutes = totalMilliseconds / 60_000
        let remaining = totalMilliseconds % 60_000
        let wholeSeconds = remaining / 1000
        let milliseconds = remaining % 1000
        return String(format: "%02d:%02d.%03d", minutes, wholeSeconds, milliseconds)
    }
}
