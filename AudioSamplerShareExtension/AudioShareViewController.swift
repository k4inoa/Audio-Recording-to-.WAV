import UIKit
import UniformTypeIdentifiers

final class AudioShareViewController: UIViewController {
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        importFirstAudioAttachment()
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.08, green: 0.09, blue: 0.10, alpha: 1)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Importing audio..."
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func importFirstAudioAttachment() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            finishWithFailure("No shared item was found.")
            return
        }

        let providers = extensionItems
            .flatMap { $0.attachments ?? [] }

        guard let provider = providers.first(where: { itemProvider in
            itemProvider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) ||
            itemProvider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }) else {
            finishWithFailure("Share an audio recording to import it.")
            return
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
            loadAudioFile(from: provider, typeIdentifier: UTType.audio.identifier)
        } else {
            loadAudioFile(from: provider, typeIdentifier: UTType.fileURL.identifier)
        }
    }

    private func loadAudioFile(from provider: NSItemProvider, typeIdentifier: String) {
        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, error in
            guard let self else { return }

            if let error {
                self.finishWithFailure(error.localizedDescription)
                return
            }

            guard let url else {
                self.finishWithFailure("The shared recording did not include a readable file.")
                return
            }

            do {
                let importedURL = try self.copyToSharedInbox(sourceURL: url)
                DispatchQueue.main.async {
                    self.statusLabel.text = "Opening WAV Sampler..."
                    self.openContainingApp(fileName: importedURL.lastPathComponent)
                }
            } catch {
                self.finishWithFailure(error.localizedDescription)
            }
        }
    }

    private func copyToSharedInbox(sourceURL: URL) throws -> URL {
        let inbox = try makeSharedInboxIfNeeded()
        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let baseName = sourceURL.deletingPathExtension().lastPathComponent.isEmpty
            ? "Voice-Memo"
            : sourceURL.deletingPathExtension().lastPathComponent
        let destination = uniqueURL(in: inbox, baseName: baseName, extension: ext)
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return destination
    }

    private func makeSharedInboxIfNeeded() throws -> URL {
        guard let inbox = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.jah.AudioSampler")?
            .appendingPathComponent("SharedImports", isDirectory: true) else {
            throw NSError(domain: "AudioShareExtension", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "The shared import folder is unavailable."
            ])
        }
        try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        return inbox
    }

    private func uniqueURL(in directory: URL, baseName: String, extension ext: String) -> URL {
        let cleanBase = baseName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        var candidate = directory.appendingPathComponent(cleanBase).appendingPathExtension(ext)
        var index = 1

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(cleanBase)-\(index)").appendingPathExtension(ext)
            index += 1
        }

        return candidate
    }

    private func openContainingApp(fileName: String) {
        var components = URLComponents()
        components.scheme = "audiosampler"
        components.host = "import"
        components.queryItems = [
            URLQueryItem(name: "file", value: fileName)
        ]

        guard let url = components.url else {
            finishWithFailure("The import URL could not be created.")
            return
        }

        var responder: UIResponder? = self
        let selector = Selector(("openURL:"))

        while let current = responder {
            if current.responds(to: selector) {
                current.perform(selector, with: url)
                extensionContext?.completeRequest(returningItems: nil)
                return
            }
            responder = current.next
        }

        extensionContext?.completeRequest(returningItems: nil)
    }

    private func finishWithFailure(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
            self.extensionContext?.cancelRequest(withError: NSError(domain: "AudioShareExtension", code: 2, userInfo: [
                NSLocalizedDescriptionKey: message
            ]))
        }
    }
}
