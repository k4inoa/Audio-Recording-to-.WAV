import AVFoundation
import Foundation

enum WaveformAnalyzer {
    static func makeWaveform(for url: URL, bins: Int = 180) throws -> [CGFloat] {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let totalFrames = AVAudioFramePosition(file.length)

        guard totalFrames > 0, format.channelCount > 0 else {
            throw AudioSamplerError.cannotReadAudio
        }

        let binCount = max(16, bins)
        let framesPerBin = max(1, Int(totalFrames) / binCount)
        var peaks = Array(repeating: Float(0), count: binCount)
        var currentBin = 0
        var framesInBin = 0
        let readCapacity: AVAudioFrameCount = 4096

        while file.framePosition < totalFrames && currentBin < binCount {
            let framesLeft = totalFrames - file.framePosition
            let frameCount = min(readCapacity, AVAudioFrameCount(framesLeft))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                throw AudioSamplerError.cannotReadAudio
            }

            try file.read(into: buffer, frameCount: frameCount)
            guard let channelData = buffer.floatChannelData else { continue }

            for frame in 0..<Int(buffer.frameLength) {
                var samplePeak: Float = 0
                for channel in 0..<Int(format.channelCount) {
                    samplePeak = max(samplePeak, abs(channelData[channel][frame]))
                }

                peaks[currentBin] = max(peaks[currentBin], samplePeak)
                framesInBin += 1

                if framesInBin >= framesPerBin {
                    currentBin = min(currentBin + 1, binCount - 1)
                    framesInBin = 0
                }
            }
        }

        let maxPeak = max(peaks.max() ?? 0, 0.0001)
        return peaks.map { CGFloat(max(0.04, min(1, $0 / maxPeak))) }
    }
}
