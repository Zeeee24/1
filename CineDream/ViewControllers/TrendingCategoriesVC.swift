import UIKit

class TrendingCategoriesVC: BaseViewController {
    
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
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Data
    private var categories: [TrendingCategory] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Trending"
        setupUI()
        loadCategories()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
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
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func loadCategories() {
        // Create trending categories
        categories = [
            TrendingCategory(
                title: "New Releases",
                subtitle: "Fresh this week",
                type: .newReleases,
                items: generateMockMovies(count: 8)
            ),
            TrendingCategory(
                title: "Popular This Week",
                subtitle: "Most watched",
                type: .popularThisWeek,
                items: generateMockMovies(count: 8)
            ),
            TrendingCategory(
                title: "Trending Now",
                subtitle: "Everyone's watching",
                type: .trendingNow,
                items: generateMockMovies(count: 8)
            ),
            TrendingCategory(
                title: "Coming Soon",
                subtitle: "Get ready",
                type: .comingSoon,
                items: generateMockMovies(count: 8)
            ),
            TrendingCategory(
                title: "Top Rated",
                subtitle: "Critics' choice",
                type: .topRated,
                items: generateMockMovies(count: 8)
            ),
            TrendingCategory(
                title: "Similar to Your Favorites",
                subtitle: "Because you watched...",
                type: .similar,
                items: generateMockMovies(count: 8)
            )
        ]
        
        // Create category sections
        for category in categories {
            let categoryView = createCategoryView(category: category)
            stackView.addArrangedSubview(categoryView)
        }
    }
    
    private func createCategoryView(category: TrendingCategory) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Header
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = category.title
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = category.subtitle
        subtitleLabel.textColor = .lightGray
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let seeAllButton = UIButton(type: .system)
        seeAllButton.setTitle("See All", for: .normal)
        seeAllButton.setTitleColor(UIColor(hex: "#E50914"), for: .normal)
        seeAllButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        seeAllButton.translatesAutoresizingMaskIntoConstraints = false
        seeAllButton.addNetflixTouchEffect()
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        headerView.addSubview(seeAllButton)
        
        // Collection View
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 140, height: 210)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(TrendingCardCell.self, forCellWithReuseIdentifier: TrendingCardCell.identifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.tag = category.type.rawValue
        
        // Add to container
        container.addSubview(headerView)
        container.addSubview(collectionView)
        
        // Constraints
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            seeAllButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            seeAllButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 230),
            collectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Setup collection view
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // See All button action
        seeAllButton.addAction(UIAction { _ in
            self.seeAllTapped(for: category)
        }, for: .touchUpInside)
        
        return container
    }
    
    private func seeAllTapped(for category: TrendingCategory) {
        let seeAllVC = SeeAllVC()
        seeAllVC.category = category
        navigationController?.pushViewController(seeAllVC, animated: true)
    }
    
    private func generateMockMovies(count: Int) -> [Movie] {
        return (0..<count).map { index in
            Movie(
                id: index + 1000,
                title: "Trending Movie \(index + 1)",
                overview: "An amazing trending movie that everyone is talking about.",
                posterPath: "/trending\(index).jpg",
                backdropPath: "/trending_back\(index).jpg",
                releaseDate: "2024",
                voteAverage: Double.random(in: 7.0...9.5),
                runtime: Int.random(in: 90...180),
                releaseDates: nil
            )
        }
    }
}

// MARK: - Trending Category Model
struct TrendingCategory {
    let title: String
    let subtitle: String
    let type: TrendingType
    let items: [Movie]
}

enum TrendingType: Int, CaseIterable {
    case newReleases = 100
    case popularThisWeek = 101
    case trendingNow = 102
    case comingSoon = 103
    case topRated = 104
    case similar = 105
    
    var title: String {
        switch self {
        case .newReleases: return "New Releases"
        case .popularThisWeek: return "Popular This Week"
        case .trendingNow: return "Trending Now"
        case .comingSoon: return "Coming Soon"
        case .topRated: return "Top Rated"
        case .similar: return "Similar"
        }
    }
}

// MARK: - Trending Card Cell
class TrendingCardCell: UICollectionViewCell {
    static let identifier = "TrendingCardCell"
    
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
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 10)
        label.backgroundColor = UIColor(hex: "#E50914")
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let trendingBadge: UILabel = {
        let label = UILabel()
        label.text = "🔥"
        label.font = .systemFont(ofSize: 16)
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
        contentView.addSubview(ratingLabel)
        contentView.addSubview(trendingBadge)
        
        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterImageView.heightAnchor.constraint(equalToConstant: 180),
            
            trendingBadge.topAnchor.constraint(equalTo: posterImageView.topAnchor, constant: 8),
            trendingBadge.trailingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: -8),
            
            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            ratingLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            ratingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ratingLabel.widthAnchor.constraint(equalToConstant: 30),
            ratingLabel.heightAnchor.constraint(equalToConstant: 16),
            ratingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
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
    
    func configure(with movie: Movie, trendingType: TrendingType) {
        titleLabel.text = movie.title
        ratingLabel.text = String(format: "%.1f", movie.voteAverage ?? 0.0)
        
        if let path = movie.posterPath {
            posterImageView.loadImage(from: "\(Constants.imageBaseURL)\(path)")
        }
        
        // Show trending badge for certain types
        switch trendingType {
        case .trendingNow, .popularThisWeek:
            trendingBadge.isHidden = false
        default:
            trendingBadge.isHidden = true
        }
    }
}

// MARK: - Collection View Data Source
extension TrendingCategoriesVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let trendingType = TrendingType(rawValue: collectionView.tag),
              let category = categories.first(where: { $0.type == trendingType }) else {
            return 0
        }
        return category.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrendingCardCell.identifier, for: indexPath) as! TrendingCardCell
        
        guard let trendingType = TrendingType(rawValue: collectionView.tag),
              let category = categories.first(where: { $0.type == trendingType }) else {
            return cell
        }
        
        let movie = category.items[indexPath.row]
        cell.configure(with: movie, trendingType: trendingType)
        
        return cell
    }
}

// MARK: - Collection View Delegate
extension TrendingCategoriesVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cardCell = cell as? TrendingCardCell {
            cardCell.animateAppearance()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let trendingType = TrendingType(rawValue: collectionView.tag),
              let category = categories.first(where: { $0.type == trendingType }) else {
            return
        }
        
        let movie = category.items[indexPath.row]
        let detailVC = DetailVC()
        detailVC.movie = movie
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - See All View Controller
class SeeAllVC: BaseViewController {
    
    var category: TrendingCategory?
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 110, height: 180)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(TrendingCardCell.self, forCellWithReuseIdentifier: TrendingCardCell.identifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = category?.title ?? "See All"
        setupUI()
    }
    
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
}

extension SeeAllVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cardCell = cell as? TrendingCardCell {
            cardCell.animateAppearance()
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return category?.items.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrendingCardCell.identifier, for: indexPath) as! TrendingCardCell
        
        if let movie = category?.items[indexPath.row] {
            cell.configure(with: movie, trendingType: category?.type ?? .trendingNow)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let movie = category?.items[indexPath.row] else { return }
        let detailVC = DetailVC()
        detailVC.movie = movie
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
