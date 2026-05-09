import UIKit

class HomeVC: BaseViewController {

    var trendingMovies: [Movie] = []
    var latestMovies: [Movie] = []
    var topRated: [Movie] = []
    var continueWatching: [HistoryItem] = []
    var collectionViews: [UICollectionView] = []

    // Continue Watching section UI
    private let continueWatchingSection: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var continueWatchingCV: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 130, height: 195)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(NetflixContentCardCell.self, forCellWithReuseIdentifier: "ContinueWatchingCell")
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.tag = 99 // Tag for Continue Watching section
        return cv
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let heroView = NetflixHeroView()

    private var heroMovies: [Movie] = []
    private var currentHeroIndex: Int = 0
    private var heroTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupScrollLayout()
        setupHeroSection()
        setupSections()
        setupAnimations()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadContinueWatching()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    // MARK: - Nav Bar
    private func setupNavBar() {
        let logo = UILabel()
        logo.text = "CineDream"
        logo.textColor = UIColor(hex: "#E50914")
        if let descriptor = UIFont.systemFont(ofSize: 24, weight: .black).fontDescriptor.withDesign(.rounded) {
            logo.font = UIFont(descriptor: descriptor, size: 24)
        } else {
            logo.font = .boldSystemFont(ofSize: 24)
        }
        navigationItem.titleView = logo
    }

    // MARK: - Layout
    private func setupScrollLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupHeroSection() {
        // Setup Netflix hero view
        heroView.translatesAutoresizingMaskIntoConstraints = false
        heroView.heightAnchor.constraint(equalToConstant: 480).isActive = true
        
        heroView.onPlayTapped = { [weak self] in
            self?.heroPlayTapped()
        }
        
        // More Info callback removed
        
        contentStack.addArrangedSubview(heroView)
    }

    @objc private func heroPlayTapped() {
        guard !heroMovies.isEmpty else { return }
        let detailVC = DetailVC()
        detailVC.movie = heroMovies[currentHeroIndex]
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - Continue Watching
    private func setupContinueWatchingSection() {
        // Already configured in lazy var, but let's ensure it's in the stack
        continueWatchingCV.dataSource = self
        continueWatchingCV.delegate = self

        let label = UILabel()
        label.text = "Continue Watching"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false

        continueWatchingSection.addSubview(label)
        continueWatchingSection.addSubview(continueWatchingCV)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: continueWatchingSection.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: continueWatchingSection.leadingAnchor, constant: 16),

            continueWatchingCV.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            continueWatchingCV.leadingAnchor.constraint(equalTo: continueWatchingSection.leadingAnchor),
            continueWatchingCV.trailingAnchor.constraint(equalTo: continueWatchingSection.trailingAnchor),
            continueWatchingCV.heightAnchor.constraint(equalToConstant: 230),
            continueWatchingCV.bottomAnchor.constraint(equalTo: continueWatchingSection.bottomAnchor, constant: -8)
        ])

        continueWatchingSection.isHidden = true
    }

    private func reloadContinueWatching() {
        if let data = UserDefaults.standard.data(forKey: "watchHistory"),
           let list = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            continueWatching = list.filter { $0.progressSeconds > 0 && $0.progressSeconds < $0.durationSeconds - 30 }
            print("Loaded continue watching: \(continueWatching.count) items")
        } else {
            continueWatching = []
            print("No watch history found")
        }
        continueWatchingSection.isHidden = continueWatching.isEmpty
        continueWatchingCV.reloadData()
    }

    // MARK: - Sections
    private func setupSections() {
        // 1. Now Trending
        let trendingSection = makeSectionView(title: "Now Trending", tag: 0)
        contentStack.addArrangedSubview(trendingSection)
        
        // 2. Continue Watching (Conditional)
        setupContinueWatchingSection()
        contentStack.addArrangedSubview(continueWatchingSection)
        
        // 3. Latest Movies
        let latestSection = makeSectionView(title: "Latest Movies", tag: 1)
        contentStack.addArrangedSubview(latestSection)
        
        // 4. Top Rated
        let topRatedSection = makeSectionView(title: "Top Rated", tag: 2)
        contentStack.addArrangedSubview(topRatedSection)
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
        layout.itemSize = CGSize(width: 130, height: 195)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(NetflixContentCardCell.self, forCellWithReuseIdentifier: NetflixContentCardCell.identifier)
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

            cv.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            cv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            cv.heightAnchor.constraint(equalToConstant: 230),
            cv.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    // MARK: - Data
    private func loadData() {
        TMDBService.shared.fetchTrendingMovies { [weak self] movies in
            guard let self = self else { return }
            self.trendingMovies = movies
            self.heroMovies = Array(movies.prefix(5))
            DispatchQueue.main.async {
                self.startHeroShuffle()
                self.collectionViews.first?.reloadData()
            }
        }
        TMDBService.shared.fetchMovies(endpoint: "now_playing") { [weak self] movies in
            self?.latestMovies = movies
            if (self?.collectionViews.count ?? 0) > 1 { self?.collectionViews[1].reloadData() }
        }
        TMDBService.shared.fetchTopRatedMovies { [weak self] movies in
            self?.topRated = movies
            if (self?.collectionViews.count ?? 0) > 2 { self?.collectionViews[2].reloadData() }
        }
    }
    
    // MARK: - Hero Shuffle Logic
    private func startHeroShuffle() {
        guard !heroMovies.isEmpty else { return }
        updateHeroBanner()
        
        heroTimer?.invalidate()
        heroTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.heroMovies.isEmpty else { return }
            self.currentHeroIndex = (self.currentHeroIndex + 1) % self.heroMovies.count
            self.updateHeroBanner()
        }
    }
    
    private func updateHeroBanner() {
        updateHeroBannerWithAnimation()
    }
}

extension HomeVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cardCell = cell as? ContentCardCell {
            cardCell.animateAppearance()
        } else if let cardCell = cell as? NetflixContentCardCell {
            cardCell.animateAppearance()
        } else if let cardCell = cell as? ContinueWatchingCell {
            cardCell.animateAppearance()
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView.tag {
        case 0: return trendingMovies.count
        case 1: return latestMovies.count
        case 2: return topRated.count
        case 99: return continueWatching.count
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 99 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContinueWatchingCell", for: indexPath) as! NetflixContentCardCell
            let item = continueWatching[indexPath.row]
            cell.configure(with: item)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NetflixContentCardCell.identifier, for: indexPath) as! NetflixContentCardCell
        var movie: Movie?
        switch collectionView.tag {
        case 0: movie = trendingMovies[indexPath.row]
        case 1: movie = latestMovies[indexPath.row]
        case 2: movie = topRated[indexPath.row]
        default: break
        }
        
        if let m = movie { cell.configure(with: m) }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.tag == 99 {
            guard indexPath.row < continueWatching.count else { return }
            let item = continueWatching[indexPath.row]
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
                    
                    print("[HomeVC] Presenting Continue Watching PlayerVC for: \(item.title)")
                    DispatchQueue.main.async {
                        self.present(playerVC, animated: true) {
                            print("[HomeVC] Continue Watching PlayerVC presentation complete.")
                        }
                    }
                }
            }
            return
        }
        var movie: Movie?
        switch collectionView.tag {
        case 0: 
            guard indexPath.row < trendingMovies.count else { return }
            movie = trendingMovies[indexPath.row]
        case 1: 
            guard indexPath.row < latestMovies.count else { return }
            movie = latestMovies[indexPath.row]
        case 2: 
            guard indexPath.row < topRated.count else { return }
            movie = topRated[indexPath.row]
        default: break
        }

        if let m = movie {
            let detailVC = DetailVC()
            detailVC.movie = m
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        var movie: Movie?
        switch collectionView.tag {
        case 0: movie = trendingMovies[indexPath.row]
        case 1: movie = latestMovies[indexPath.row]
        case 2: movie = topRated[indexPath.row]
        default: break
        }
        
        guard let tmdbId = movie?.id, let m = movie else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let isSaved = self.isSavedToWatchLater(tmdbId: tmdbId)
            let title = isSaved ? "Remove from Watch Later" : "Add to Watch Later"
            let image = isSaved ? UIImage(systemName: "minus.circle") : UIImage(systemName: "plus.circle")
            
            let action = UIAction(title: title, image: image) { _ in
                self.toggleWatchLater(movie: m)
            }
            return UIMenu(title: "", children: [action])
        }
    }
    
    private func isSavedToWatchLater(tmdbId: Int) -> Bool {
        guard let data = UserDefaults.standard.data(forKey: "watchLater"),
              let list = try? JSONDecoder().decode([HistoryItem].self, from: data) else { return false }
        return list.contains { $0.tmdbId == tmdbId }
    }
    
    private func toggleWatchLater(movie: Movie) {
        HapticManager.shared.medium()
        var list: [HistoryItem] = []
        if let data = UserDefaults.standard.data(forKey: "watchLater"),
           let existing = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            list = existing
        }
        
        if let idx = list.firstIndex(where: { $0.tmdbId == movie.id }) {
            list.remove(at: idx)
        } else {
            let item = HistoryItem(tmdbId: movie.id, title: movie.title ?? "Unknown", posterPath: movie.posterPath, contentType: "Movie", watchedDate: Date().toISO8601(), progressSeconds: 0, durationSeconds: 1)
            list.insert(item, at: 0)
        }
        
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: "watchLater")
        }
    }
    
    // MARK: - Netflix Animations Setup
    private func setupAnimations() {
        collectionViews.forEach { $0.alpha = 0 }
        continueWatchingCV.alpha = 0
        heroView.alpha = 0
        
        // Animate hero section
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.heroView.fadeIn(duration: 0.5)
        }
        
        // Animate continue watching if visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.continueWatchingCV.alpha = 1
        }
        
        // Animate collection views independently (don't chain through hidden section)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.animateCollectionViews()
        }
    }
    
    private func animateCollectionViews() {
        for (index, collectionView) in collectionViews.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                collectionView.alpha = 1
                collectionView.slideUp(from: 50, duration: 0.4)
            }
        }
    }
    
    private func updateHeroBannerWithAnimation() {
        guard currentHeroIndex < heroMovies.count else { return }
        let movie = heroMovies[currentHeroIndex]
        
        // Update Netflix hero view with new movie
        heroView.configure(with: movie)
    }
}
