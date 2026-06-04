import SwiftUI

enum AnalogPalette {
    static let base = Color(red: 0.035, green: 0.040, blue: 0.040)
    static let panel = Color(red: 0.080, green: 0.095, blue: 0.095)
    static let panelRaised = Color(red: 0.130, green: 0.145, blue: 0.140)
    static let warmWhite = Color(red: 0.940, green: 0.930, blue: 0.860)
    static let lime = Color(red: 0.660, green: 0.980, blue: 0.350)
    static let cyan = Color(red: 0.250, green: 0.880, blue: 0.900)
    static let amber = Color(red: 1.000, green: 0.660, blue: 0.240)
    static let magenta = Color(red: 0.940, green: 0.320, blue: 0.540)
}

enum PadPalette {
    static let base = Color(red: 0.035, green: 0.035, blue: 0.055)
    static let surface = Color(red: 0.115, green: 0.120, blue: 0.160)
    static let ink = Color(red: 0.970, green: 0.970, blue: 0.930)
    static let mint = Color(red: 0.290, green: 0.960, blue: 0.700)
    static let cyan = Color(red: 0.180, green: 0.780, blue: 1.000)
    static let pink = Color(red: 1.000, green: 0.250, blue: 0.560)
    static let yellow = Color(red: 1.000, green: 0.830, blue: 0.220)
    static let purple = Color(red: 0.610, green: 0.380, blue: 1.000)
    static let orange = Color(red: 1.000, green: 0.500, blue: 0.190)

    static let padTints = [
        cyan,
        pink,
        yellow,
        mint,
        purple,
        orange,
        Color(red: 0.420, green: 0.650, blue: 1.000),
        Color(red: 1.000, green: 0.390, blue: 0.770),
        Color(red: 0.700, green: 1.000, blue: 0.300)
    ]
}

struct PadBoardBackground: View {
    var body: some View {
        PadPalette.base
            .overlay {
                LinearGradient(
                    colors: [
                        PadPalette.purple.opacity(0.22),
                        Color.clear,
                        PadPalette.cyan.opacity(0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .overlay {
                DotPattern(spacing: 24)
                    .fill(Color.white.opacity(0.045))
            }
            .ignoresSafeArea()
    }
}

struct DAWGridBackground: View {
    var body: some View {
        AnalogPalette.base
            .overlay {
                GridPattern(minor: 16, major: 64)
                    .stroke(AnalogPalette.lime.opacity(0.065), lineWidth: 1)
            }
            .overlay {
                ScanlinePattern(spacing: 6)
                    .stroke(Color.black.opacity(0.22), lineWidth: 1)
            }
            .ignoresSafeArea()
    }
}

struct PadEditorGrid: View {
    var body: some View {
        GridPattern(minor: 24, major: 96)
            .stroke(Color.white.opacity(0.06), lineWidth: 1)
            .overlay {
                GridPattern(minor: 96, major: 192)
                    .stroke(PadPalette.purple.opacity(0.12), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct EditorGrid: View {
    var body: some View {
        GridPattern(minor: 20, major: 80)
            .stroke(AnalogPalette.cyan.opacity(0.12), lineWidth: 1)
            .overlay {
                GridPattern(minor: 80, major: 160)
                    .stroke(AnalogPalette.amber.opacity(0.11), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct GridPattern: Shape {
    let minor: CGFloat
    let major: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        var x: CGFloat = 0
        while x <= rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += minor
        }

        var y: CGFloat = 0
        while y <= rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += minor
        }

        x = 0
        while x <= rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += major
        }

        return path
    }
}

struct DotPattern: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y: CGFloat = 0
        while y <= rect.height {
            var x: CGFloat = 0
            while x <= rect.width {
                path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                x += spacing
            }
            y += spacing
        }
        return path
    }
}

struct ScanlinePattern: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y: CGFloat = 0
        while y <= rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += spacing
        }
        return path
    }
}

struct WaveformBars: View {
    let samples: [CGFloat]

    var body: some View {
        GeometryReader { proxy in
            let barWidth = max(3, proxy.size.width / CGFloat(max(samples.count, 1)) * 0.62)
            HStack(alignment: .center, spacing: max(1, barWidth * 0.55)) {
                ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    PadPalette.yellow,
                                    PadPalette.pink,
                                    PadPalette.cyan
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: barWidth, height: max(6, proxy.size.height * sample))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct SelectionShade: View {
    @EnvironmentObject private var viewModel: AudioSamplerViewModel
    let clip: AudioClip

    var body: some View {
        GeometryReader { proxy in
            let startX = xPosition(for: viewModel.trimStart, width: proxy.size.width)
            let endX = xPosition(for: viewModel.trimEnd, width: proxy.size.width)

            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black.opacity(0.58))
                    .frame(width: max(0, startX))
                Rectangle()
                    .fill(PadPalette.mint.opacity(0.08))
                    .frame(width: max(0, endX - startX))
                Rectangle()
                    .fill(Color.black.opacity(0.58))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func xPosition(for time: TimeInterval, width: CGFloat) -> CGFloat {
        guard clip.duration > 0 else { return 0 }
        return CGFloat(time / clip.duration) * width
    }
}

struct Playhead: View {
    @EnvironmentObject private var viewModel: AudioSamplerViewModel
    let clip: AudioClip

    var body: some View {
        GeometryReader { proxy in
            let x = xPosition(for: viewModel.playbackPosition, width: proxy.size.width)
            Rectangle()
                .fill(PadPalette.yellow.opacity(0.95))
                .frame(width: 3)
                .position(x: x, y: proxy.size.height / 2)
        }
    }

    private func xPosition(for time: TimeInterval, width: CGFloat) -> CGFloat {
        guard clip.duration > 0 else { return 0 }
        return CGFloat(time / clip.duration) * width
    }
}

struct TrimHandle: View {
    enum Edge {
        case start
        case end
    }

    @EnvironmentObject private var viewModel: AudioSamplerViewModel
    let edge: Edge
    let clip: AudioClip
    let width: CGFloat

    var body: some View {
        let time = edge == .start ? viewModel.trimStart : viewModel.trimEnd
        let x = xPosition(for: time)

        VStack(spacing: 0) {
            Text(edge == .start ? "IN" : "OUT")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(PadPalette.ink)
                .padding(.horizontal, 5)
                .frame(height: 18)
                .background(edge == .start ? PadPalette.mint : PadPalette.pink)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Rectangle()
                .fill(edge == .start ? PadPalette.mint : PadPalette.pink)
                .frame(width: 3)
        }
        .frame(width: 42)
        .position(x: x, y: 124)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let clampedX = min(max(0, value.location.x), width)
                    let snapped = snappedTime(for: clampedX)
                    if edge == .start {
                        viewModel.updateTrimStart(snapped)
                    } else {
                        viewModel.updateTrimEnd(snapped)
                    }
                }
        )
        .accessibilityLabel(edge == .start ? "Trim start" : "Trim end")
    }

    private func xPosition(for time: TimeInterval) -> CGFloat {
        guard clip.duration > 0 else { return 0 }
        return CGFloat(time / clip.duration) * width
    }

    private func snappedTime(for x: CGFloat) -> TimeInterval {
        guard width > 0 else { return 0 }
        let raw = TimeInterval(x / width) * clip.duration
        let grid = max(0.01, clip.duration / 64)
        return (raw / grid).rounded() * grid
    }
}

struct TimeRuler: View {
    @EnvironmentObject private var viewModel: AudioSamplerViewModel
    let clip: AudioClip

    var body: some View {
        VStack {
            HStack {
                Text(AudioClip.timeString(viewModel.trimStart))
                Spacer()
                Text(AudioClip.timeString(viewModel.playbackPosition))
                Spacer()
                Text(AudioClip.timeString(viewModel.trimEnd))
            }
            Spacer()
        }
        .font(.system(.caption2, design: .rounded, weight: .black))
        .foregroundStyle(PadPalette.ink.opacity(0.78))
        .padding(10)
    }
}
