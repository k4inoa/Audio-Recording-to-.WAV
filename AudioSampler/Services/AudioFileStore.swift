import Foundation
import UniformTypeIdentifiers

enum AudioFileStore {
    static func persistImportedFile(from sourceURL: URL) throws -> URL {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let imports = try importsDirectory()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent.isEmpty
            ? "Recording"
            : sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let destination = uniqueURL(in: imports, baseName: baseName, extension: ext)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return destination
    }

    static func importsDirectory() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Imports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func exportsDirectory() throws -> URL {
        let directory = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func uniqueURL(in directory: URL, baseName: String, extension ext: String) -> URL {
        let cleanedName = baseName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        var candidate = directory.appendingPathComponent(cleanedName).appendingPathExtension(ext)
        var index = 1

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(cleanedName)-\(index)")
                .appendingPathExtension(ext)
            index += 1
        }

        return candidate
    }
}
