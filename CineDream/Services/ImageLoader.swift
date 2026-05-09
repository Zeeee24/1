import Foundation
import UIKit

class ImageLoader {
    static let shared = ImageLoader()
    let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    private lazy var cacheDirectory: URL = {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = urls[0].appendingPathComponent("ImageCache")
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }()
    
    func load(urlString: String?, into imageView: UIImageView) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            imageView.image = nil
            return
        }
        
        let cacheKey = NSString(string: urlString)
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            imageView.image = cachedImage
            return
        }
        
        let fileURL = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        if fileManager.fileExists(atPath: fileURL.path), let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: cacheKey)
            imageView.image = image
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, error == nil, let data = data, let image = UIImage(data: data) else { return }
            
            self.memoryCache.setObject(image, forKey: cacheKey)
            try? data.write(to: fileURL)
            
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }
    
    func prefetch(urlStrings: [String]) {
        for urlString in urlStrings {
            guard let url = URL(string: urlString) else { continue }
            let cacheKey = NSString(string: urlString)
            if memoryCache.object(forKey: cacheKey) != nil { continue }
            
            let fileURL = cacheDirectory.appendingPathComponent(url.lastPathComponent)
            if fileManager.fileExists(atPath: fileURL.path) { continue }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self, error == nil, let data = data, let image = UIImage(data: data) else { return }
                self.memoryCache.setObject(image, forKey: cacheKey)
                try? data.write(to: fileURL)
            }.resume()
        }
    }
}
