import AVFoundation
import Foundation
import SwiftUI

@MainActor
final class AudioSamplerViewModel: NSObject, ObservableObject {
    @Published var clip: AudioClip?
    @Published var waveform: [CGFloat] = []
    @Published var trimStart: TimeInterval = 0
    @Published var trimEnd: TimeInterval = 0
    @Published var playbackPosition: TimeInterval = 0
    @Published var isPlaying = false
    @Published var isBusy = false
    @Published var statusMessage = "Import a Voice Memo or audio file to start chopping."
    @Published var errorMessage: String?
    @Published var exportedURL: URL?
    @Published var isShowingExporter = false

    private var player: AVAudioPlayer?
    private var playbackTimer: Timer?

    func handleIncomingURL(_ url: URL) {
        if let sharedURL = SharedImportStore.resolveSharedImport(from: url) {
            importAudio(from: sharedURL, shouldCopy: true)
            return
        }

        if url.isFileURL {
            importAudio(from: url, shouldCopy: true)
        }
    }

    func importAudio(from sourceURL: URL, shouldCopy: Bool = true) {
        stopPlayback()
        isBusy = true
        errorMessage = nil
        statusMessage = "Loading \(sourceURL.lastPathComponent)..."

        Task {
            do {
                let workingURL = try shouldCopy ? AudioFileStore.persistImportedFile(from: sourceURL) : sourceURL
                let loadedClip = try Self.makeClip(from: workingURL)
                let loadedWaveform = try await Task.detached {
                    try WaveformAnalyzer.makeWaveform(for: workingURL)
                }.value

                clip = loadedClip
                waveform = loadedWaveform
                trimStart = 0
                trimEnd = loadedClip.duration
                playbackPosition = 0
                statusMessage = "Ready: \(loadedClip.displayName)"
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = "Import failed."
            }
            isBusy = false
        }
    }

    func playOrPause() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    func startPlayback() {
        guard let clip, trimEnd > trimStart else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: clip.url)
            player.currentTime = trimStart
            player.prepareToPlay()
            player.play()

            self.player = player
            isPlaying = true
            playbackPosition = trimStart
            startPlaybackTimer()
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Preview failed."
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func stopAndResetPlayback() {
        stopPlayback()
        playbackPosition = trimStart
    }

    func updateTrimStart(_ value: TimeInterval) {
        guard clip != nil else { return }
        trimStart = min(max(0, value), max(0, trimEnd - 0.05))
        playbackPosition = min(max(playbackPosition, trimStart), trimEnd)
        if isPlaying {
            stopPlayback()
        }
    }

    func updateTrimEnd(_ value: TimeInterval) {
        guard let clip else { return }
        trimEnd = max(min(value, clip.duration), min(clip.duration, trimStart + 0.05))
        playbackPosition = min(max(playbackPosition, trimStart), trimEnd)
        if isPlaying {
            stopPlayback()
        }
    }

    func exportTrimmedWAV() {
        guard let clip else { return }
        guard trimEnd > trimStart else {
            errorMessage = AudioSamplerError.invalidTrimRange.localizedDescription
            return
        }

        let sourceURL = clip.url
        let exportStart = trimStart
        let exportEnd = trimEnd
        let exportName = clip.url.deletingPathExtension().lastPathComponent

        stopPlayback()
        isBusy = true
        errorMessage = nil
        statusMessage = "Rendering 44.1 kHz / 16-bit WAV..."

        Task {
            do {
                let exported = try await Task.detached {
                    try WAVExporter.export(
                        sourceURL: sourceURL,
                        trimStart: exportStart,
                        trimEnd: exportEnd,
                        displayName: exportName
                    )
                }.value

                exportedURL = exported
                isShowingExporter = true
                statusMessage = "WAV ready. Save it to Files."
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = "Export failed."
            }
            isBusy = false
        }
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.player else { return }
                self.playbackPosition = player.currentTime
                if player.currentTime >= self.trimEnd {
                    self.stopPlayback()
                    self.playbackPosition = self.trimStart
                }
            }
        }
    }

    private static func makeClip(from url: URL) throws -> AudioClip {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        guard file.length > 0 else {
            throw AudioSamplerError.cannotReadAudio
        }

        return AudioClip(
            url: url,
            displayName: url.deletingPathExtension().lastPathComponent,
            duration: TimeInterval(file.length) / format.sampleRate,
            sampleRate: format.sampleRate,
            channelCount: Int(format.channelCount)
        )
    }
}
