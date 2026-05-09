import UIKit

class ContentCardCell: UICollectionViewCell {
    static let identifier = "ContentCardCell"
    
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = UIColor(white: 0.1, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progressTintColor = UIColor(hex: "#E50914")
        pv.trackTintColor = .darkGray
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.isHidden = true
        return pv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(progressView)
        
        // Add hover overlay elements
        posterImageView.addSubview(hoverOverlay)
        hoverOverlay.addSubview(hoverPlayButton)
        hoverOverlay.addSubview(hoverTitleLabel)
        hoverOverlay.addSubview(hoverGenresLabel)
        
        // Add Netflix hover effect
        addNetflixHoverEffect()
        
        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterImageView.heightAnchor.constraint(equalTo: posterImageView.widthAnchor, multiplier: 1.5),
            
            // Hover overlay constraints
            hoverOverlay.topAnchor.constraint(equalTo: posterImageView.topAnchor),
            hoverOverlay.leadingAnchor.constraint(equalTo: posterImageView.leadingAnchor),
            hoverOverlay.trailingAnchor.constraint(equalTo: posterImageView.trailingAnchor),
            hoverOverlay.bottomAnchor.constraint(equalTo: posterImageView.bottomAnchor),
            
            hoverPlayButton.centerXAnchor.constraint(equalTo: hoverOverlay.centerXAnchor),
            hoverPlayButton.centerYAnchor.constraint(equalTo: hoverOverlay.centerYAnchor, constant: -10),
            hoverPlayButton.widthAnchor.constraint(equalToConstant: 40),
            hoverPlayButton.heightAnchor.constraint(equalToConstant: 40),
            
            hoverTitleLabel.leadingAnchor.constraint(equalTo: hoverOverlay.leadingAnchor, constant: 8),
            hoverTitleLabel.trailingAnchor.constraint(equalTo: hoverOverlay.trailingAnchor, constant: -8),
            hoverTitleLabel.bottomAnchor.constraint(equalTo: hoverGenresLabel.topAnchor, constant: 4),
            
            hoverGenresLabel.leadingAnchor.constraint(equalTo: hoverOverlay.leadingAnchor, constant: 8),
            hoverGenresLabel.trailingAnchor.constraint(equalTo: hoverOverlay.trailingAnchor, constant: -8),
            hoverGenresLabel.bottomAnchor.constraint(equalTo: hoverOverlay.bottomAnchor, constant: 8),
            
            progressView.bottomAnchor.constraint(equalTo: posterImageView.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: posterImageView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: posterImageView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 3),
            
            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
                self.layer.shadowColor = self.isHighlighted ? UIColor.black.cgColor : UIColor.clear.cgColor
                self.layer.shadowOpacity = self.isHighlighted ? 0.6 : 0
                self.layer.shadowRadius = self.isHighlighted ? 15 : 0
                self.layer.shadowOffset = CGSize(width: 0, height: 10)
                self.contentView.layer.zPosition = self.isHighlighted ? 10 : 0
            }, completion: nil)
        }
    }
    
    func animateAppearance() {
        self.alpha = 0
        self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.alpha = 1
            self.transform = .identity
        })
    }
    
    // Netflix-style hover overlay
    private let hoverOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    
    private let hoverPlayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(hex: "#E50914")
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        button.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        return button
    }()
    
    let hoverTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let hoverGenresLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    func configure(with movie: Movie) {
        titleLabel.text = movie.title
        hoverTitleLabel.text = movie.title
        hoverGenresLabel.text = "Action • Drama" // Mock genre
        
        if let path = movie.posterPath {
            posterImageView.loadImage(from: "\(Constants.imageBaseURL)\(path)")
        }
        progressView.isHidden = true
    }
    
    func configure(with tv: TVShow) {
        titleLabel.text = tv.name
        hoverTitleLabel.text = tv.name
        hoverGenresLabel.text = "TV Series • 2024" // Mock info
        
        if let path = tv.posterPath {
            posterImageView.loadImage(from: "\(Constants.imageBaseURL)\(path)")
        }
        progressView.isHidden = true
    }
    
    func configure(with item: HistoryItem) {
        titleLabel.text = item.title
        hoverTitleLabel.text = item.title
        hoverGenresLabel.text = "Continue Watching"
        
        if let path = item.posterPath {
            posterImageView.loadImage(from: "\(Constants.imageBaseURL)\(path)")
        }
        progressView.isHidden = false
        progressView.progress = Float(item.progressSeconds / item.durationSeconds)
    }
    
    func configure(with item: ContinueWatchingItem) {
        titleLabel.text = item.title
        hoverTitleLabel.text = item.title
        hoverGenresLabel.text = "Continue Watching"
        
        if let path = item.posterPath {
            posterImageView.loadImage(from: "\(Constants.imageBaseURL)\(path)")
        }
        progressView.isHidden = false
        progressView.progress = Float(item.progressSeconds / item.durationSeconds)
    }
    
    func configure(with posterPath: String?, title: String?) {
        titleLabel.text = title
        hoverTitleLabel.text = title
        hoverGenresLabel.text = "Content"
        
        if let path = posterPath {
            posterImageView.loadImage(from: "\(Constants.imageBaseURL)\(path)")
        }
        progressView.isHidden = true
    }
    
    // Netflix hover animation
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        showHoverOverlay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        hideHoverOverlay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        hideHoverOverlay()
    }
    
    private func showHoverOverlay() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.hoverOverlay.alpha = 1
            self.hoverPlayButton.transform = .identity
        }, completion: nil)
    }
    
    private func hideHoverOverlay() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.hoverOverlay.alpha = 0
            self.hoverPlayButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: nil)
    }
}
