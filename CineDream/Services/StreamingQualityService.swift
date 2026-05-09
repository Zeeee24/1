import UIKit
import AVFoundation
import Network

class StreamingQualityService {
    
    static let shared = StreamingQualityService()
    
    // MARK: - Quality Levels
    enum VideoQuality: String, CaseIterable {
        case auto = "Auto"
        case uhd4k = "4K UHD"
        case hd1080p = "1080p HD"
        case hd720p = "720p HD"
        case sd480p = "480p SD"
        case sd360p = "360p SD"
        
        var bitrate: Int {
            switch self {
            case .auto: return 0 // Adaptive
            case .uhd4k: return 25000 // 25 Mbps
            case .hd1080p: return 8000 // 8 Mbps
            case .hd720p: return 4000 // 4 Mbps
            case .sd480p: return 2000 // 2 Mbps
            case .sd360p: return 1000 // 1 Mbps
            }
        }
        
        var resolution: CGSize {
            switch self {
            case .auto: return CGSize(width: 1920, height: 1080) // Default
            case .uhd4k: return CGSize(width: 3840, height: 2160)
            case .hd1080p: return CGSize(width: 1920, height: 1080)
            case .hd720p: return CGSize(width: 1280, height: 720)
            case .sd480p: return CGSize(width: 854, height: 480)
            case .sd360p: return CGSize(width: 640, height: 360)
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    // MARK: - HDR Support
    enum HDRType: String, CaseIterable {
        case none = "SDR"
        case hdr10 = "HDR10"
        case dolbyVision = "Dolby Vision"
        case hlg = "HLG"
        
        var isHDR: Bool {
            return self != .none
        }
    }
    
    // MARK: - Adaptive Streaming
    private var currentNetworkSpeed: Double = 0.0 // Mbps
    private var preferredQuality: VideoQuality = .auto
    private var isAdaptiveEnabled: Bool = true
    private var supportedQualities: Set<VideoQuality> = []
    
    private init() {
        setupNetworkMonitoring()
        loadUserPreferences()
        detectDeviceCapabilities()
    }
    
    // MARK: - Public Methods
    func getOptimalQuality(for content: MediaContent) -> VideoQuality {
        if !isAdaptiveEnabled {
            return preferredQuality
        }
        
        // Check device capabilities
        let maxDeviceQuality = getMaxDeviceQuality()
        let maxContentQuality = content.maxQuality
        
        // Get adaptive quality based on network
        let adaptiveQuality = getAdaptiveQuality()
        
        // Return the minimum of all constraints
        let qualities = [maxDeviceQuality, maxContentQuality, adaptiveQuality]
        return qualities.min { quality1, quality2 in
            quality1.bitrate < quality2.bitrate
        } ?? .hd720p
    }
    
    func setPreferredQuality(_ quality: VideoQuality) {
        preferredQuality = quality
        saveUserPreferences()
        
        // Disable adaptive if user manually selects quality
        if quality != .auto {
            isAdaptiveEnabled = false
        } else {
            isAdaptiveEnabled = true
        }
    }
    
    func getAvailableQualities(for content: MediaContent) -> [VideoQuality] {
        return VideoQuality.allCases.filter { quality in
            guard supportedQualities.contains(quality) else { return false }
            return quality.bitrate <= content.maxQuality.bitrate
        }
    }
    
    func isHDRSupported() -> Bool {
        // Check if device supports HDR
        if #available(iOS 16.0, *) {
            return UIScreen.main.potentialEDRHeadroom > 1.0
        }
        return false
    }
    
    func getSupportedHDRTypes() -> [HDRType] {
        var supportedTypes: [HDRType] = [.none]
        
        if isHDRSupported() {
            supportedTypes.append(contentsOf: [.hdr10, .dolbyVision, .hlg])
        }
        
        return supportedTypes
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        // Monitor network path changes using manual timer for compatibility
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.startNetworkSpeedTest()
        }
        
        // Start initial network speed test
        startNetworkSpeedTest()
    }
    
    private func startNetworkSpeedTest() {
        // Simulate network speed test
        DispatchQueue.global(qos: .background).async {
            // In real implementation, this would test actual download speed
            let simulatedSpeed = self.getSimulatedNetworkSpeed()
            
            DispatchQueue.main.async {
                self.currentNetworkSpeed = simulatedSpeed
                self.notifyQualityChanged()
            }
        }
    }
    
    private func getSimulatedNetworkSpeed() -> Double {
        // Simulate different network conditions
        let speeds = [50.0, 25.0, 10.0, 5.0, 2.0, 1.0] // Mbps
        return speeds.randomElement() ?? 5.0
    }
    
    // MARK: - Device Detection
    private func detectDeviceCapabilities() {
        var qualities: Set<VideoQuality> = []
        
        // Check device resolution and capabilities
        let screenSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let nativeResolution = CGSize(width: screenSize.width * scale, height: screenSize.height * scale)
        
        // Determine supported qualities based on device
        if nativeResolution.width >= 3840 && nativeResolution.height >= 2160 {
            // 4K device
            qualities.formUnion([.auto, .uhd4k, .hd1080p, .hd720p, .sd480p, .sd360p])
        } else if nativeResolution.width >= 1920 && nativeResolution.height >= 1080 {
            // 1080p device
            qualities.formUnion([.auto, .hd1080p, .hd720p, .sd480p, .sd360p])
        } else {
            // Lower resolution device
            qualities.formUnion([.auto, .hd720p, .sd480p, .sd360p])
        }
        
        // Check processor capabilities for 4K
        if !is4KCapable() {
            qualities.remove(.uhd4k)
        }
        
        supportedQualities = qualities
    }
    
    private func is4KCapable() -> Bool {
        // Check if device can handle 4K playback
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        // iPhone 8+ and newer, iPad Pro and newer support 4K
        if deviceModel.contains("iPhone") {
            return systemVersion >= "13.0"
        } else if deviceModel.contains("iPad") {
            return systemVersion >= "13.0"
        }
        
        return false
    }
    
    private func getMaxDeviceQuality() -> VideoQuality {
        return supportedQualities.max { quality1, quality2 in
            quality1.bitrate < quality2.bitrate
        } ?? .hd720p
    }
    
    private func getAdaptiveQuality() -> VideoQuality {
        guard currentNetworkSpeed > 0 else { return .sd360p }
        
        // Select quality based on network speed with 30% buffer
        let bufferedSpeed = currentNetworkSpeed * 0.7
        
        if bufferedSpeed >= 25.0 {
            return .uhd4k
        } else if bufferedSpeed >= 8.0 {
            return .hd1080p
        } else if bufferedSpeed >= 4.0 {
            return .hd720p
        } else if bufferedSpeed >= 2.0 {
            return .sd480p
        } else {
            return .sd360p
        }
    }
    
    // MARK: - Preloading
    func preloadNextEpisode(for series: TVShow, currentEpisode: Episode) {
        guard let nextEpisode = series.getNextEpisode(after: currentEpisode) else { return }
        
        DispatchQueue.global(qos: .background).async {
            let quality = self.getOptimalQuality(for: nextEpisode)
            
            // Preload next episode data
            self.preloadContent(nextEpisode, quality: quality)
        }
    }
    
    private func preloadContent(_ content: MediaContent, quality: VideoQuality) {
        // In real implementation, this would preload video segments
        print("Preloading content: \(content.contentTitle) at \(quality.displayName)")
        
        // Simulate preloading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NotificationCenter.default.post(
                name: .contentPreloaded,
                object: content,
                userInfo: ["quality": quality]
            )
        }
    }
    
    // MARK: - Background Loading
    func enableBackgroundLoading() {
        // Enable background loading for better performance
        DispatchQueue.global(qos: .background).async {
            self.preloadPopularContent()
        }
    }
    
    private func preloadPopularContent() {
        // Preload trending content in background
        print("Preloading popular content in background...")
    }
    
    // MARK: - User Preferences
    private func loadUserPreferences() {
        if let qualityRaw = UserDefaults.standard.string(forKey: "preferredQuality"),
           let quality = VideoQuality(rawValue: qualityRaw) {
            preferredQuality = quality
        }
        
        isAdaptiveEnabled = UserDefaults.standard.bool(forKey: "adaptiveEnabled")
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(preferredQuality.rawValue, forKey: "preferredQuality")
        UserDefaults.standard.set(isAdaptiveEnabled, forKey: "adaptiveEnabled")
    }
    
    private func notifyQualityChanged() {
        NotificationCenter.default.post(name: .qualityDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Media Content Protocol
protocol MediaContent {
    var contentTitle: String { get }
    var maxQuality: StreamingQualityService.VideoQuality { get }
    var duration: TimeInterval { get }
}

// MARK: - Extensions
extension Movie: MediaContent {
    var maxQuality: StreamingQualityService.VideoQuality {
        // In real app, this would come from API
        return .hd1080p
    }
    
    var contentTitle: String {
        return self.title ?? "Unknown"
    }
    
    var duration: TimeInterval {
        return TimeInterval((runtime ?? 0) * 60)
    }
}

extension TVShow: MediaContent {
    var maxQuality: StreamingQualityService.VideoQuality {
        return .hd1080p
    }
    
    var contentTitle: String {
        return self.name ?? "Unknown"
    }
    
    var duration: TimeInterval {
        return 45 * 60 // 45 minutes average
    }
    
    func getNextEpisode(after currentEpisode: Episode) -> Episode? {
        // Mock implementation
        return Episode(id: currentEpisode.id + 1, name: "Next Episode", overview: "", stillPath: nil, episodeNumber: currentEpisode.episodeNumber + 1, seasonNumber: currentEpisode.seasonNumber, airDate: "")
    }
}

extension Episode: MediaContent {
    var contentTitle: String {
        return self.name ?? "Unknown"
    }
    
    var maxQuality: StreamingQualityService.VideoQuality {
        return .hd1080p
    }
    
    var duration: TimeInterval {
        return 45 * 60
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let qualityDidChange = Notification.Name("qualityDidChange")
    static let contentPreloaded = Notification.Name("contentPreloaded")
}
