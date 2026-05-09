import Foundation

class CacheService {
    static let shared = CacheService()
    
    func getCacheSize() -> String {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey])
            var totalSize: Int64 = 0
            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let size = attributes[.size] as? NSNumber {
                    totalSize += size.int64Value
                }
            }
            return String(format: "%.1f MB", Double(totalSize) / 1024.0 / 1024.0)
        } catch {
            return "0.0 MB"
        }
    }
    
    func clearCache() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: cacheURL.path)
            for file in files {
                let path = cacheURL.appendingPathComponent(file).path
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {}
    }
}
