import UIKit

class HistoryGridVC: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var items: [HistoryItem] = []
    let defaultsKey: String

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 110, height: 180)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(ContentCardCell.self, forCellWithReuseIdentifier: ContentCardCell.identifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.textColor = .gray
        l.font = .systemFont(ofSize: 16)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(title: String, defaultsKey: String) {
        self.defaultsKey = defaultsKey
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
        emptyLabel.text = "No items in \(title ?? "list")"

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadItems()
    }

    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let list = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            items = list
        }
        collectionView.reloadData()
        emptyLabel.isHidden = !items.isEmpty
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContentCardCell.identifier, for: indexPath) as? ContentCardCell else {
            return UICollectionViewCell()
        }
        let item = items[indexPath.row]

        let cItem = ContinueWatchingItem(
            tmdbId: item.tmdbId,
            title: item.title,
            posterPath: item.posterPath,
            backdropPath: nil,
            contentType: item.contentType,
            season: nil,
            episode: nil,
            progressSeconds: item.progressSeconds,
            durationSeconds: item.durationSeconds,
            lastWatched: Date()
        )
        cell.configure(with: cItem)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < items.count else { return }
        let item = items[indexPath.row]
        let vc = DetailVC()
        if item.contentType == "TV" {
            let tv = TVShow(id: item.tmdbId, name: item.title, overview: "", posterPath: item.posterPath, backdropPath: nil as String?, firstAirDate: nil as String?, voteAverage: 0, numberOfSeasons: nil as Int?, numberOfEpisodes: nil as Int?, contentRatings: nil, episodeRunTime: nil)
            vc.tvShow = tv
        } else {
            let movie = Movie(id: item.tmdbId, title: item.title, overview: "", posterPath: item.posterPath, backdropPath: nil, releaseDate: nil, voteAverage: 0, runtime: nil, releaseDates: nil)
            vc.movie = movie
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

class HistoryVC: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var historyItems: [HistoryItem] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 110, height: 165)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(HistoryItemCell.self, forCellWithReuseIdentifier: HistoryItemCell.identifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No watch history yet\nStart watching movies and TV shows to see them here"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Watch History"
        setupUI()
        loadHistory()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadHistory()
    }

    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "watchHistory"),
           let items = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            historyItems = items.sorted { $0.watchedDate > $1.watchedDate }
        } else {
            historyItems = []
        }

        collectionView.reloadData()
        emptyLabel.isHidden = !historyItems.isEmpty
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return historyItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HistoryItemCell.identifier, for: indexPath) as? HistoryItemCell else {
            return UICollectionViewCell()
        }

        let item = historyItems[indexPath.row]
        cell.configure(with: item)



        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = historyItems[indexPath.row]
        resumePlayback(for: item)
    }

    private func resumePlayback(for item: HistoryItem) {
        let isTV = (item.contentType == "TV")
        
        // Fetch IMDB ID and build sources
        TMDBService.shared.fetchExternalIDs(tmdbId: item.tmdbId, isMovie: !isTV) { [weak self] imdbId in
            guard let self = self else { return }
            
            SourceManager.shared.buildAllEmbedSources(tmdbId: item.tmdbId, isTVShow: isTV, imdbId: imdbId) { allSources in
                guard let first = allSources.first else { return }
                
                let playerVC = PlayerVC()
                playerVC.tmdbId = item.tmdbId
                playerVC.titleText = item.title
                playerVC.posterPath = item.posterPath
                playerVC.isTVShow = isTV
                playerVC.startProgressSeconds = item.progressSeconds
                playerVC.allStreamResults = allSources
                playerVC.streamResult = first
                playerVC.modalPresentationStyle = .overFullScreen
                playerVC.modalTransitionStyle = .crossDissolve
                self.present(playerVC, animated: true)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 110, height: 165)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = historyItems[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let action = UIAction(title: "Remove from History", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.removeFromHistory(item)
            }
            return UIMenu(title: "", children: [action])
        }
    }
    
    private func removeFromHistory(_ item: HistoryItem) {
        historyItems.removeAll { $0.tmdbId == item.tmdbId }
        if let encoded = try? JSONEncoder().encode(historyItems) {
            UserDefaults.standard.set(encoded, forKey: "watchHistory")
        }
        collectionView.reloadData()
        emptyLabel.isHidden = !historyItems.isEmpty
    }
}

class WatchLaterVC: HistoryGridVC {
    init() { super.init(title: "Watch Later", defaultsKey: "watchLater") }
    required init?(coder: NSCoder) { fatalError() }
}

class SettingsVC: BaseViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        setupUI()
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Content Section
        let contentSection = createSectionHeader(title: "Content")
        contentView.addSubview(contentSection)
        
        // History Button
        let historyButton = createSettingsButton(title: "Watch History", icon: "clock.arrow.circlepath") {
            let historyVC = HistoryVC()
            self.navigationController?.pushViewController(historyVC, animated: true)
        }
        contentView.addSubview(historyButton)
        
        // Clear cache button
        let clearCacheButton = createSettingsButton(title: "Clear Cache", icon: "trash") {
            self.clearCache()
        }
        contentView.addSubview(clearCacheButton)
        
        // Footer
        let footer = UILabel()
        footer.text = "Made By Zee"
        footer.textColor = .darkGray
        footer.font = .boldSystemFont(ofSize: 14)
        footer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(footer)
        
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
            
            contentSection.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            contentSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            historyButton.topAnchor.constraint(equalTo: contentSection.bottomAnchor, constant: 12),
            historyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            historyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            historyButton.heightAnchor.constraint(equalToConstant: 60),
            
            clearCacheButton.topAnchor.constraint(equalTo: historyButton.bottomAnchor, constant: 16),
            clearCacheButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            clearCacheButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            clearCacheButton.heightAnchor.constraint(equalToConstant: 60),
            
            footer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            footer.topAnchor.constraint(equalTo: clearCacheButton.bottomAnchor, constant: 40),
            footer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createSectionHeader(title: String) -> UILabel {
        let label = UILabel()
        label.text = title.uppercased()
        label.textColor = UIColor(hex: "#E50914")
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createSettingsButton(title: String, icon: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(white: 0.2, alpha: 1)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let iconImageView = UIImageView(image: UIImage(systemName: icon))
        iconImageView.tintColor = UIColor(hex: "#E50914")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrowImageView.tintColor = .lightGray
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        
        button.addSubview(iconImageView)
        button.addSubview(titleLabel)
        button.addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            arrowImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 16),
            arrowImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
    
    private func clearCache() {
        let alert = UIAlertController(title: "Clear Cache", message: "Are you sure you want to clear all cached data?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            CacheService.shared.clearCache()
            let successAlert = UIAlertController(title: "Success", message: "Cache cleared successfully", preferredStyle: .alert)
            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(successAlert, animated: true)
        })
        present(alert, animated: true)
    }
}

class SubtitleVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
}

class QualityVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
}

class SleepTimerVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
}
