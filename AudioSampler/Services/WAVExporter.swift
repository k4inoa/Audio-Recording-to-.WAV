import AVFoundation
import Foundation

enum WAVExporter {
    static let targetSampleRate: Double = 44_100
    static let bitDepth = 16

    static func export(sourceURL: URL, trimStart: TimeInterval, trimEnd: TimeInterval, displayName: String) throws -> URL {
        guard trimEnd > trimStart else {
            throw AudioSamplerError.invalidTrimRange
        }

        let inputFile = try AVAudioFile(forReading: sourceURL)
        let inputFormat = inputFile.processingFormat
        let channelCount = inputFormat.channelCount
        let startFrame = AVAudioFramePosition(trimStart * inputFormat.sampleRate)
        let endFrame = min(AVAudioFramePosition(trimEnd * inputFormat.sampleRate), inputFile.length)
        let framesToRead = endFrame - startFrame

        guard framesToRead > 0 else {
            throw AudioSamplerError.invalidTrimRange
        }

        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: targetSampleRate,
            AVNumberOfChannelsKey: Int(channelCount),
            AVLinearPCMBitDepthKey: bitDepth,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        guard let outputFormat = AVAudioFormat(settings: outputSettings) else {
            throw AudioSamplerError.exportFailed
        }

        let exports = try AudioFileStore.exportsDirectory()
        let baseName = displayName.isEmpty ? "Sample" : displayName
        let outputURL = AudioFileStore.uniqueURL(
            in: exports,
            baseName: baseName + "-trimmed",
            extension: "wav"
        )

        let outputFile = try AVAudioFile(forWriting: outputURL, settings: outputSettings)
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw AudioSamplerError.exportFailed
        }

        inputFile.framePosition = startFrame
        var remainingFrames = framesToRead
        let chunkCapacity: AVAudioFrameCount = 4096

        while remainingFrames > 0 {
            let framesThisChunk = min(chunkCapacity, AVAudioFrameCount(remainingFrames))
            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: framesThisChunk) else {
                throw AudioSamplerError.exportFailed
            }

            try inputFile.read(into: inputBuffer, frameCount: framesThisChunk)
            if inputBuffer.frameLength == 0 {
                break
            }

            let ratio = outputFormat.sampleRate / inputFormat.sampleRate
            let outputCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 1024
            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputCapacity) else {
                throw AudioSamplerError.exportFailed
            }

            var suppliedInput = false
            var conversionError: NSError?
            converter.convert(to: outputBuffer, error: &conversionError) { _, status in
                if suppliedInput {
                    status.pointee = .noDataNow
                    return nil
                }
                suppliedInput = true
                status.pointee = .haveData
                return inputBuffer
            }

            if let conversionError {
                throw conversionError
            }

            if outputBuffer.frameLength > 0 {
                try outputFile.write(from: outputBuffer)
            }

            remainingFrames -= AVAudioFramePosition(inputBuffer.frameLength)
        }

        return outputURL
    }
}
