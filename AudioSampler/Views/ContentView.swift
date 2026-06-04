import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AudioSamplerViewModel
    @State private var isShowingImporter = false

    var body: some View {
        ZStack(alignment: .top) {
            PadBoardBackground()

            VStack(spacing: 14) {
                HeaderBar(isShowingImporter: $isShowingImporter)
                SampleHero(isShowingImporter: $isShowingImporter)

                WaveformEditor()
                    .frame(height: 250)

                TransportBar()
                ExportPanel()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if viewModel.isBusy {
                BusyOverlay(message: viewModel.statusMessage)
            }
        }
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.xSmall ... .large)
        .fileImporterSheet(isPresented: $isShowingImporter)
        .fileExporterSheet(url: viewModel.exportedURL, isPresented: $viewModel.isShowingExporter)
        .alert("Audio Sampler", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct HeaderBar: View {
    @EnvironmentObject private var viewModel: AudioSamplerViewModel
    @Binding var isShowingImporter: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("WAV SAMPLER")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(PadPalette.ink)
                Text(viewModel.clip?.detailLine ?? "IMPORT -> TRIM -> EXPORT WAV")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(PadPalette.mint.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 8)

            Button {
                isShowingImporter = true
            } label: {
                Label("Import", systemImage: "plus")
            }
            .buttonStyle(PadButtonStyle(tint: PadPalette.pink, minWidth: 104))
        }
    }
}

private struct SampleHero: View {
    @EnvironmentObject private var viewModel: AudioSamplerViewModel
    @Binding var isShowingImporter: Bool

    var body: some View {
        Button {
            if viewModel.clip == nil {
                isShowingImporter = true
            } else {
                viewModel.playOrPause()
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [PadPalette.cyan, PadPalette.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: viewModel.clip == nil ? "waveform.badge.plus" : (viewModel.isPlaying ? "pause.fill" : "play.fill"))
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(PadPalette.ink)
                }
                .frame(width: 74, height: 74)

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.clip?.displayName ?? "Load a Voice Memo")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(PadPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(viewModel.clip == nil ? "Tap to choose audio" : "Tap to preview current trim")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(PadPalette.ink.opacity(0.62))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(12)
            .background(PadPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: PadPalette.cyan.opacity(0.16), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
}

private struct WaveformEditor: View {
    @EnvironmentObject private var viewModel: AudioSamplerViewModel

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 22)
                    .fill(PadPalette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(PadPalette.purple.opacity(0.42), lineWidth: 1)
                    )

                PadEditorGrid()

                if let clip = viewModel.clip {
                    WaveformBars(samples: viewModel.waveform)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 38)

                    SelectionShade(clip: clip)
                        .environmentObject(viewModel)

                    Playhead(clip: clip)
                        .environmentObject(viewModel)

                    TrimHandle(edge: .start, clip: clip, width: proxy.size.width)
                        .environmentObject(viewModel)

                    TrimHandle(edge: .end, clip: clip, width: proxy.size.width)
                        .environmentObject(viewModel)

                    TimeRuler(clip: clip)
                        .environmentObject(viewModel)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 44, weight: .black))
                            .foregroundStyle(PadPalette.yellow)
                        Text("NO AUDIO LOADED")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(PadPalette.ink)
                        Text("Import audio, trim the hit, export a WAV.")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(PadPalette.ink.opacity(0.62))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

private struct TransportBar: View {
    @EnvironmentObject private var viewModel: AudioSamplerViewModel

    var body: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.playOrPause()
            } label: {
                Label(viewModel.isPlaying ? "Pause" : "Play", systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(PadButtonStyle(tint: PadPalette.mint, minWidth: 116))
            .disabled(viewModel.clip == nil)

            Button {
                viewModel.stopAndResetPlayback()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(PadButtonStyle(tint: PadPalette.purple, minWidth: 98))
            .disabled(viewModel.clip == nil)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text("IN \(AudioClip.timeString(viewModel.trimStart))")
                Text("OUT \(AudioClip.timeString(viewModel.trimEnd))")
            }
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(PadPalette.ink.opacity(0.78))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        }
    }
}

private struct ExportPanel: View {
    @EnvironmentObject private var viewModel: AudioSamplerViewModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.clip?.displayName ?? "No clip loaded")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(PadPalette.ink)
                    .lineLimit(1)
                Text(viewModel.statusMessage)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(PadPalette.ink.opacity(0.58))
                    .lineLimit(2)
            }

            Spacer()

            Button {
                viewModel.exportTrimmedWAV()
            } label: {
                Label("WAV", systemImage: "square.and.arrow.up.fill")
            }
            .buttonStyle(PadButtonStyle(tint: PadPalette.yellow, minWidth: 92))
            .disabled(viewModel.clip == nil || viewModel.isBusy)
        }
        .padding(14)
        .background(PadPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct BusyOverlay: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(PadPalette.yellow)
            Text(message)
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(PadPalette.ink.opacity(0.82))
        }
        .padding(18)
        .background(PadPalette.surface.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
    }
}

private struct PadButtonStyle: ButtonStyle {
    let tint: Color
    var minWidth: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundStyle(PadPalette.ink)
            .padding(.horizontal, 13)
            .frame(minWidth: minWidth, minHeight: 42)
            .background(tint.opacity(configuration.isPressed ? 0.62 : 0.95))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.28), radius: configuration.isPressed ? 4 : 10, x: 0, y: configuration.isPressed ? 3 : 7)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
