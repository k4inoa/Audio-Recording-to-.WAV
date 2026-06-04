import SwiftUI
import UniformTypeIdentifiers

struct AudioDocumentImporter: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio, .mpeg4Audio, .mp3, .wav, .aiff], asCopy: false)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

struct AudioDocumentExporter: UIViewControllerRepresentable {
    let url: URL
    let onDone: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDone: onDone)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDone: () -> Void

        init(onDone: @escaping () -> Void) {
            self.onDone = onDone
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onDone()
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onDone()
        }
    }
}

private struct FileImporterSheet: ViewModifier {
    @EnvironmentObject private var viewModel: AudioSamplerViewModel
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            AudioDocumentImporter { url in
                viewModel.importAudio(from: url)
                isPresented = false
            }
        }
    }
}

private struct FileExporterSheet: ViewModifier {
    let url: URL?
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.sheet(isPresented: Binding(
            get: { isPresented && url != nil },
            set: { isPresented = $0 }
        )) {
            if let url {
                AudioDocumentExporter(url: url) {
                    isPresented = false
                }
            }
        }
    }
}

extension View {
    func fileImporterSheet(isPresented: Binding<Bool>) -> some View {
        modifier(FileImporterSheet(isPresented: isPresented))
    }

    func fileExporterSheet(url: URL?, isPresented: Binding<Bool>) -> some View {
        modifier(FileExporterSheet(url: url, isPresented: isPresented))
    }
}
