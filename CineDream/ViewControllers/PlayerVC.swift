import UIKit
import AVFoundation
import AVKit
import MediaPlayer
import WebKit

// MARK: - Server Status Enum
enum ServerQualityStatus {
    case checking
    case fast
    case slow
    case dead
    
    var color: UIColor {
        switch self {
        case .checking: return .systemGray
        case .fast: return .systemGreen
        case .slow: return .systemYellow
        case .dead: return .systemRed
        }
    }
}

// MARK: - Server Check Result
struct ServerCheckResult {
    let source: StreamResult
    let status: ServerQualityStatus
    let responseTime: TimeInterval
}

class PlayerVC: UIViewController {
    
    // MARK: - Public Properties
    var streamResult: StreamResult?
    var allStreamResults: [StreamResult] = []
    var tmdbId: Int = 0
    var titleText: String = ""
    var releaseYear: String?
    var isTVShow: Bool = false
    var posterPath: String? = nil
    var imdbId: String?
    var startProgressSeconds: Double = 0
    
    var allEpisodes: [Episode] = []
    var currentEpisodeIndex: Int?
    private var nextEpisodeButtonVisible = false
    
    // MARK: - Internal State
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var webView: WKWebView?
    var timeObserver: Any?
    var hasAddedObserver = false
    var isEmbed = false
    
    private var isOverlayVisible = true
    private var overlayTimer: DispatchWorkItem?
    private var isPlaying = false
    private var subtitleCues: [SubtitleCue] = []
    
    // MARK: - Server System
    private var serverCheckResults: [String: ServerCheckResult] = [:]
    private var currentServerIndex = 0
    private var playbackStartTime: Date?
    private var hasSwitchedServer = false
    
    // MARK: - Fallback System
    private var fallbackTimer: Timer?
    private var hasSuccessfullyLoaded = false
    private var isFallbackActive = false
    
    // MARK: - UI Components
    private let overlayView = UIView()
    private let topGradient = CAGradientLayer()
    private let bottomGradient = CAGradientLayer()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .boldSystemFont(ofSize: 16)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.down", withConfiguration: config), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        b.layer.cornerRadius = 20
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let serverButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        b.setImage(UIImage(systemName: "server.rack", withConfiguration: config), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        b.layer.cornerRadius = 20
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let bottomBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let currentTimeLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        l.text = "00:00"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let durationLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        l.text = "00:00"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let progressSlider: UISlider = {
        let s = UISlider()
        s.minimumTrackTintColor = UIColor(hex: "#E50914")
        s.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        s.thumbTintColor = UIColor(hex: "#E50914")
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private let bufferBar: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .default)
        p.progressTintColor = UIColor.white.withAlphaComponent(0.4)
        p.trackTintColor = .clear
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .boldSystemFont(ofSize: 20)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowOffset = CGSize(width: 1, height: 1)
        l.layer.shadowOpacity = 1.0
        l.layer.shadowRadius = 2.0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let nextEpisodeButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        b.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        b.layer.borderWidth = 1
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        b.layer.cornerRadius = 4
        b.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        b.alpha = 0
        return b
    }()
    
    private let bufferingSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    private let errorView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let errorLabel: UILabel = {
        let l = UILabel()
        l.text = "This movie is currently unavailable on any server"
        l.textColor = .white
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let errorBackButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Back", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.backgroundColor = UIColor(hex: "#E50914")
        b.layer.cornerRadius = 25
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private var volumeSlider: UISlider?
    private lazy var volumeView: MPVolumeView = {
        let view = MPVolumeView()
        view.isHidden = true
        return view
    }()
    
    // MARK: - Pan gesture state
    private var startPanPoint: CGPoint = .zero
    private var startBrightness: CGFloat = 0
    private var startVolume: Float = 0
    private var isScrubbing = false
    
    // MARK: - Orientation
    private var isLandscape: Bool {
        return view.bounds.width > view.bounds.height
    }
    
    // MARK: - Overrides
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        isEmbed = streamResult?.isEmbed ?? false
        
        setupErrorView()
        setupOverlay()
        setupGestures()
        setupAudioSession()

        view.addSubview(volumeView)
        for subview in volumeView.subviews {
            if let slider = subview as? UISlider {
                volumeSlider = slider
                break
            }
        }
        
        // Start server checking immediately
        checkAllServersAndPlay()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
        webView?.frame = view.bounds
        updateOrientationUI()
    }
    
    deinit {
        overlayTimer?.cancel()
        if let obs = timeObserver { player?.removeTimeObserver(obs) }
        if hasAddedObserver {
            player?.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Error View Setup
    private func setupErrorView() {
        view.addSubview(errorView)
        errorView.addSubview(errorLabel)
        errorView.addSubview(errorBackButton)
        
        errorBackButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            errorLabel.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: errorView.centerYAnchor, constant: -50),
            errorLabel.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -40),
            
            errorBackButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 40),
            errorBackButton.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            errorBackButton.widthAnchor.constraint(equalToConstant: 150),
            errorBackButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Server System
    private func checkAllServersAndPlay() {
        self.serverCheckResults = ServerCheckManager.shared.getResults(for: tmdbId)
        self.allStreamResults = ServerCheckManager.shared.getAllSources(for: tmdbId)
        
        guard !self.allStreamResults.isEmpty else {
            // Still building sources, wait
            bufferingSpinner.startAnimating()
            ServerCheckManager.shared.onUpdate = { [weak self] updatedTmdbId in
                guard let self = self, updatedTmdbId == self.tmdbId else { return }
                self.checkAllServersAndPlay()
            }
            return
        }
        
        var bestResult: ServerCheckResult? = nil
        var isStillChecking = false
        
        for source in allStreamResults {
            if let res = serverCheckResults[source.sourceId] {
                if res.status == .fast {
                    bestResult = res
                    break // First green server in priority order
                } else if res.status == .checking {
                    isStillChecking = true
                } else if res.status == .slow && bestResult == nil {
                    bestResult = res // Remember first yellow, but keep looking for green
                }
            } else {
                isStillChecking = true
            }
        }
        
        if let best = bestResult {
            // Found a usable server and didn't wait if green
            if best.status == .fast || !isStillChecking {
                self.streamResult = best.source
                self.isEmbed = best.source.isEmbed
                self.currentServerIndex = self.allStreamResults.firstIndex(where: { $0.sourceId == best.source.sourceId }) ?? 0
                self.setupPlayer()
                self.schedulePlaybackCheck()
                
                // Listen for background updates for the server list
                ServerCheckManager.shared.onUpdate = { [weak self] updatedTmdbId in
                    guard let self = self, updatedTmdbId == self.tmdbId else { return }
                    self.serverCheckResults = ServerCheckManager.shared.getResults(for: self.tmdbId)
                    // Notification could update ServerSelectionSheet if open
                    NotificationCenter.default.post(name: NSNotification.Name("ServerCheckUpdated"), object: nil)
                }
                return
            }
        }
        
        if isStillChecking {
            // Wait for update
            bufferingSpinner.startAnimating()
            ServerCheckManager.shared.onUpdate = { [weak self] updatedTmdbId in
                guard let self = self, updatedTmdbId == self.tmdbId else { return }
                self.checkAllServersAndPlay() // Try again
            }
            return
        }
        
        // If we get here, no servers are available. Fall back to Direct Stream automatically.
        bufferingSpinner.stopAnimating()
        self.checkAndTriggerFallback()
    }
    
    private func schedulePlaybackCheck() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.checkAndSwitchIfNeeded()
        }
    }
    
    private func checkAndSwitchIfNeeded() {
        guard !hasSwitchedServer else { return }
        
        let isPlaying = isActuallyPlaying()
        
        if !isPlaying {
            // Show toast and switch to next server
            switchToNextBestServer()
        }
    }
    
    private func isActuallyPlaying() -> Bool {
        if isEmbed {
            if let startTime = playbackStartTime {
                return Date().timeIntervalSince(startTime) > 3.0
            }
            return false
        } else if let player = player {
            return player.rate != 0 && player.currentItem?.status == .readyToPlay
        }
        return false
    }
    
    private func switchToNextBestServer() {
        hasSwitchedServer = true
        
        let remainingServers = allStreamResults.enumerated().filter { $0.offset != currentServerIndex }
        
        guard !remainingServers.isEmpty else {
            cleanupPlayer()
            self.checkAndTriggerFallback()
            return
        }
        
        // Find next best available server in priority order
        var nextBest: (offset: Int, element: StreamResult)? = nil
        
        for server in remainingServers {
            if let res = serverCheckResults[server.element.sourceId], res.status == .fast || res.status == .slow {
                nextBest = server
                break // Priority order is preserved
            }
        }
        
        if let next = nextBest {
            currentServerIndex = next.offset
            let nextSource = next.element
            
            cleanupPlayer()
            streamResult = nextSource
            isEmbed = nextSource.isEmbed
            setupPlayer()
    
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                if let self = self, !self.isActuallyPlaying() {
                    self.switchToNextBestServer()
                }
            }
        } else {
            cleanupPlayer()
            self.checkAndTriggerFallback()
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        webView?.removeFromSuperview()
        webView = nil
        
        if let obs = timeObserver { player?.removeTimeObserver(obs); timeObserver = nil }
        if hasAddedObserver {
            player?.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
            hasAddedObserver = false
        }
    }
    
    private func showErrorView() {
        bufferingSpinner.stopAnimating()
        UIView.animate(withDuration: 0.3) {
            self.errorView.alpha = 1
        }
    }
    
    private func showToast(_ message: String) {
        // Disabled for a silent player experience
    }
    
    // MARK: - Player Setup
    private func setupPlayer() {
        guard let result = streamResult else { return }
        
        playbackStartTime = Date()
        bufferingSpinner.startAnimating()
        
        if result.isEmbed {
            let config = WKWebViewConfiguration()
            config.allowsInlineMediaPlayback = true
            config.mediaTypesRequiringUserActionForPlayback = []
            config.allowsPictureInPictureMediaPlayback = true
            config.preferences.javaScriptEnabled = true
            config.allowsAirPlayForMediaPlayback = true
            
            let wv = WKWebView(frame: view.bounds, configuration: config)
            wv.backgroundColor = .black
            wv.scrollView.backgroundColor = .black
            wv.isOpaque = false
            wv.scrollView.isScrollEnabled = false
            wv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Apply ad blocker before loading
            AdBlockManager.shared.applyAdBlocker(to: wv)
            
            view.insertSubview(wv, at: 0)
            
            let request = URLRequest(url: result.url)
            wv.load(request)
            self.webView = wv
            
            // Start fallback timer for embed sources
            startFallbackTimer()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.bufferingSpinner.stopAnimating()
            }
        } else {
            // For direct streams, mark as successfully loaded
            hasSuccessfullyLoaded = true
            let avPlayer = AVPlayer(url: result.url)
            let layer = AVPlayerLayer(player: avPlayer)
            layer.videoGravity = .resizeAspect
            view.layer.insertSublayer(layer, at: 0)
            
            self.player = avPlayer
            self.playerLayer = layer
            
            let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                self?.updateTimeUI(time)
            }
            avPlayer.currentItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
            hasAddedObserver = true
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinish), name: .AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
            
            if startProgressSeconds > 0 {
                let time = CMTime(seconds: startProgressSeconds, preferredTimescale: 600)
                avPlayer.seek(to: time)
            }
            
            avPlayer.play()
            
            // Mark as successfully loaded for direct streams
            hasSuccessfullyLoaded = true
            cancelFallbackTimer()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.bufferingSpinner.stopAnimating()
            }
        }
        isPlaying = true
    }
    
    // MARK: - Fallback Timer
    private func startFallbackTimer() {
        guard !isFallbackActive && imdbId != nil else { return }
        
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.checkAndTriggerFallback()
        }
    }
    
    private func cancelFallbackTimer() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }
    
    private func checkAndTriggerFallback() {
        guard !hasSuccessfullyLoaded && !isFallbackActive else { return }
        guard let imdbId = imdbId else { return }
        
        isFallbackActive = true
        
        // Resolve direct stream from vidsrc.icu or vidsrc.mov
        let cleanImdbId = imdbId.trimmingCharacters(in: .whitespacesAndNewlines)
        StreamResolverService.shared.resolve(imdbId: cleanImdbId, isTVShow: isTVShow) { [weak self] url in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if url == nil {
                    // Fail silently
                }
                
                guard let streamURL = url else {
                    self.isFallbackActive = false
                    return
                }
                
                self.switchToDirectStream(streamURL)
            }
        }
    }
    
    private func switchToDirectStream(_ url: URL) {
        // Clean up current player
        cleanupPlayer()
        
        // Present native player
        let nativePlayerVC = NativePlayerVC()
        nativePlayerVC.streamURL = url
        nativePlayerVC.movieTitle = titleText
        nativePlayerVC.imdbId = imdbId
        nativePlayerVC.isTVShow = isTVShow
        nativePlayerVC.embedServers = allStreamResults
        nativePlayerVC.onServerSelected = { self.switchBackToEmbed($0) }
        
        present(nativePlayerVC, animated: true)
    }

    private func switchBackToEmbed(_ result: StreamResult) {
        dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            
            // Update stream result and reload
            self.streamResult = result
            self.cleanupPlayer()
            self.setupPlayer()
            self.hasSuccessfullyLoaded = true
            self.isFallbackActive = false
        }
    }
    
    // MARK: - Overlay Setup
    private func setupOverlay() {
        overlayView.frame = view.bounds
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.isUserInteractionEnabled = false  // Let taps pass through to webview
        view.addSubview(overlayView)
        
        topGradient.colors = [UIColor.black.withAlphaComponent(0.75).cgColor, UIColor.clear.cgColor]
        bottomGradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.75).cgColor]
        overlayView.layer.addSublayer(topGradient)
        overlayView.layer.addSublayer(bottomGradient)
        
        let topBar = UIView()
        topBar.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(topBar)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        serverButton.addTarget(self, action: #selector(serverTapped), for: .touchUpInside)
        view.addSubview(serverButton)
        
        topBar.addSubview(titleLabel)
        titleLabel.text = titleText
        
        overlayView.addSubview(bottomBar)
        bottomBar.isHidden = true // Initially hidden
        
        bottomBar.addSubview(currentTimeLabel)
        bottomBar.addSubview(progressSlider)
        bottomBar.addSubview(durationLabel)
        bottomBar.addSubview(bufferBar)
        
        progressSlider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(sliderTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        view.addSubview(subtitleLabel)
        view.addSubview(bufferingSpinner)
        
        view.addSubview(nextEpisodeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            serverButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            serverButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            serverButton.widthAnchor.constraint(equalToConstant: 40),
            serverButton.heightAnchor.constraint(equalToConstant: 40),
            
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            topBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            topBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            topBar.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: serverButton.leadingAnchor, constant: -8),
            
            bottomBar.bottomAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            bottomBar.leadingAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            bottomBar.trailingAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            bottomBar.heightAnchor.constraint(equalToConstant: 40),
            
            currentTimeLabel.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            currentTimeLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            
            durationLabel.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            durationLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            
            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 12),
            progressSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -12),
            progressSlider.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            
            bufferBar.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            bufferBar.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor),
            bufferBar.centerYAnchor.constraint(equalTo: progressSlider.centerYAnchor),
            
            subtitleLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            bufferingSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bufferingSpinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            nextEpisodeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            nextEpisodeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
        nextEpisodeButton.addTarget(self, action: #selector(nextEpisodeTapped), for: .touchUpInside)
        
        updateOrientationUI()
        // Don't auto-hide initially - buttons start hidden and appear only on long press in landscape
    }
    
    private func updateOrientationUI() {
        let isLandscape = self.isLandscape

        // Both portrait and landscape start hidden
        closeButton.isHidden = true
        serverButton.isHidden = true
        titleLabel.isHidden = true
        bottomBar.isHidden = true
        
        closeButton.alpha = 0
        serverButton.alpha = 0
        titleLabel.alpha = 0
        bottomBar.alpha = 0
        
        closeButton.isUserInteractionEnabled = false
        serverButton.isUserInteractionEnabled = false
        isOverlayVisible = false

        let topHeight: CGFloat = isLandscape ? 120 : 80
        let bottomHeight: CGFloat = isLandscape ? 100 : 80
        
        topGradient.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: topHeight)
        bottomGradient.frame = CGRect(x: 0, y: view.bounds.height - bottomHeight, width: view.bounds.width, height: bottomHeight)
    }
    
    // MARK: - Gestures
    private func setupGestures() {
        // Single tap to show controls when in top zone (15% of screen height)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)

        // Pan gestures for volume/brightness (landscape only)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.cancelsTouchesInView = false
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        let topZoneHeight = view.bounds.height * 0.15  // Top 15% of screen

        // Only respond to taps in top zone
        if location.y <= topZoneHeight {
            if isOverlayVisible {
                // If already visible, hide immediately on tap
                hideLandscapeControls()
            } else {
                // Show controls
                showLandscapeControls()
            }
        }
        // Taps in bottom 85% pass through to webview (do nothing)
    }
    
    // MARK: - Audio Session
    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] _ in self?.player?.play(); return .success }
        commandCenter.pauseCommand.addTarget { [weak self] _ in self?.player?.pause(); return .success }
        
        let info: [String: Any] = [MPMediaItemPropertyTitle: titleText]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - Time Update
    private func updateTimeUI(_ time: CMTime) {
        guard let item = player?.currentItem else { return }
        let cur = CMTimeGetSeconds(time)
        let tot = CMTimeGetSeconds(item.duration)
        guard tot.isNormal, tot > 0 else { return }
        
        currentTimeLabel.text = formatTime(cur)
        durationLabel.text = formatTime(tot)
        
        checkNextEpisodeButton(current: cur, total: tot)
    }
    
    private func checkNextEpisodeButton(current: Double, total: Double) {
        guard isTVShow, let currentIndex = currentEpisodeIndex, currentIndex + 1 < allEpisodes.count else { return }
        
        let remaining = total - current
        let shouldShow = remaining <= 90 // 1 minute 30 seconds
        
        if shouldShow && !nextEpisodeButtonVisible {
            showNextEpisodeButton()
        } else if !shouldShow && nextEpisodeButtonVisible {
            hideNextEpisodeButton()
        }
    }
    
    private func showNextEpisodeButton() {
        guard let currentIndex = currentEpisodeIndex, currentIndex + 1 < allEpisodes.count else { return }
        let nextEp = allEpisodes[currentIndex + 1]
        let title = "Next: S\(nextEp.seasonNumber)E\(nextEp.episodeNumber) - \(nextEp.name ?? "Episode")"
        nextEpisodeButton.setTitle(title, for: .normal)
        
        nextEpisodeButton.isHidden = false
        nextEpisodeButton.transform = CGAffineTransform(translationX: 50, y: 0)
        nextEpisodeButtonVisible = true
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) {
            self.nextEpisodeButton.alpha = 1
            self.nextEpisodeButton.transform = .identity
        }
    }
    
    private func hideNextEpisodeButton() {
        nextEpisodeButtonVisible = false
        UIView.animate(withDuration: 0.5, animations: {
            self.nextEpisodeButton.alpha = 0
            self.nextEpisodeButton.transform = CGAffineTransform(translationX: 50, y: 0)
        }) { _ in
            self.nextEpisodeButton.isHidden = true
        }
    }
    
    @objc private func nextEpisodeTapped() {
        HapticManager.shared.medium()
        guard let currentIndex = currentEpisodeIndex, currentIndex + 1 < allEpisodes.count else { return }
        let nextEp = allEpisodes[currentIndex + 1]
        loadEpisode(nextEp, index: currentIndex + 1)
    }
    
    private func loadEpisode(_ ep: Episode, index: Int) {
        hideNextEpisodeButton()
        cleanupPlayer()
        bufferingSpinner.startAnimating()
        
        self.currentEpisodeIndex = index
        self.titleText = "\(titleText.components(separatedBy: " - ").first ?? "Show") - S\(ep.seasonNumber)E\(ep.episodeNumber)"
        self.titleLabel.text = titleText
        
        TMDBService.shared.fetchExternalIDs(tmdbId: tmdbId, isMovie: false) { [weak self] imdbId in
            guard let self = self else { return }
            self.imdbId = imdbId
            SourceManager.shared.buildAllEmbedSources(tmdbId: self.tmdbId, isTVShow: true, season: ep.seasonNumber, episode: ep.episodeNumber, imdbId: imdbId) { allSources in
                guard let first = allSources.first else {
                    HapticManager.shared.strong()
                    self.showErrorView()
                    return
                }
                self.allStreamResults = allSources
                self.streamResult = first
                self.isEmbed = first.isEmbed
                self.setupPlayer()
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        saveToHistory()
        overlayTimer?.cancel()
        player?.pause()
        dismiss(animated: true)
    }
    
    @objc private func serverTapped() {
        guard !allStreamResults.isEmpty else { return }
        
        let serverSheet = ServerSelectionSheet()
        serverSheet.servers = allStreamResults
        serverSheet.currentServerId = streamResult?.sourceId
        serverSheet.serverStatuses = serverCheckResults
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ServerCheckUpdated"), object: nil, queue: .main) { [weak serverSheet, weak self] _ in
            guard let self = self, let sheet = serverSheet else { return }
            sheet.updateStatuses(self.serverCheckResults)
        }
        
        serverSheet.onServerSelected = { [weak self] source in
            HapticManager.shared.medium()
            guard let self = self else { return }
            if source.sourceId != self.streamResult?.sourceId {
                self.hasSwitchedServer = true
                self.currentServerIndex = self.allStreamResults.firstIndex(where: { $0.sourceId == source.sourceId }) ?? 0
                self.cleanupPlayer()
                self.streamResult = source
                self.isEmbed = source.isEmbed
                self.setupPlayer()
            }
        }
        
        if let sheet = serverSheet.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(serverSheet, animated: true)
        scheduleAutoHide()
    }
    
    @objc private func sliderTouchDown() {
        isScrubbing = true
        overlayTimer?.cancel()
    }
    
    @objc private func sliderTouchUp() {
        isScrubbing = false
        scheduleAutoHide()
    }
    
    @objc private func playerDidFinish() {
        if !isTVShow { closeTapped() }
    }
    
    // MARK: - Overlay Toggle
    private func scheduleAutoHide() {
        overlayTimer?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isScrubbing else { return }
            self.hideLandscapeControls()
        }
        overlayTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
    }

    private func showLandscapeControls() {
        isOverlayVisible = true

        closeButton.isHidden = false
        closeButton.alpha = 0
        closeButton.isUserInteractionEnabled = true
        
        if isLandscape {
            serverButton.isHidden = false
            titleLabel.isHidden = false
            serverButton.alpha = 0
            titleLabel.alpha = 0
            serverButton.isUserInteractionEnabled = true
        }

        if !isEmbed {
            bottomBar.isHidden = false
            bottomBar.alpha = 0
        }

        overlayView.isUserInteractionEnabled = true

        UIView.animate(withDuration: 0.3) {
            self.closeButton.alpha = 1
            if self.isLandscape {
                self.serverButton.alpha = 1
                self.titleLabel.alpha = 1
            }
            if !self.isEmbed {
                self.bottomBar.alpha = 1
            }
        }
        scheduleAutoHide()
    }

    private func hideLandscapeControls() {
        isOverlayVisible = false

        UIView.animate(withDuration: 0.3) {
            self.closeButton.alpha = 0
            self.serverButton.alpha = 0
            self.titleLabel.alpha = 0
            self.bottomBar.alpha = 0
        } completion: { _ in
            self.closeButton.isHidden = true
            self.serverButton.isHidden = true
            self.titleLabel.isHidden = true
            self.bottomBar.isHidden = true
            self.closeButton.isUserInteractionEnabled = false
            self.serverButton.isUserInteractionEnabled = false
            self.overlayView.isUserInteractionEnabled = false
        }
    }
    
    // MARK: - Gesture Handlers
    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard isLandscape else { return }
        
        let loc = g.location(in: view)
        let trans = g.translation(in: view)
        let width = view.bounds.width
        
        let zoneWidth = width / 3
        
        switch g.state {
        case .began:
            startPanPoint = loc
            startBrightness = UIScreen.main.brightness
            startVolume = volumeSlider?.value ?? AVAudioSession.sharedInstance().outputVolume
            
        case .changed:
            if startPanPoint.x < zoneWidth {
                let delta = Float(trans.y / view.bounds.height)
                let newBrightness = max(0, min(1, startBrightness - CGFloat(delta)))
                UIScreen.main.brightness = newBrightness
                IndicatorManager.shared.showBrightnessIndicator(value: Float(newBrightness), in: view)
                
            } else if startPanPoint.x > zoneWidth * 2 {
                let delta = Float(trans.y / view.bounds.height)
                let newVol = max(0, min(1, startVolume - delta))
                volumeSlider?.value = newVol
                IndicatorManager.shared.showVolumeIndicator(value: newVol, in: view)
            }
            
        case .ended, .cancelled, .failed:
            IndicatorManager.shared.hideAllIndicators()
            
        default: break
        }
    }
    
    // MARK: - History
    private func saveToHistory() {
        guard tmdbId != 0 else { return }
        let contentType = isTVShow ? "TV" : "Movie"
        
        var currentProgress: Double = 0
        var totalDuration: Double = 1
        
        if let p = player, let item = p.currentItem {
            let cur = CMTimeGetSeconds(p.currentTime())
            let tot = CMTimeGetSeconds(item.duration)
            if cur.isNormal && cur > 0 { currentProgress = cur }
            if tot.isNormal && tot > 0 { totalDuration = tot }
        }
        
        if isEmbed {
            currentProgress = startProgressSeconds
        }
        
        let newItem = HistoryItem(
            tmdbId: tmdbId,
            title: titleText,
            posterPath: posterPath,
            contentType: contentType,
            watchedDate: Date().toISO8601(),
            progressSeconds: currentProgress,
            durationSeconds: totalDuration
        )
        
        let defaults = UserDefaults.standard
        var history: [HistoryItem] = []
        if let data = defaults.data(forKey: "watchHistory"),
           let existing = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            history = existing
        }
        
        history.removeAll { $0.tmdbId == newItem.tmdbId }
        history.insert(newItem, at: 0)
        
        if let encoded = try? JSONEncoder().encode(history) {
            defaults.set(encoded, forKey: "watchHistory")
        }
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "loadedTimeRanges",
              let ranges = player?.currentItem?.loadedTimeRanges,
              let first = ranges.first?.timeRangeValue else { return }
        let loaded = CMTimeGetSeconds(first.start) + CMTimeGetSeconds(first.duration)
        let total = CMTimeGetSeconds(player?.currentItem?.duration ?? .zero)
        if total > 0 { bufferBar.progress = Float(loaded / total) }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PlayerVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton || touch.view is UISlider {
            return false
        }
        
        if touch.view == progressSlider || touch.view?.superview == progressSlider {
            return false
        }
        
        if gestureRecognizer is UIPanGestureRecognizer {
            return isLandscape
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UILabel Padding Extension
extension UILabel {
    private struct AssociatedKeys {
        static var padding = "padding"
    }
    
    var padding: UIEdgeInsets {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.padding) as? UIEdgeInsets ?? .zero
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.padding, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
