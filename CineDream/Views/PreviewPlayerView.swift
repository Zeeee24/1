import UIKit
import AVKit
import AVFoundation

class PreviewPlayerView: UIView {
    
    private let playerLayer: AVPlayerLayer
    private let player: AVPlayer
    private var previewTimer: Timer?
    private var isPlaying = false
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    
    private let playIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let soundIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "speaker.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 12)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var previewURL: URL?
    var contentTitle: String?
    
    override init(frame: CGRect) {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        super.init(frame: frame)
        setupUI()
        setupPlayer()
    }
    
    required init?(coder: NSCoder) {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        super.init(coder: coder)
        setupUI()
        setupPlayer()
    }
    
    private func setupUI() {
        layer.addSublayer(playerLayer)
        
        addSubview(overlayView)
        overlayView.addSubview(playIcon)
        overlayView.addSubview(soundIcon)
        overlayView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            playIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            playIcon.widthAnchor.constraint(equalToConstant: 24),
            playIcon.heightAnchor.constraint(equalToConstant: 24),
            
            soundIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            soundIcon.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            soundIcon.widthAnchor.constraint(equalToConstant: 16),
            soundIcon.heightAnchor.constraint(equalToConstant: 16),
            
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    private func setupPlayer() {
        playerLayer.videoGravity = .resizeAspectFill
        player.isMuted = true // Preview videos are muted by default
        player.actionAtItemEnd = .none
        
        // Loop the preview
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    func configure(previewURL: URL?, title: String?) {
        self.previewURL = previewURL
        self.contentTitle = title
        self.titleLabel.text = title
        
        if let url = previewURL {
            let playerItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: playerItem)
        }
    }
    
    func startPreview() {
        guard let url = previewURL else { return }
        
        // Show overlay briefly then fade out
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5, options: .curveEaseOut, animations: {
                self.overlayView.alpha = 0
            }, completion: nil)
        }
        
        // Start playing after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.player.play()
            self.isPlaying = true
            
            // Auto-stop after 30 seconds (Netflix preview length)
            self.previewTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
                self.stopPreview()
            }
        }
    }
    
    func stopPreview() {
        previewTimer?.invalidate()
        previewTimer = nil
        
        if isPlaying {
            player.pause()
            player.seek(to: CMTime.zero)
            isPlaying = false
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.overlayView.alpha = 0
        })
    }
    
    @objc private func playerItemDidReachEnd() {
        // Loop the preview
        player.seek(to: CMTime.zero)
        player.play()
    }
    
    deinit {
        previewTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        player.pause()
    }
}

// MARK: - Netflix Preview Manager
class NetflixPreviewManager {
    
    static let shared = NetflixPreviewManager()
    
    private var currentPreviewPlayer: PreviewPlayerView?
    private var currentCell: UICollectionViewCell?
    
    private init() {}
    
    func showPreview(for cell: UICollectionViewCell, previewURL: URL?, title: String?) {
        // Stop current preview if any
        stopCurrentPreview()
        
        guard let url = previewURL else { return }
        
        // Create preview player
        let previewPlayer = PreviewPlayerView(frame: cell.bounds)
        previewPlayer.configure(previewURL: url, title: title)
        previewPlayer.alpha = 0
        
        // Add to cell
        cell.contentView.insertSubview(previewPlayer, at: 0)
        
        NSLayoutConstraint.activate([
            previewPlayer.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            previewPlayer.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            previewPlayer.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            previewPlayer.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        
        // Animate in and start preview
        UIView.animate(withDuration: 0.3, animations: {
            previewPlayer.alpha = 1
        }) { _ in
            previewPlayer.startPreview()
        }
        
        currentPreviewPlayer = previewPlayer
        currentCell = cell
    }
    
    func stopCurrentPreview() {
        currentPreviewPlayer?.stopPreview()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.currentPreviewPlayer?.alpha = 0
        }) { _ in
            self.currentPreviewPlayer?.removeFromSuperview()
            self.currentPreviewPlayer = nil
            self.currentCell = nil
        }
    }
}

// MARK: - Enhanced Content Card with Preview
class NetflixContentCardCell: ContentCardCell {
    
    private var previewURL: URL?
    private var hoverTimer: Timer?
    
    override func configure(with movie: Movie) {
        super.configure(with: movie)
        
        // Mock preview URL - in real app, this would come from API
        if let backdropPath = movie.backdropPath {
            previewURL = URL(string: "\(Constants.backdropBaseURL)\(backdropPath)")
        }
    }
    
    override func configure(with tv: TVShow) {
        super.configure(with: tv)
        
        // Mock preview URL - in real app, this would come from API
        if let backdropPath = tv.backdropPath {
            previewURL = URL(string: "\(Constants.backdropBaseURL)\(backdropPath)")
        }
    }
    
    // Override hover methods for preview
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        // Start preview after 1 second of hover
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            if let url = self.previewURL {
                NetflixPreviewManager.shared.showPreview(for: self, previewURL: url, title: self.hoverTitleLabel.text)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        cancelHoverTimer()
        NetflixPreviewManager.shared.stopCurrentPreview()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        cancelHoverTimer()
        NetflixPreviewManager.shared.stopCurrentPreview()
    }
    
    private func cancelHoverTimer() {
        hoverTimer?.invalidate()
        hoverTimer = nil
    }
    
    deinit {
        cancelHoverTimer()
    }
}
