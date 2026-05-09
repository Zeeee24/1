import UIKit

class AnimeEpisodeVC: BaseViewController {
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        collectionView.register(AnimeEpisodeCell.self, forCellWithReuseIdentifier: AnimeEpisodeCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Data
    var anime: Anime?
    private var episodes: [AnimeEpisode] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Episodes"
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: view.bounds.width - 32, height: 80)
        }
        
        setupUI()
        loadEpisodes()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private func loadEpisodes() {
        guard let anime = anime else { return }
        
        // Generate mock episodes
        episodes = (1...anime.episodeCount).map { episodeNumber in
            AnimeEpisode(
                episodeNumber: episodeNumber,
                title: "Episode \(episodeNumber)",
                overview: "Episode \(episodeNumber) of \(anime.title)",
                airDate: "2024-01-\(String(format: "%02d", episodeNumber))"
            )
        }
        
        collectionView.reloadData()
    }
}

// MARK: - Collection View Data Source
extension AnimeEpisodeVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return episodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AnimeEpisodeCell.identifier, for: indexPath) as! AnimeEpisodeCell
        let episode = episodes[indexPath.row]
        if let anime = anime {
            cell.configure(with: episode, anime: anime)
        }
        return cell
    }
}

// MARK: - Collection View Delegate
extension AnimeEpisodeVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let anime = anime else { return }
        let episode = episodes[indexPath.row]
        
        // Build TBCPL anime sources for specific episode
        let sources = SourceManager.shared.buildAnimeSources(animeId: anime.id, episode: episode.episodeNumber)
        
        guard let firstSource = sources.first else {
            showAlert(title: "Error", message: "No streaming sources available for this episode")
            return
        }
        
        let playerVC = PlayerVC()
        playerVC.streamResult = firstSource
        playerVC.allStreamResults = sources
        playerVC.tmdbId = anime.id
        playerVC.titleText = "\(anime.title) - \(episode.title)"
        playerVC.isTVShow = true
        playerVC.posterPath = anime.posterPath
        playerVC.modalTransitionStyle = .crossDissolve
        present(playerVC, animated: true)
    }
}

// MARK: - Anime Episode Model
struct AnimeEpisode {
    let episodeNumber: Int
    let title: String
    let overview: String
    let airDate: String
}

// MARK: - Anime Episode Cell
class AnimeEpisodeCell: UICollectionViewCell {
    static let identifier = "AnimeEpisodeCell"
    
    private let episodeNumberLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.backgroundColor = UIColor(hex: "#E50914")
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let airDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        backgroundColor = UIColor(white: 0.1, alpha: 1)
        layer.cornerRadius = 8
        
        contentView.addSubview(episodeNumberLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(airDateLabel)
        
        NSLayoutConstraint.activate([
            episodeNumberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            episodeNumberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            episodeNumberLabel.widthAnchor.constraint(equalToConstant: 40),
            episodeNumberLabel.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: episodeNumberLabel.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            airDateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            airDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            airDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with episode: AnimeEpisode, anime: Anime) {
        episodeNumberLabel.text = "\(episode.episodeNumber)"
        titleLabel.text = episode.title
        airDateLabel.text = episode.airDate
    }
}
