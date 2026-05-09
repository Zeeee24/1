import UIKit

extension UIImageView {
    func loadImage(from urlString: String?, placeholder: UIImage? = nil, completion: ((UIImage?) -> Void)? = nil) {
        self.image = placeholder
        guard let urlString = urlString, let url = URL(string: urlString) else {
            print("⚠️ Invalid image URL: \(urlString ?? "nil")")
            completion?(nil)
            return
        }
        let cacheKey = NSString(string: urlString)
        if let cachedImage = ImageLoader.shared.memoryCache.object(forKey: cacheKey) {
            self.image = cachedImage
            completion?(cachedImage)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ Image download error for \(url): \(error.localizedDescription)")
                DispatchQueue.main.async { completion?(nil) }
                return
            }
            guard let data = data, let img = UIImage(data: data) else {
                print("⚠️ Invalid image data for \(url)")
                DispatchQueue.main.async { completion?(nil) }
                return
            }
            ImageLoader.shared.memoryCache.setObject(img, forKey: cacheKey)
            DispatchQueue.main.async {
                self?.image = img
                completion?(img)
            }
        }.resume()
    }
}

extension UIImage {
    var averageColor: UIColor? {
        guard let cgImage = self.cgImage else { return nil }
        let inputImage = CIImage(cgImage: cgImage)
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]), let outputImage = filter.outputImage else { return nil }
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        return UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: 1.0)
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension UIView {
    func addGradient(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        layer.insertSublayer(gradient, at: 0)
    }
}

extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension String {
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.compactMap { match in
                if let range = Range(match.range, in: self) {
                    return String(self[range])
                }
                return nil
            }
        } catch {
            return []
        }
    }
}

extension Date {
    func toISO8601() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func strong() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}
