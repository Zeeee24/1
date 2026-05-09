import UIKit
import AVKit

class NetflixHeroView: UIView {
    
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let gradientOverlay: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor.black.cgColor
        ]
        gradient.locations = [0, 0.3, 0.7, 1]
        return gradient
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        if let descriptor = UIFont.systemFont(ofSize: 32, weight: .black).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 32)
        } else {
            label.font = .boldSystemFont(ofSize: 32)
        }
        label.numberOfLines = 3
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 2, height: 2)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("▶  Play", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor(hex: "#E50914")
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addNetflixTouchEffect()
        return button
    }()
    
    // More Info button removed
    
    private let maturityRating: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 14)
        label.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let qualityLabel: UILabel = {
        let label = UILabel()
        label.text = "4K UHD"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 12)
        label.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var playerLayer: AVPlayerLayer?
    private var isVideoPlaying = false
    
    var onPlayTapped: (() -> Void)?
    // More Info callback removed
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(backgroundImageView)
        layer.addSublayer(gradientOverlay)
        
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(playButton)
        addSubview(maturityRating)
        addSubview(qualityLabel)
        
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.bottomAnchor.constraint(equalTo: playButton.topAnchor, constant: -20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            subtitleLabel.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -8),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            playButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -60),
            playButton.widthAnchor.constraint(equalToConstant: 140),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            // More Info button constraints removed
            
            maturityRating.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            maturityRating.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            maturityRating.widthAnchor.constraint(equalToConstant: 30),
            maturityRating.heightAnchor.constraint(equalToConstant: 20),
            
            qualityLabel.leadingAnchor.constraint(equalTo: maturityRating.trailingAnchor, constant: 8),
            qualityLabel.centerYAnchor.constraint(equalTo: maturityRating.centerYAnchor),
            qualityLabel.widthAnchor.constraint(equalToConstant: 60),
            qualityLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientOverlay.frame = bounds
        playerLayer?.frame = bounds
    }
    
    func configure(with movie: Movie) {
        animateContentOut { [weak self] in
            guard let self = self else { return }
            self.titleLabel.text = movie.title
            self.subtitleLabel.text = movie.overview
            
            if let backdropPath = movie.backdropPath {
                self.backgroundImageView.loadImage(from: "\(Constants.backdropBaseURL)\(backdropPath)")
            } else if let posterPath = movie.posterPath {
                self.backgroundImageView.loadImage(from: "\(Constants.backdropBaseURL)\(posterPath)")
            }
            
            self.maturityRating.text = "13+"
            self.animateContentIn()
        }
    }
    
    func configure(with tvShow: TVShow) {
        animateContentOut { [weak self] in
            guard let self = self else { return }
            self.titleLabel.text = tvShow.name
            self.subtitleLabel.text = tvShow.overview
            
            if let backdropPath = tvShow.backdropPath {
                self.backgroundImageView.loadImage(from: "\(Constants.backdropBaseURL)\(backdropPath)")
            } else if let posterPath = tvShow.posterPath {
                self.backgroundImageView.loadImage(from: "\(Constants.backdropBaseURL)\(posterPath)")
            }
            
            self.maturityRating.text = "16+"
            self.animateContentIn()
        }
    }
    
    private func animateContentOut(completion: @escaping () -> Void) {
        if alpha == 0 {
            completion()
            return
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundImageView.alpha = 0
            self.titleLabel.alpha = 0
            self.subtitleLabel.alpha = 0
            self.playButton.alpha = 0
            self.maturityRating.alpha = 0
            self.qualityLabel.alpha = 0
        }) { _ in
            completion()
        }
    }

    private func animateContentIn() {
        // Reset states
        backgroundImageView.alpha = 0
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        subtitleLabel.alpha = 0
        maturityRating.alpha = 0
        qualityLabel.alpha = 0
        playButton.alpha = 0
        playButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        
        // 1. Background poster fade in
        UIView.animate(withDuration: 0.6) {
            self.backgroundImageView.alpha = 1
        }
        
        // 2. Movie title fade in and slide up
        UIView.animate(withDuration: 0.4, delay: 0.4, options: .curveEaseOut) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }
        
        // 3. Description text fade in
        UIView.animate(withDuration: 0.3, delay: 0.7, options: .curveEaseInOut) {
            self.subtitleLabel.alpha = 1
        }
        
        // 4. Rating and badge fade in
        UIView.animate(withDuration: 0.3, delay: 0.9, options: .curveEaseInOut) {
            self.maturityRating.alpha = 1
            self.qualityLabel.alpha = 1
        }
        
        // 5. Play button fade in with subtle scale
        UIView.animate(withDuration: 0.3, delay: 1.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.playButton.alpha = 1
            self.playButton.transform = .identity
        }
    }
    
    @objc private func playButtonTapped() {
        onPlayTapped?()
    }
    
    // More Info button method removed
    
    func startVideoPreview() {
        // This would start a video preview in the background
        // For now, we'll just add a subtle animation
        UIView.animate(withDuration: 0.3) {
            self.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        }
    }
    
    func stopVideoPreview() {
        UIView.animate(withDuration: 0.3) {
            self.transform = .identity
        }
    }
}
