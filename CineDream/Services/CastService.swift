import UIKit
import AVKit
import MediaPlayer
import WebKit

// MARK: - Cast Device Model
struct CastDevice {
    let name: String
    let device: Any
    let type: CastDeviceType
    let isConnected: Bool
}

enum CastDeviceType {
    case airPlay
    case chromecast
    case screenMirroring
}

// MARK: - Cast Service Delegate
protocol CastServiceDelegate: AnyObject {
    func castServiceDidStartCasting(to device: CastDevice)
    func castServiceDidStopCasting()
    func castServiceDidDiscoverDevices(_ devices: [CastDevice])
    func castServiceDidFail(with error: Error)
}

// MARK: - Cast Service
class CastService: NSObject {
    
    static let shared = CastService()
    
    weak var delegate: CastServiceDelegate?
    
    private var airPlayPicker: AVRoutePickerView?
    private var availableDevices: [CastDevice] = []
    private var currentCastDevice: CastDevice?
    
    // AirPlay route picker view (hidden, used programmatically)
    private lazy var routePickerView: AVRoutePickerView = {
        let picker = AVRoutePickerView()
        picker.isHidden = true
        picker.delegate = self
        picker.tintColor = UIColor(hex: "#E50914")
        picker.activeTintColor = UIColor(hex: "#E50914")
        return picker
    }()
    
    private override init() {
        super.init()
        setupAirPlayMonitoring()
    }
    
    // MARK: - Setup
    private func setupAirPlayMonitoring() {
        // Monitor AirPlay route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // Monitor screen mirroring changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenMirroringChanged),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenMirroringChanged),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    func discoverDevices() {
        var devices: [CastDevice] = []
        
        // Check for AirPlay devices
        if #available(iOS 13.0, *) {
            let airPlaySession = AVAudioSession.sharedInstance()
            let availableOutputs = airPlaySession.currentRoute.outputs
            
            for output in availableOutputs {
                if output.portType == .HDMI || output.portType == .airPlay {
                    let device = CastDevice(
                        name: output.portName,
                        device: output,
                        type: .airPlay,
                        isConnected: true
                    )
                    devices.append(device)
                }
            }
        }
        
        // Check for screen mirroring
        if UIScreen.screens.count > 1 {
            let externalScreen = UIScreen.screens.first { $0 != UIScreen.main }
            if let screen = externalScreen {
                let device = CastDevice(
                    name: "External Display",
                    device: screen,
                    type: .screenMirroring,
                    isConnected: true
                )
                devices.append(device)
            }
        }
        
        // Add mock Chromecast devices (in real app, use Google Cast SDK)
        devices.append(contentsOf: getMockChromecastDevices())
        
        availableDevices = devices
        delegate?.castServiceDidDiscoverDevices(devices)
    }
    
    private func getMockChromecastDevices() -> [CastDevice] {
        // Mock Chromecast devices for demonstration
        // In real implementation, use Google Cast SDK
        return [
            CastDevice(name: "Living Room TV", device: "mock_chromecast_1", type: .chromecast, isConnected: false),
            CastDevice(name: "Bedroom TV", device: "mock_chromecast_2", type: .chromecast, isConnected: false),
            CastDevice(name: "Kitchen Display", device: "mock_chromecast_3", type: .chromecast, isConnected: false)
        ]
    }
    
    func castToAirPlay() {
        // Programmatically trigger AirPlay picker
        DispatchQueue.main.async {
            if let button = self.routePickerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                button.sendActions(for: .touchUpInside)
            }
        }
    }
    
    func castToScreenMirroring() {
        guard UIScreen.screens.count > 1 else {
            delegate?.castServiceDidFail(with: CastError.noExternalDisplay)
            return
        }
        
        let externalScreen = UIScreen.screens.first { $0 != UIScreen.main }
        guard let screen = externalScreen else {
            delegate?.castServiceDidFail(with: CastError.noExternalDisplay)
            return
        }
        
        setupScreenMirroring(to: screen)
    }
    
    func castToChromecast(device: CastDevice) {
        // Mock Chromecast connection
        // In real implementation, use Google Cast SDK
        currentCastDevice = device
        delegate?.castServiceDidStartCasting(to: device)
    }
    
    func stopCasting() {
        currentCastDevice = nil
        
        // Stop AirPlay if active
        if #available(iOS 13.0, *) {
            let airPlaySession = AVAudioSession.sharedInstance()
            // Try to switch back to built-in speaker
            do {
                try airPlaySession.overrideOutputAudioPort(.none)
            } catch {
                print("Failed to stop AirPlay: \(error)")
            }
        }
        
        // Stop screen mirroring if active
        if UIScreen.screens.count > 1 {
            for screen in UIScreen.screens {
                if screen != UIScreen.main {
                    // Disconnect external screen
                    screen.overscanCompensation = .none
                }
            }
        }
        
        delegate?.castServiceDidStopCasting()
    }
    
    func isCasting() -> Bool {
        return currentCastDevice != nil || isAirPlayActive() || isScreenMirroringActive()
    }
    
    func getCurrentCastDevice() -> CastDevice? {
        return currentCastDevice
    }
    
    // MARK: - Private Methods
    private func setupScreenMirroring(to screen: UIScreen) {
        // Create a new window for the external screen
        let externalWindow = UIWindow(frame: screen.bounds)
        externalWindow.screen = screen
        
        // Create a simple view controller for mirroring
        let mirrorVC = UIViewController()
        mirrorVC.view.backgroundColor = .black
        
        // Add the current player view to the external screen
        // Find the player view and mirror it
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        if let window = windowScene?.windows.first,
           let rootVC = window.rootViewController {
            findAndMirrorPlayerView(from: rootVC, to: mirrorVC)
        }
        
        externalWindow.rootViewController = mirrorVC
        externalWindow.makeKeyAndVisible()
        
        let device = CastDevice(
            name: "External Display",
            device: screen,
            type: .screenMirroring,
            isConnected: true
        )
        
        currentCastDevice = device
        delegate?.castServiceDidStartCasting(to: device)
    }
    
    private func findAndMirrorPlayerView(from viewController: UIViewController, to mirrorVC: UIViewController) {
        // Recursively search for PlayerVC
        if let playerVC = viewController as? PlayerVC {
            // Mirror the player's view
            if let playerView = playerVC.view {
                let mirroredView = UIView(frame: mirrorVC.view.bounds)
                mirroredView.backgroundColor = .black
                
                // Create a copy of the webview or player layer
                if let webView = playerVC.webView {
                    // For webview, create a new webview with same content
                    let newWebView = WKWebView(frame: mirroredView.bounds, configuration: webView.configuration)
                    AdBlockManager.shared.applyAdBlocker(to: newWebView)
                    if let url = webView.url {
                        newWebView.load(URLRequest(url: url))
                    }
                    mirroredView.addSubview(newWebView)
                } else if let playerLayer = playerVC.playerLayer {
                    // For AVPlayer, create a new player layer
                    let newPlayer = AVPlayer(playerItem: playerLayer.player?.currentItem)
                    let newLayer = AVPlayerLayer(player: newPlayer)
                    newLayer.frame = mirroredView.bounds
                    newLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                    mirroredView.layer.addSublayer(newLayer)
                    newPlayer.play()
                }
                
                mirrorVC.view.addSubview(mirroredView)
            }
        }
        
        // Search child view controllers
        for child in viewController.children {
            findAndMirrorPlayerView(from: child, to: mirrorVC)
        }
        
        // Search presented view controllers
        if let presented = viewController.presentedViewController {
            findAndMirrorPlayerView(from: presented, to: mirrorVC)
        }
    }
    
    private func isAirPlayActive() -> Bool {
        if #available(iOS 13.0, *) {
            let airPlaySession = AVAudioSession.sharedInstance()
            let availableOutputs = airPlaySession.currentRoute.outputs
            return availableOutputs.contains { $0.portType == .airPlay }
        }
        return false
    }
    
    private func isScreenMirroringActive() -> Bool {
        return UIScreen.screens.count > 1
    }
    
    // MARK: - Notification Handlers
    @objc private func audioRouteChanged(notification: Notification) {
        discoverDevices()
    }
    
    @objc private func screenMirroringChanged(notification: Notification) {
        discoverDevices()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVRoutePickerViewDelegate
@available(iOS 13.0, *)
extension CastService: AVRoutePickerViewDelegate {
    func routePickerViewDidPresentRoutePicker(_ routePickerView: AVRoutePickerView) {
        // AirPlay picker presented
    }
    
    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        // AirPlay picker dismissed
        discoverDevices()
    }
}

// MARK: - Cast Error
enum CastError: Error, LocalizedError {
    case noExternalDisplay
    case connectionFailed
    case deviceNotFound
    
    var errorDescription: String? {
        switch self {
        case .noExternalDisplay:
            return "No external display found"
        case .connectionFailed:
            return "Failed to connect to casting device"
        case .deviceNotFound:
            return "Casting device not found"
        }
    }
}

// MARK: - Cast Button
class CastButton: UIButton {
    
    private let castIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "tv"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let routePickerView: AVRoutePickerView = {
        let picker = AVRoutePickerView()
        picker.backgroundColor = .clear
        picker.alpha = 0.01 // Nearly invisible but clickable
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        layer.cornerRadius = 20
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(castIcon)
        addSubview(activityIndicator)
        addSubview(routePickerView)
        
        NSLayoutConstraint.activate([
            castIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            castIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            castIcon.widthAnchor.constraint(equalToConstant: 24),
            castIcon.heightAnchor.constraint(equalToConstant: 24),
            
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            routePickerView.topAnchor.constraint(equalTo: topAnchor),
            routePickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            routePickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            routePickerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        addNetflixTouchEffect()
        updateCastStatus()
    }
    
    @objc private func castButtonTapped() {
        showCastOptions()
    }
    
    private func showCastOptions() {
        let alert = UIAlertController(title: "Cast & Mirroring", message: "Choose how you want to watch", preferredStyle: .actionSheet)
        
        // AirPlay & Mirroring option (The standard iOS way)
        alert.addAction(UIAlertAction(title: "📺 AirPlay or Screen Mirroring", style: .default) { _ in
            self.triggerSystemPicker()
        })
        
        // Screen Mirroring option (Manual app-level mirroring if already connected)
        if UIScreen.screens.count > 1 {
            alert.addAction(UIAlertAction(title: "🖥️ Use External Display", style: .default) { _ in
                CastService.shared.castToScreenMirroring()
            })
        }
        
        // Mock Chromecast devices
        alert.addAction(UIAlertAction(title: "📡 Living Room TV", style: .default) { _ in
            let device = CastDevice(name: "Living Room TV", device: "mock_chromecast_1", type: .chromecast, isConnected: false)
            CastService.shared.castToChromecast(device: device)
        })
        
        alert.addAction(UIAlertAction(title: "📡 Bedroom TV", style: .default) { _ in
            let device = CastDevice(name: "Bedroom TV", device: "mock_chromecast_2", type: .chromecast, isConnected: false)
            CastService.shared.castToChromecast(device: device)
        })
        
        // Stop casting option
        if CastService.shared.isCasting() {
            alert.addAction(UIAlertAction(title: "⏹️ Stop Casting", style: .destructive) { _ in
                CastService.shared.stopCasting()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Get the current view controller to present the alert
        if let viewController = findViewController() {
            if let popover = alert.popoverPresentationController {
                popover.sourceView = self
                popover.sourceRect = bounds
                popover.permittedArrowDirections = .up
            }
            viewController.present(alert, animated: true)
        }
    }
    
    private func triggerSystemPicker() {
        // Trigger the hidden AVRoutePickerView
        for subview in routePickerView.subviews {
            if let button = subview as? UIButton {
                button.sendActions(for: .touchUpInside)
                break
            }
        }
    }
    
    func updateCastStatus() {
        let isCasting = CastService.shared.isCasting()
        
        if isCasting {
            castIcon.image = UIImage(systemName: "tv.and.hifi")
            castIcon.tintColor = UIColor(hex: "#E50914")
            backgroundColor = UIColor(hex: "#E50914")!.withAlphaComponent(0.2)
        } else {
            castIcon.image = UIImage(systemName: "tv")
            castIcon.tintColor = .white
            backgroundColor = UIColor.black.withAlphaComponent(0.6)
        }
    }
    
    func setConnecting(_ connecting: Bool) {
        if connecting {
            activityIndicator.startAnimating()
            castIcon.alpha = 0
        } else {
            activityIndicator.stopAnimating()
            castIcon.alpha = 1
        }
    }
}
