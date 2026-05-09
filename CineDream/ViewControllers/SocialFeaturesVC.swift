import UIKit

class SocialFeaturesVC: BaseViewController {
    
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
    
    private let shareSection: UIView = createSectionView(title: "Share & Recommend")
    private let reviewsSection: UIView = createSectionView(title: "Reviews & Ratings")
    private let statsSection: UIView = createSectionView(title: "Your Stats")
    
    // Share Section
    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share on Social Media", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#E50914")
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addNetflixTouchEffect()
        return button
    }()
    
    private let recommendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Recommend to Friends", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 0.2, alpha: 1)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addNetflixTouchEffect()
        return button
    }()
    
    // Reviews Section
    private let userRatingView: RatingView = {
        let view = RatingView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let reviewTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        textView.textColor = .white
        textView.font = .systemFont(ofSize: 16)
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let submitReviewButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Submit Review", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#E50914")
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addNetflixTouchEffect()
        return button
    }()
    
    // Stats Section
    private let statsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 150, height: 100)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(StatCell.self, forCellWithReuseIdentifier: StatCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Data
    private var currentMovie: Movie?
    private var currentTVShow: TVShow?
    private var userStats: UserStats = UserStats()
    
    // MARK: - Initialization
    init(movie: Movie) {
        self.currentMovie = movie
        super.init(nibName: nil, bundle: nil)
    }
    
    init(tvShow: TVShow) {
        self.currentTVShow = tvShow
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Social"
        setupUI()
        loadUserStats()
        setupReviewPlaceholder()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Share Section
        setupShareSection()
        contentView.addSubview(shareSection)
        
        // Reviews Section
        setupReviewsSection()
        contentView.addSubview(reviewsSection)
        
        // Stats Section
        setupStatsSection()
        contentView.addSubview(statsSection)
        
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
            
            shareSection.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            shareSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            shareSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            shareSection.heightAnchor.constraint(equalToConstant: 120),
            
            reviewsSection.topAnchor.constraint(equalTo: shareSection.bottomAnchor, constant: 24),
            reviewsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            reviewsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            reviewsSection.heightAnchor.constraint(equalToConstant: 250),
            
            statsSection.topAnchor.constraint(equalTo: reviewsSection.bottomAnchor, constant: 24),
            statsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsSection.heightAnchor.constraint(equalToConstant: 250),
            statsSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        statsCollectionView.dataSource = self
        statsCollectionView.delegate = self
    }
    
    private func setupShareSection() {
        shareSection.addSubview(shareButton)
        shareSection.addSubview(recommendButton)
        
        NSLayoutConstraint.activate([
            shareButton.topAnchor.constraint(equalTo: shareSection.topAnchor, constant: 16),
            shareButton.leadingAnchor.constraint(equalTo: shareSection.leadingAnchor),
            shareButton.trailingAnchor.constraint(equalTo: shareSection.trailingAnchor),
            shareButton.heightAnchor.constraint(equalToConstant: 44),
            
            recommendButton.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 12),
            recommendButton.leadingAnchor.constraint(equalTo: shareSection.leadingAnchor),
            recommendButton.trailingAnchor.constraint(equalTo: shareSection.trailingAnchor),
            recommendButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        recommendButton.addTarget(self, action: #selector(recommendTapped), for: .touchUpInside)
    }
    
    private func setupReviewsSection() {
        reviewsSection.addSubview(userRatingView)
        reviewsSection.addSubview(reviewTextView)
        reviewsSection.addSubview(submitReviewButton)
        
        NSLayoutConstraint.activate([
            userRatingView.topAnchor.constraint(equalTo: reviewsSection.topAnchor, constant: 16),
            userRatingView.centerXAnchor.constraint(equalTo: reviewsSection.centerXAnchor),
            userRatingView.heightAnchor.constraint(equalToConstant: 40),
            
            reviewTextView.topAnchor.constraint(equalTo: userRatingView.bottomAnchor, constant: 16),
            reviewTextView.leadingAnchor.constraint(equalTo: reviewsSection.leadingAnchor),
            reviewTextView.trailingAnchor.constraint(equalTo: reviewsSection.trailingAnchor),
            reviewTextView.heightAnchor.constraint(equalToConstant: 100),
            
            submitReviewButton.topAnchor.constraint(equalTo: reviewTextView.bottomAnchor, constant: 16),
            submitReviewButton.trailingAnchor.constraint(equalTo: reviewsSection.trailingAnchor),
            submitReviewButton.widthAnchor.constraint(equalToConstant: 120),
            submitReviewButton.heightAnchor.constraint(equalToConstant: 44),
            submitReviewButton.bottomAnchor.constraint(equalTo: reviewsSection.bottomAnchor, constant: -16)
        ])
        
        submitReviewButton.addTarget(self, action: #selector(submitReviewTapped), for: .touchUpInside)
    }
    
    private func setupStatsSection() {
        statsSection.addSubview(statsCollectionView)
        
        NSLayoutConstraint.activate([
            statsCollectionView.topAnchor.constraint(equalTo: statsSection.topAnchor, constant: 16),
            statsCollectionView.leadingAnchor.constraint(equalTo: statsSection.leadingAnchor),
            statsCollectionView.trailingAnchor.constraint(equalTo: statsSection.trailingAnchor),
            statsCollectionView.bottomAnchor.constraint(equalTo: statsSection.bottomAnchor, constant: -16)
        ])
    }
    
    private func loadUserStats() {
        // Load user stats from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "userStats"),
           let stats = try? JSONDecoder().decode(UserStats.self, from: data) {
            userStats = stats
        } else {
            // Generate mock stats
            userStats = UserStats(
                moviesWatched: 156,
                showsWatched: 23,
                totalWatchTime: 12480, // minutes
                favoriteGenre: "Action",
                averageRating: 4.2
            )
        }
        
        statsCollectionView.reloadData()
    }
    
    private func setupReviewPlaceholder() {
        reviewTextView.text = "Write your review here..."
        reviewTextView.textColor = .lightGray
        
        reviewTextView.delegate = self
    }
    
    @objc private func shareTapped() {
        let contentTitle = currentMovie?.title ?? currentTVShow?.name ?? "Amazing Content"
        let shareText = "I'm watching '\(contentTitle)' on CineDream! 🍿✨"
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityViewController, animated: true)
    }
    
    @objc private func recommendTapped() {
        let contentTitle = currentMovie?.title ?? currentTVShow?.name ?? "Amazing Content"
        let recommendText = "You should check out '\(contentTitle)' on CineDream! It's amazing! 🎬"
        
        let activityViewController = UIActivityViewController(
            activityItems: [recommendText],
            applicationActivities: nil
        )
        
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = recommendButton
            popover.sourceRect = recommendButton.bounds
        }
        
        present(activityViewController, animated: true)
    }
    
    @objc private func submitReviewTapped() {
        guard !reviewTextView.text.isEmpty && reviewTextView.textColor != .lightGray else {
            showAlert(title: "Error", message: "Please write a review before submitting")
            return
        }
        
        let rating = userRatingView.currentRating
        let reviewText = reviewTextView.text
        
        // Save review
        let review = UserReview(
            contentId: currentMovie?.id ?? currentTVShow?.id ?? 0,
            rating: rating,
            reviewText: reviewText ?? "",
            date: Date()
        )
        
        saveReview(review, rating: rating)
        
        // Show success message
        let alert = UIAlertController(title: "Review Submitted", message: "Thank you for your review!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Clear form
        userRatingView.resetRating()
        reviewTextView.text = "Write your review here..."
        reviewTextView.textColor = .lightGray
    }
    
    private func saveReview(_ review: UserReview, rating: Int) {
        var reviews: [UserReview] = []
        if let data = UserDefaults.standard.data(forKey: "userReviews"),
           let savedReviews = try? JSONDecoder().decode([UserReview].self, from: data) {
            reviews = savedReviews
        }
        
        reviews.append(review)
        
        if let data = try? JSONEncoder().encode(reviews) {
            UserDefaults.standard.set(data, forKey: "userReviews")
        }
        
        // Update user stats
        userStats.totalReviews += 1
        userStats.averageRating = (userStats.averageRating * Double(userStats.totalReviews - 1) + Double(rating)) / Double(userStats.totalReviews)
        
        if let data = try? JSONEncoder().encode(userStats) {
            UserDefaults.standard.set(data, forKey: "userStats")
        }
    }
    
    private static func createSectionView(title: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(white: 0.1, alpha: 1)
        container.layer.cornerRadius = 16
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        
        return container
    }
}

// MARK: - UITextView Delegate
extension SocialFeaturesVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .white
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write your review here..."
            textView.textColor = .lightGray
        }
    }
}

// MARK: - Collection View Data Source
extension SocialFeaturesVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatCell.identifier, for: indexPath) as! StatCell
        
        switch indexPath.item {
        case 0:
            cell.configure(title: "Movies Watched", value: "\(userStats.moviesWatched)", icon: "film.fill", color: "#E50914")
        case 1:
            cell.configure(title: "Shows Watched", value: "\(userStats.showsWatched)", icon: "tv.fill", color: "#00A8E1")
        case 2:
            let hours = userStats.totalWatchTime / 60
            let minutes = userStats.totalWatchTime % 60
            cell.configure(title: "Watch Time", value: "\(hours)h \(minutes)m", icon: "clock.fill", color: "#50C878")
        case 3:
            cell.configure(title: "Avg Rating", value: String(format: "%.1f⭐", userStats.averageRating), icon: "star.fill", color: "#FFB347")
        default:
            break
        }
        
        return cell
    }
}

// MARK: - Collection View Delegate
extension SocialFeaturesVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Show detailed stats
        let detailVC = StatsDetailVC()
        detailVC.userStats = userStats
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Rating View
class RatingView: UIView {
    
    private let starButtons: [UIButton] = (0..<5).map { _ in
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "star"), for: .normal)
        button.setImage(UIImage(systemName: "star.fill"), for: .selected)
        button.tintColor = .lightGray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    var currentRating: Int = 0 {
        didSet {
            updateStarDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: starButtons)
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        for (index, button) in starButtons.enumerated() {
            button.tag = index
            button.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
        }
    }
    
    @objc private func starTapped(_ sender: UIButton) {
        currentRating = sender.tag + 1
        updateStarDisplay()
    }
    
    private func updateStarDisplay() {
        for (index, button) in starButtons.enumerated() {
            button.isSelected = index < currentRating
            button.tintColor = button.isSelected ? UIColor(hex: "#E50914") : .lightGray
        }
    }
    
    func resetRating() {
        currentRating = 0
    }
}

// MARK: - Stat Cell
class StatCell: UICollectionViewCell {
    static let identifier = "StatCell"
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 20)
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
        backgroundColor = UIColor(white: 0.2, alpha: 1)
        layer.cornerRadius = 12
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(title: String, value: String, icon: String, color: String) {
        titleLabel.text = title
        valueLabel.text = value
        iconImageView.image = UIImage(systemName: icon)
        backgroundColor = UIColor(hex: color)
    }
}

// MARK: - Data Models
struct UserStats: Codable {
    var moviesWatched: Int = 0
    var showsWatched: Int = 0
    var totalWatchTime: Int = 0 // minutes
    var favoriteGenre: String = ""
    var averageRating: Double = 0.0
    var totalReviews: Int = 0
}

struct UserReview: Codable {
    let contentId: Int
    let rating: Int
    let reviewText: String
    let date: Date
}

// MARK: - Stats Detail View Controller
class StatsDetailVC: BaseViewController {
    
    var userStats: UserStats?
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Viewing Statistics"
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(StatsDetailCell.self, forCellReuseIdentifier: StatsDetailCell.identifier)
    }
}

extension StatsDetailVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StatsDetailCell.identifier, for: indexPath) as! StatsDetailCell
        
        guard let stats = userStats else { return cell }
        
        switch indexPath.row {
        case 0:
            cell.configure(icon: "film.fill", title: "Movies Watched", value: "\(stats.moviesWatched) movies")
        case 1:
            cell.configure(icon: "tv.fill", title: "TV Shows Watched", value: "\(stats.showsWatched) shows")
        case 2:
            let hours = stats.totalWatchTime / 60
            cell.configure(icon: "clock.fill", title: "Total Watch Time", value: "\(hours) hours")
        case 3:
            cell.configure(icon: "heart.fill", title: "Favorite Genre", value: stats.favoriteGenre)
        case 4:
            cell.configure(icon: "star.fill", title: "Average Rating", value: String(format: "%.1f stars", stats.averageRating))
        case 5:
            cell.configure(icon: "text.bubble.fill", title: "Reviews Written", value: "\(stats.totalReviews) reviews")
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

class StatsDetailCell: UITableViewCell {
    static let identifier = "StatsDetailCell"
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(hex: "#E50914")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .black
        selectionStyle = .none
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
    }
    
    func configure(icon: String, title: String, value: String) {
        iconImageView.image = UIImage(systemName: icon)
        titleLabel.text = title
        valueLabel.text = value
    }
}
