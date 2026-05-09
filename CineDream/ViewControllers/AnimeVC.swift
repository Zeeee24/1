import UIKit

class AnimeVC: BaseViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Anime Sections
    private var trendingAnime: [Anime] = []
    private var newAnime: [Anime] = []
    private var popularAnime: [Anime] = []
    private var collectionViews: [UICollectionView] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Anime"
        setupUI()
        setupSections()
        loadAnimeData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupSections() {
        let sections = ["Trending Anime", "New Episodes", "Popular Anime"]
        for (index, title) in sections.enumerated() {
            let sectionView = makeSectionView(title: title, tag: index)
            contentView.addArrangedSubview(sectionView)
        }
    }
    
    private func makeSectionView(title: String, tag: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 180)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(AnimeCardCell.self, forCellWithReuseIdentifier: AnimeCardCell.identifier)
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.tag = tag
        cv.translatesAutoresizingMaskIntoConstraints = false
        collectionViews.append(cv)
        
        container.addSubview(label)
        container.addSubview(cv)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            cv.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            cv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            cv.heightAnchor.constraint(equalToConstant: 220),
            cv.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        return container
    }
    
    // MARK: - Data Loading
    private func loadAnimeData() {
        // Mock anime data
        trendingAnime = [
            Anime(id: 1001, title: "Attack on Titan", overview: "Humanity fights for survival against giant humanoid Titans", posterPath: "/aot.jpg", episodeCount: 87, rating: 9.0, status: "Completed"),
            Anime(id: 1002, title: "Demon Slayer", overview: "A young boy becomes a demon slayer to save his sister", posterPath: "/demonslayer.jpg", episodeCount: 26, rating: 8.7, status: "Ongoing"),
            Anime(id: 1003, title: "One Piece", overview: "Pirates search for the ultimate treasure One Piece", posterPath: "/onepiece.jpg", episodeCount: 1000, rating: 8.8, status: "Ongoing"),
            Anime(id: 1004, title: "Jujutsu Kaisen", overview: "Students battle cursed spirits in modern Japan", posterPath: "/jjk.jpg", episodeCount: 24, rating: 8.5, status: "Ongoing"),
            Anime(id: 1005, title: "My Hero Academia", overview: "Superhero school for the next generation of heroes", posterPath: "/mha.jpg", episodeCount: 138, rating: 8.4, status: "Ongoing")
        ]
        
        newAnime = [
            Anime(id: 2001, title: "Frieren", overview: "Elf mage reflects on her journey after adventure ends", posterPath: "/frieren.jpg", episodeCount: 28, rating: 9.1, status: "Ongoing"),
            Anime(id: 2002, title: "Chainsaw Man", overview: "Devil hunter with chainsaw powers seeks normal life", posterPath: "/chainsaw.jpg", episodeCount: 12, rating: 8.6, status: "Ongoing"),
            Anime(id: 2003, title: "Spy x Family", overview: "Spy builds fake family for mission", posterPath: "/spyfamily.jpg", episodeCount: 25, rating: 8.4, status: "Ongoing")
        ]
        
        popularAnime = [
            Anime(id: 3001, title: "Death Note", overview: "Student finds notebook that kills anyone whose name is written", posterPath: "/deathnote.jpg", episodeCount: 37, rating: 9.0, status: "Completed"),
            Anime(id: 3002, title: "Naruto", overview: "Young ninja seeks to become Hokage", posterPath: "/naruto.jpg", episodeCount: 720, rating: 8.3, status: "Completed"),
            Anime(id: 3003, title: "Bleach", overview: "Teen becomes Soul Reaper fighting evil spirits", posterPath: "/bleach.jpg", episodeCount: 366, rating: 8.2, status: "Completed")
        ]
        
        // Reload collection views
        DispatchQueue.main.async {
            self.collectionViews.forEach { $0.reloadData() }
        }
    }
}

// MARK: - Collection View Data Source
extension AnimeVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView.tag {
        case 0: return trendingAnime.count
        case 1: return newAnime.count
        case 2: return popularAnime.count
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AnimeCardCell.identifier, for: indexPath) as! AnimeCardCell
        
        var anime: Anime?
        switch collectionView.tag {
        case 0: anime = trendingAnime[indexPath.row]
        case 1: anime = newAnime[indexPath.row]
        case 2: anime = popularAnime[indexPath.row]
        default: break
        }
        
        if let a = anime {
            cell.configure(with: a)
        }
        
        return cell
    }
}

// MARK: - Collection View Delegate
extension AnimeVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var anime: Anime?
        switch collectionView.tag {
        case 0: anime = trendingAnime[indexPath.row]
        case 1: anime = newAnime[indexPath.row]
        case 2: anime = popularAnime[indexPath.row]
        default: break
        }
        
        guard let selectedAnime = anime else { return }
        
        let detailVC = AnimeDetailVC()
        detailVC.anime = selectedAnime
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Anime Model
struct Anime {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let episodeCount: Int
    let rating: Double
    let status: String
}

// MARK: - Anime Card Cell
class AnimeCardCell: UICollectionViewCell {
    static let identifier = "AnimeCardCell"
    
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(white: 0.2, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let episodeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 10)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addNetflixHoverEffect()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        addNetflixHoverEffect()
    }
    
    private func setupUI() {
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(episodeLabel)
        
        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterImageView.heightAnchor.constraint(equalToConstant: 160),
            
            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            
            episodeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            episodeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            episodeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            episodeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with anime: Anime) {
        titleLabel.text = anime.title
        episodeLabel.text = "\(anime.episodeCount) eps • ⭐️ \(anime.rating)"
        
        if let posterPath = anime.posterPath {
            posterImageView.loadImage(from: "\(Constants.imageBaseURL)\(posterPath)")
        }
    }
}
