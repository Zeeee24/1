import UIKit
import AVFoundation
import AVKit
import MediaPlayer

// MARK: - Toast View
class ToastView: UIView {
    private let label = UILabel()
    
    init(message: String) {
        super.init(frame: .zero)
        setupView(message: message)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(message: String) {
        backgroundColor = UIColor(white: 0.2, alpha: 0.9)
        layer.cornerRadius = 8
        translatesAutoresizingMaskIntoConstraints = false
        
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
}

// MARK: - Native Player ViewController
class NativePlayerVC: UIViewController {
    
    // MARK: - Public Properties
    var streamURL: URL?
    var movieTitle: String = ""
    var imdbId: String?
    var isTVShow: Bool = false
    var season: Int?
    var episode: Int?
    var onSwitchToEmbed: (() -> Void)?
    var embedServers: [StreamResult] = []
    var currentEmbedServerId: String?
    var onServerSelected: ((StreamResult) -> Void)?
    
    // MARK: - Player
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    
    // MARK: - Subtitles
    private var subtitleGroups: [AVMediaSelectionGroup]?
    private var currentSubtitleOption: AVMediaSelectionOption?
    
    // MARK: - Controls State
    private var isControlsVisible = true
    private var controlsTimer: Timer?
    private var isPlaying = false
    private var isSeeking = false
    private var currentPlaybackRate: Float = 1.0
    private var isLandscape: Bool { UIDevice.current.orientation.isLandscape }
    
    // MARK: - UI Components - Container
    private let playerContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    // MARK: - UI Components - Top Bar
    private let topBarView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.4)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .boldSystemFont(ofSize: 16)
        l.textAlignment = .center
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let serverButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        b.setImage(UIImage(systemName: "server.rack", withConfiguration: config), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // MARK: - UI Components - Center Controls
    private let centerControlsView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let playPauseButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .semibold)
        b.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // MARK: - UI Components - Bottom Bar
    private let bottomBarView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.4)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let currentTimeLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        l.text = "0:00"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let durationLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        l.text = "0:00"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let seekSlider: UISlider = {
        let s = UISlider()
        s.minimumTrackTintColor = UIColor(hex: "#E50914")
        s.maximumTrackTintColor = UIColor(white: 0.5, alpha: 0.5)
        s.thumbTintColor = .white
        s.value = 0
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private let ccButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        b.setImage(UIImage(systemName: "cc.circle", withConfiguration: config), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let speedButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("1x", for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 14)
        b.setTitleColor(.white, for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    
    // MARK: - Gesture Views (for brightness/volume in landscape)
    private let leftGestureView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let rightGestureView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    // MARK: - Indicators
    private var volumeIndicator: AnimatedIndicatorView?
    private var brightnessIndicator: AnimatedIndicatorView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupPlayer()
        setupGestures()
        setupNotifications()
        startControlsTimer()
        fetchSubtitles()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        playerLayer?.frame = playerContainerView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupPlayer()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Add container
        view.addSubview(playerContainerView)
        
        // Add gesture views (behind controls)
        playerContainerView.addSubview(leftGestureView)
        playerContainerView.addSubview(rightGestureView)
        
        // Add top bar
        view.addSubview(topBarView)
        topBarView.addSubview(backButton)
        topBarView.addSubview(titleLabel)
        topBarView.addSubview(serverButton)
        
        // Add center controls
        view.addSubview(centerControlsView)
        centerControlsView.addSubview(playPauseButton)
        
        // Add bottom bar
        view.addSubview(bottomBarView)
        bottomBarView.addSubview(currentTimeLabel)
        bottomBarView.addSubview(seekSlider)
        bottomBarView.addSubview(durationLabel)
        bottomBarView.addSubview(ccButton)
        bottomBarView.addSubview(speedButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Player container
            playerContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Gesture views (only active in landscape)
            leftGestureView.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
            leftGestureView.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            leftGestureView.widthAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 0.33),
            leftGestureView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor),
            
            rightGestureView.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor),
            rightGestureView.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            rightGestureView.widthAnchor.constraint(equalTo: playerContainerView.widthAnchor, multiplier: 0.33),
            rightGestureView.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor),
            
            // Top bar
            topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarView.heightAnchor.constraint(equalToConstant: 50),
            
            backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: topBarView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: serverButton.leadingAnchor, constant: -8),
            
            serverButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor, constant: -16),
            serverButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            serverButton.widthAnchor.constraint(equalToConstant: 44),
            serverButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Center controls
            centerControlsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerControlsView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            centerControlsView.widthAnchor.constraint(equalToConstant: 100),
            centerControlsView.heightAnchor.constraint(equalToConstant: 100),
            
            playPauseButton.centerXAnchor.constraint(equalTo: centerControlsView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: centerControlsView.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 80),
            playPauseButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Bottom bar
            bottomBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBarView.heightAnchor.constraint(equalToConstant: 70),
            
            currentTimeLabel.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 16),
            currentTimeLabel.centerYAnchor.constraint(equalTo: seekSlider.centerYAnchor),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 45),
            
            durationLabel.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -16),
            
            seekSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 8),
            seekSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            seekSlider.topAnchor.constraint(equalTo: bottomBarView.topAnchor, constant: 10),
            
            ccButton.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 16),
            ccButton.topAnchor.constraint(equalTo: seekSlider.bottomAnchor, constant: 8),
            ccButton.widthAnchor.constraint(equalToConstant: 36),
            ccButton.heightAnchor.constraint(equalToConstant: 36),
            
            speedButton.leadingAnchor.constraint(equalTo: ccButton.trailingAnchor, constant: 16),
            speedButton.centerYAnchor.constraint(equalTo: ccButton.centerYAnchor),
            speedButton.widthAnchor.constraint(equalToConstant: 50),
            speedButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Set title
        titleLabel.text = movieTitle
        
        // Add targets
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        serverButton.addTarget(self, action: #selector(serverTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        ccButton.addTarget(self, action: #selector(ccTapped), for: .touchUpInside)
        speedButton.addTarget(self, action: #selector(speedTapped), for: .touchUpInside)
        
        // Slider events
        seekSlider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        seekSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        seekSlider.addTarget(self, action: #selector(sliderTouchUp), for: [.touchUpInside, .touchUpOutside])
    }
    
    // MARK: - Player Setup
    private func setupPlayer() {
        guard let url = streamURL else {
            return
        }
        
        // Create asset with subtitle options
        let asset = AVAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = true
        player?.volume = 1.0
        
        // Setup player layer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = playerContainerView.bounds
        if let layer = playerLayer {
            playerContainerView.layer.insertSublayer(layer, at: 0)
        }
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateProgress(time: time)
        }
        
        // Observe duration
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), options: [.new, .initial], context: nil)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
        
        // Start playing
        player?.play()
        isPlaying = true
        updatePlayPauseButton()
    }
    
    private func cleanupPlayer() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration))
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        
        player?.pause()
        player = nil
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.duration) {
            if let duration = playerItem?.duration, duration.isNumeric {
                let seconds = CMTimeGetSeconds(duration)
                DispatchQueue.main.async {
                    self.durationLabel.text = self.formatTime(seconds)
                    self.seekSlider.maximumValue = Float(seconds)
                }
            }
        } else if keyPath == #keyPath(AVPlayerItem.status) {
            if playerItem?.status == .readyToPlay {
                // Silently ready
            } else if playerItem?.status == .failed {
                HapticManager.shared.strong()
            }
        }
    }
    
    // MARK: - Gestures
    private func setupGestures() {
        // Tap to toggle controls
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapToToggleControls))
        playerContainerView.addGestureRecognizer(tapGesture)
        
        // Brightness gesture (left side in landscape)
        let brightnessGesture = UIPanGestureRecognizer(target: self, action: #selector(handleBrightnessPan(_:)))
        leftGestureView.addGestureRecognizer(brightnessGesture)
        
        // Volume gesture (right side in landscape)
        let volumeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleVolumePan(_:)))
        rightGestureView.addGestureRecognizer(volumeGesture)
        
        // Double tap to seek
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        playerContainerView.addGestureRecognizer(doubleTapGesture)
        tapGesture.require(toFail: doubleTapGesture)
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func orientationChanged() {
        // Update gesture view visibility based on orientation
        let isLandscape = UIDevice.current.orientation.isLandscape
        leftGestureView.isUserInteractionEnabled = isLandscape
        rightGestureView.isUserInteractionEnabled = isLandscape
    }
    
    // MARK: - Actions
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    @objc private func serverTapped() {
        // Show embed server selection sheet
        let sheet = ServerSelectionSheet()
        sheet.servers = embedServers
        sheet.currentServerId = currentEmbedServerId
        sheet.onServerSelected = { [weak self] result in
            HapticManager.shared.medium()
            self?.onServerSelected?(result)
            self?.dismiss(animated: true)
        }
        present(sheet, animated: true)
    }
    
    @objc private func playPauseTapped() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
            player?.rate = currentPlaybackRate
        }
        isPlaying.toggle()
        updatePlayPauseButton()
        resetControlsTimer()
    }
    
    @objc private func ccTapped() {
        showSubtitleSelection()
        resetControlsTimer()
    }
    
    @objc private func speedTapped() {
        showSpeedSelection()
        resetControlsTimer()
    }
    
    
    @objc private func sliderTouchDown() {
        isSeeking = true
        controlsTimer?.invalidate()
    }
    
    @objc private func sliderValueChanged() {
        let seconds = Double(seekSlider.value)
        currentTimeLabel.text = formatTime(seconds)
    }
    
    @objc private func sliderTouchUp() {
        let seconds = Double(seekSlider.value)
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        player?.seek(to: time)
        isSeeking = false
        startControlsTimer()
    }
    
    @objc private func tapToToggleControls() {
        isControlsVisible.toggle()
        updateControlsVisibility()
        if isControlsVisible {
            startControlsTimer()
        }
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: playerContainerView)
        let isForward = location.x > playerContainerView.bounds.width / 2
        
        seekBy(seconds: isForward ? 10 : -10)
        
        // Seek feedback removed
    }
    
    private func seekBy(seconds: Double) {
        guard let player = player else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(0, currentTime + seconds)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
    }
    
    // MARK: - Brightness/Volume Gestures
    @objc private func handleBrightnessPan(_ gesture: UIPanGestureRecognizer) {
        guard isLandscape else { return }
        
        let translation = gesture.translation(in: leftGestureView)
        
        if gesture.state == .began {
            showBrightnessIndicator()
        } else if gesture.state == .changed {
            let delta = -translation.y / leftGestureView.bounds.height
            let currentBrightness = UIScreen.main.brightness
            let newBrightness = max(0, min(1, currentBrightness + delta * 0.05))
            UIScreen.main.brightness = newBrightness
            brightnessIndicator?.updateValue(Float(newBrightness))
        } else if gesture.state == .ended || gesture.state == .cancelled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.brightnessIndicator?.hide()
            }
        }
    }
    
    @objc private func handleVolumePan(_ gesture: UIPanGestureRecognizer) {
        guard isLandscape else { return }
        
        let translation = gesture.translation(in: rightGestureView)
        
        if gesture.state == .began {
            showVolumeIndicator()
        } else if gesture.state == .changed {
            let delta = -translation.y / rightGestureView.bounds.height
            let currentVolume = AVAudioSession.sharedInstance().outputVolume
            let newVolume = max(0, min(1, currentVolume + Float(delta * 0.05)))
            MPVolumeView.setVolume(newVolume)
            volumeIndicator?.updateValue(newVolume)
        } else if gesture.state == .ended || gesture.state == .cancelled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.volumeIndicator?.hide()
            }
        }
    }
    
    // MARK: - Indicators
    private func showBrightnessIndicator() {
        brightnessIndicator?.removeFromSuperview()
        let indicator = AnimatedIndicatorView(isVolume: false)
        indicator.updateValue(Float(UIScreen.main.brightness))
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 150),
            indicator.heightAnchor.constraint(equalToConstant: 80)
        ])
        brightnessIndicator = indicator
        indicator.show()
    }
    
    private func showVolumeIndicator() {
        volumeIndicator?.removeFromSuperview()
        let indicator = AnimatedIndicatorView(isVolume: true)
        indicator.updateValue(AVAudioSession.sharedInstance().outputVolume)
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 150),
            indicator.heightAnchor.constraint(equalToConstant: 80)
        ])
        volumeIndicator = indicator
        indicator.show()
    }
    
    // MARK: - Controls Visibility
    private func updateControlsVisibility() {
        let alpha: CGFloat = isControlsVisible ? 1 : 0
        UIView.animate(withDuration: 0.3) {
            self.topBarView.alpha = alpha
            self.bottomBarView.alpha = alpha
            self.centerControlsView.alpha = alpha
        }
    }
    
    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.isControlsVisible = false
            self?.updateControlsVisibility()
        }
    }
    
    private func resetControlsTimer() {
        startControlsTimer()
    }
    
    // MARK: - Updates
    private func updatePlayPauseButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .semibold)
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
    }
    
    private func updateProgress(time: CMTime) {
        guard !isSeeking else { return }
        let seconds = CMTimeGetSeconds(time)
        currentTimeLabel.text = formatTime(seconds)
        seekSlider.value = Float(seconds)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    // MARK: - Subtitles
    private func fetchSubtitles() {
        guard let imdbId = imdbId else { return }
        SubtitleService.shared.searchSubtitles(imdbId: imdbId) { subtitles in
            // Store available subtitles for selection
        }
    }
    
    private func showSubtitleSelection() {
        let alert = UIAlertController(title: "Subtitles", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Off", style: .default) { [weak self] _ in
            self?.selectSubtitle(nil)
        })
        
        // Add available subtitle options
        let languages = SubtitleService.shared.availableLanguages
        for language in languages {
            alert.addAction(UIAlertAction(title: language.name, style: .default) { [weak self] _ in
                self?.fetchAndSelectSubtitle(language: language.code)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func fetchAndSelectSubtitle(language: String) {
        guard let imdbId = imdbId else { return }
        SubtitleService.shared.searchSubtitles(imdbId: imdbId, language: language) { [weak self] subtitles in
            if let first = subtitles.first {
                SubtitleService.shared.downloadSubtitle(subtitleId: first.id) { url in
                    if let url = url {
                        self?.loadSubtitle(from: url)
                    }
                }
            }
        }
    }
    
    private func selectSubtitle(_ option: AVMediaSelectionOption?) {
        // Disable subtitles
    }
    
    private func loadSubtitle(from url: URL) {
        // Load external subtitle file
    }
    
    // MARK: - Speed Selection
    private func showSpeedSelection() {
        let alert = UIAlertController(title: "Playback Speed", message: nil, preferredStyle: .actionSheet)
        
        let speeds: [Float] = [0.5, 1.0, 1.25, 1.5, 2.0]
        let speedLabels = ["0.5x", "1x", "1.25x", "1.5x", "2x"]
        
        for (index, speed) in speeds.enumerated() {
            let isSelected = currentPlaybackRate == speed
            let title = isSelected ? "✓ \(speedLabels[index])" : speedLabels[index]
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.setPlaybackRate(speed)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func setPlaybackRate(_ rate: Float) {
        currentPlaybackRate = rate
        player?.rate = isPlaying ? rate : 0
        speedButton.setTitle("\(rate)x", for: .normal)
    }
    
    
    // MARK: - Toast
    func showToast(_ message: String) {
        // Disabled for a silent player experience
    }
}

// MARK: - MPVolumeView Extension
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        for view in volumeView.subviews {
            if let slider = view as? UISlider {
                slider.value = volume
                return
            }
        }
    }
}
