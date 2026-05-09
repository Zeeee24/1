import UIKit

class AnimeDetailVC: BaseViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let backdropImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let gradientOverlay: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor,
            UIColor.black.cgColor
        ]
        gradient.locations = [0.3, 0.7, 1.0]
        return gradient
    }()
    
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
        label.font = .boldSystemFont(ofSize: 24)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let overviewLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("▶  Watch Now", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#E50914")
        button.layer.cornerRadius = 25
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addNetflixTouchEffect()
        return button
    }()
    
    private let episodeListButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("📺  Episodes", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 0.2, alpha: 1)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addNetflixTouchEffect()
        return button
    }()
    
    // MARK: - Data
    var anime: Anime?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = anime?.title
        setupUI()
        configureWithAnime()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientOverlay.frame = backdropImageView.bounds
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(backdropImageView)
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(overviewLabel)
        contentView.addSubview(playButton)
        contentView.addSubview(episodeListButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            backdropImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backdropImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backdropImageView.heightAnchor.constraint(equalToConstant: 250),
            
            posterImageView.topAnchor.constraint(equalTo: backdropImageView.bottomAnchor, constant: -60),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            posterImageView.widthAnchor.constraint(equalToConstant: 120),
            posterImageView.heightAnchor.constraint(equalToConstant: 180),
            
            titleLabel.topAnchor.constraint(equalTo: backdropImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            infoLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            overviewLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 16),
            overviewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            overviewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            playButton.topAnchor.constraint(equalTo: overviewLabel.bottomAnchor, constant: 24),
            playButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            playButton.widthAnchor.constraint(equalToConstant: 140),
            playButton.heightAnchor.constraint(equalToConstant: 50),
            
            episodeListButton.topAnchor.constraint(equalTo: overviewLabel.bottomAnchor, constant: 24),
            episodeListButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 12),
            episodeListButton.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            episodeListButton.heightAnchor.constraint(equalToConstant: 50),
            episodeListButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        backdropImageView.layer.addSublayer(gradientOverlay)
        
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        episodeListButton.addTarget(self, action: #selector(episodeListTapped), for: .touchUpInside)
    }
    
    private func configureWithAnime() {
        guard let anime = anime else { return }
        
        titleLabel.text = anime.title
        overviewLabel.text = anime.overview
        
        let info = "\(anime.status) • \(anime.episodeCount) episodes • ⭐️ \(String(format: "%.1f", anime.rating))"
        infoLabel.text = info
        
        if let posterPath = anime.posterPath {
            posterImageView.loadImage(from: "\(Constants.imageBaseURL)\(posterPath)")
            backdropImageView.loadImage(from: "\(Constants.backdropBaseURL)\(posterPath)")
        }
    }
    
    @objc private func playTapped() {
        guard let anime = anime else { return }
        
        // Build TBCPL anime sources
        let sources = SourceManager.shared.buildAnimeSources(animeId: anime.id, episode: 1)
        
        guard let firstSource = sources.first else {
            showAlert(title: "Error", message: "No streaming sources available")
            return
        }
        
        let playerVC = PlayerVC()
        playerVC.streamResult = firstSource
        playerVC.allStreamResults = sources
        playerVC.tmdbId = anime.id
        playerVC.titleText = anime.title
        playerVC.isTVShow = true // Treat anime as TV show for episodes
        playerVC.posterPath = anime.posterPath
        playerVC.modalTransitionStyle = .crossDissolve
        present(playerVC, animated: true)
    }
    
    @objc private func episodeListTapped() {
        guard let anime = anime else { return }
        
        let episodeVC = AnimeEpisodeVC()
        episodeVC.anime = anime
        navigationController?.pushViewController(episodeVC, animated: true)
    }
}
