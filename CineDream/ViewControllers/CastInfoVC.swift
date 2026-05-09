import UIKit

class CastInfoVC: BaseViewController {
    
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
    
    private let castCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 150)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(CastMemberCell.self, forCellWithReuseIdentifier: CastMemberCell.identifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let crewCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 150)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(CrewMemberCell.self, forCellWithReuseIdentifier: CrewMemberCell.identifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let relatedCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 180)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(ContentCardCell.self, forCellWithReuseIdentifier: ContentCardCell.identifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Data
    private var movie: Movie?
    private var tvShow: TVShow?
    private var castMembers: [CastMember] = []
    private var crewMembers: [CrewMember] = []
    private var relatedContent: [Movie] = []
    
    // MARK: - Initialization
    init(movie: Movie) {
        self.movie = movie
        super.init(nibName: nil, bundle: nil)
    }
    
    init(tvShow: TVShow) {
        self.tvShow = tvShow
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = movie?.title ?? tvShow?.name
        setupUI()
        loadContentInfo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientOverlay.frame = backdropImageView.bounds
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(backdropImageView)
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(overviewLabel)
        
        // Cast section
        let castSection = createSectionView(title: "Cast", collectionView: castCollectionView)
        contentView.addSubview(castSection)
        
        // Crew section
        let crewSection = createSectionView(title: "Crew", collectionView: crewCollectionView)
        contentView.addSubview(crewSection)
        
        // Related content section
        let relatedSection = createSectionView(title: "More Like This", collectionView: relatedCollectionView)
        contentView.addSubview(relatedSection)
        
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
            
            castSection.topAnchor.constraint(equalTo: overviewLabel.bottomAnchor, constant: 24),
            castSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            castSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            castSection.heightAnchor.constraint(equalToConstant: 200),
            
            crewSection.topAnchor.constraint(equalTo: castSection.bottomAnchor, constant: 16),
            crewSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            crewSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            crewSection.heightAnchor.constraint(equalToConstant: 200),
            
            relatedSection.topAnchor.constraint(equalTo: crewSection.bottomAnchor, constant: 16),
            relatedSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            relatedSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            relatedSection.heightAnchor.constraint(equalToConstant: 240),
            relatedSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        backdropImageView.layer.addSublayer(gradientOverlay)
        
        castCollectionView.dataSource = self
        castCollectionView.delegate = self
        crewCollectionView.dataSource = self
        crewCollectionView.delegate = self
        relatedCollectionView.dataSource = self
        relatedCollectionView.delegate = self
    }
    
    private func createSectionView(title: String, collectionView: UICollectionView) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func loadContentInfo() {
        if let movie = movie {
            configureWithMovie(movie)
        } else if let tvShow = tvShow {
            configureWithTVShow(tvShow)
        }
        
        loadCastAndCrew()
        loadRelatedContent()
    }
    
    private func configureWithMovie(_ movie: Movie) {
        titleLabel.text = movie.title
        
        let info = "\(movie.releaseDate ?? "") • \(movie.runtime ?? 0) min • ⭐️ \(String(format: "%.1f", movie.voteAverage ?? 0.0))"
        infoLabel.text = info
        
        overviewLabel.text = movie.overview
        
        if let backdropPath = movie.backdropPath {
            backdropImageView.loadImage(from: "\(Constants.backdropBaseURL)\(backdropPath)")
        }
        
        if let posterPath = movie.posterPath {
            posterImageView.loadImage(from: "\(Constants.imageBaseURL)\(posterPath)")
        }
    }
    
    private func configureWithTVShow(_ tvShow: TVShow) {
        titleLabel.text = tvShow.name
        
        let info = "\(tvShow.firstAirDate ?? "") • \(tvShow.numberOfEpisodes ?? 0) episodes • ⭐️ \(String(format: "%.1f", tvShow.voteAverage ?? 0.0))"
        infoLabel.text = info
        
        overviewLabel.text = tvShow.overview
        
        if let backdropPath = tvShow.backdropPath {
            backdropImageView.loadImage(from: "\(Constants.backdropBaseURL)\(backdropPath)")
        }
        
        if let posterPath = tvShow.posterPath {
            posterImageView.loadImage(from: "\(Constants.imageBaseURL)\(posterPath)")
        }
    }
    
    private func loadCastAndCrew() {
        // Mock cast data
        castMembers = [
            CastMember(id: 1, name: "Tom Cruise", character: "Ethan Hunt", profilePath: "/tom_cruise.jpg"),
            CastMember(id: 2, name: "Rebecca Ferguson", character: "Ilsa Faust", profilePath: "/rebecca.jpg"),
            CastMember(id: 3, name: "Simon Pegg", character: "Benji Dunn", profilePath: "/simon.jpg"),
            CastMember(id: 4, name: "Ving Rhames", character: "Luther Stickell", profilePath: "/ving.jpg"),
            CastMember(id: 5, name: "Henry Cavill", character: "August Walker", profilePath: "/henry.jpg")
        ]
        
        // Mock crew data
        crewMembers = [
            CrewMember(id: 1, name: "Christopher McQuarrie", job: "Director", profilePath: "/christopher.jpg"),
            CrewMember(id: 2, name: "Tom Cruise", job: "Producer", profilePath: "/tom_cruise.jpg"),
            CrewMember(id: 3, name: "Lorne Balfe", job: "Composer", profilePath: "/lorne.jpg"),
            CrewMember(id: 4, name: "Robert Elswit", job: "Cinematographer", profilePath: "/robert.jpg")
        ]
        
        castCollectionView.reloadData()
        crewCollectionView.reloadData()
    }
    
    private func loadRelatedContent() {
        // Mock related content
        relatedContent = [
            Movie(id: 101, title: "Related Movie 1", overview: "Similar action movie", posterPath: "/related1.jpg", backdropPath: nil, releaseDate: "2024", voteAverage: 8.2, runtime: 130, releaseDates: nil),
            Movie(id: 102, title: "Related Movie 2", overview: "Another great movie", posterPath: "/related2.jpg", backdropPath: nil, releaseDate: "2023", voteAverage: 7.8, runtime: 115, releaseDates: nil),
            Movie(id: 103, title: "Related Movie 3", overview: "Must watch film", posterPath: "/related3.jpg", backdropPath: nil, releaseDate: "2024", voteAverage: 8.5, runtime: 140, releaseDates: nil),
            Movie(id: 104, title: "Related Movie 4", overview: "Exciting thriller", posterPath: "/related4.jpg", backdropPath: nil, releaseDate: "2023", voteAverage: 7.5, runtime: 125, releaseDates: nil)
        ]
        
        relatedCollectionView.reloadData()
    }
}

// MARK: - Collection View Data Sources
extension CastInfoVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case castCollectionView:
            return castMembers.count
        case crewCollectionView:
            return crewMembers.count
        case relatedCollectionView:
            return relatedContent.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case castCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CastMemberCell.identifier, for: indexPath) as! CastMemberCell
            let castMember = castMembers[indexPath.row]
            cell.configure(with: castMember)
            return cell
            
        case crewCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CrewMemberCell.identifier, for: indexPath) as! CrewMemberCell
            let crewMember = crewMembers[indexPath.row]
            cell.configure(with: crewMember)
            return cell
            
        case relatedCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContentCardCell.identifier, for: indexPath) as! ContentCardCell
            let movie = relatedContent[indexPath.row]
            cell.configure(with: movie)
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
}

// MARK: - Collection View Delegates
extension CastInfoVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case relatedCollectionView:
            let movie = relatedContent[indexPath.row]
            let detailVC = DetailVC()
            detailVC.movie = movie
            navigationController?.pushViewController(detailVC, animated: true)
        default:
            break
        }
    }
}

// MARK: - Cast & Crew Models
struct CastMember {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?
}

struct CrewMember {
    let id: Int
    let name: String
    let job: String
    let profilePath: String?
}

// MARK: - Cast Member Cell
class CastMemberCell: UICollectionViewCell {
    static let identifier = "CastMemberCell"
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(white: 0.2, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let characterLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 10)
        label.textAlignment = .center
        label.numberOfLines = 2
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
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(characterLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            characterLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            characterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            characterLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            characterLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with castMember: CastMember) {
        nameLabel.text = castMember.name
        characterLabel.text = castMember.character
        
        if let profilePath = castMember.profilePath {
            profileImageView.loadImage(from: "\(Constants.imageBaseURL)\(profilePath)")
        }
    }
}

// MARK: - Crew Member Cell
class CrewMemberCell: UICollectionViewCell {
    static let identifier = "CrewMemberCell"
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(white: 0.2, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let jobLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 10)
        label.textAlignment = .center
        label.numberOfLines = 2
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
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(jobLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            jobLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            jobLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            jobLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            jobLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with crewMember: CrewMember) {
        nameLabel.text = crewMember.name
        jobLabel.text = crewMember.job
        
        if let profilePath = crewMember.profilePath {
            profileImageView.loadImage(from: "\(Constants.imageBaseURL)\(profilePath)")
        }
    }
}
