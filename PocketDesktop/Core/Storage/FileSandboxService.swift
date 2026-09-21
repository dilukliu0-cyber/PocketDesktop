import Foundation

public final class FileSandboxService {
    public static let shared = FileSandboxService()
    
    private let fileManager = FileManager.default
    
    public var downloadsDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("PocketDownloads", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private init() {}
    
    public func saveDownloadedFile(name: String, data: Data) throws -> URL {
        let targetURL = downloadsDirectory.appendingPathComponent(name)
        try data.write(to: targetURL)
        return targetURL
    }
    
    public func listDownloadedFiles() -> [URL] {
        guard let files = try? fileManager.contentsOfDirectory(
            at: downloadsDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return [] }
        return files
    }
    
    public func deleteDownloadedFile(url: URL) {
        try? fileManager.removeItem(at: url)
    }
}
