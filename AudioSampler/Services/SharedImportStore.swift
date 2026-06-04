import Foundation

enum SharedImportStore {
    static let appGroupIdentifier = "group.com.jah.AudioSampler"
    private static let inboxName = "SharedImports"

    static var sharedInboxURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(inboxName, isDirectory: true)
    }

    static func makeSharedInboxIfNeeded() throws -> URL {
        guard let inbox = sharedInboxURL else {
            throw AudioSamplerError.appGroupUnavailable
        }
        try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        return inbox
    }

    static func resolveSharedImport(from url: URL) -> URL? {
        guard url.scheme == "audiosampler", url.host == "import" else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let fileName = components.queryItems?.first(where: { $0.name == "file" })?.value,
              let inbox = sharedInboxURL else {
            return nil
        }
        return inbox.appendingPathComponent(fileName)
    }
}
