import UIKit

class DetailVC: BaseViewController {
    var movie: Movie?
    var tvShow: TVShow?

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let backdropImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.1, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let gradientOverlay: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .boldSystemFont(ofSize: 26)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let metaStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let yearLabel: UILabel = {
        let l = UILabel()
        l.textColor = .lightGray
        l.font = .systemFont(ofSize: 15, weight: .medium)
        return l
    }()

    private let ratingBadgeContainer: UIView = {
        let v = UIView()
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        v.layer.cornerRadius = 3
        v.isHidden = true
        return v
    }()

    private let ratingBadgeLabel: UILabel = {
        let l = UILabel()
        l.textColor = .lightGray
        l.font = .systemFont(ofSize: 12, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let runtimeLabel: UILabel = {
        let l = UILabel()
        l.textColor = .lightGray
        l.font = .systemFont(ofSize: 15, weight: .medium)
        return l
    }()

    private func createDot() -> UILabel {
        let l = UILabel()
        l.text = "•"
        l.textColor = .lightGray
        l.font = .systemFont(ofSize: 15)
        return l
    }

    private let overviewLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 15)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let playBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("▶  Play Now", for: .normal)
        b.backgroundColor = UIColor(hex: "#E50914")
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.layer.cornerRadius = 10
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let watchLaterBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("＋ Watch Later", for: .normal)
        b.backgroundColor = .darkGray
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.layer.cornerRadius = 10
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let directStreamLabel: UILabel = {
        let l = UILabel()
        l.text = "OR WATCH WITH DIRECT STREAM"
        l.textColor = UIColor(hex: "#E50914")
        l.font = .systemFont(ofSize: 13, weight: .bold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let directStreamBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("⚡ Direct Stream", for: .normal)
        b.backgroundColor = UIColor(hex: "#1a1a1a")
        b.layer.borderColor = UIColor(hex: "#E50914")?.cgColor
        b.layer.borderWidth = 1
        b.setTitleColor(UIColor(hex: "#E50914"), for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.layer.cornerRadius = 10
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let btnStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .white
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private let tvContainer: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.isHidden = true
        return sv
    }()
    
    private lazy var seasonsCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(width: 100, height: 40)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(SeasonCell.self, forCellWithReuseIdentifier: SeasonCell.identifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return cv
    }()

    private let episodesStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private var episodes: [Episode] = []
    private var currentSeason: Int = 1
    private var totalSeasons: Int = 1

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        populateData()
        
        // Initial hidden state for animation
        contentView.alpha = 0
        contentView.transform = CGAffineTransform(translationX: 0, y: 50)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.6, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.contentView.alpha = 1
            self.contentView.transform = .identity
        })
    }

    // MARK: - Layout
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        [backdropImageView, gradientOverlay, titleLabel, metaStackView, overviewLabel, btnStack, loadingIndicator, directStreamLabel, directStreamBtn, tvContainer].forEach {
            contentView.addSubview($0)
        }

        ratingBadgeContainer.addSubview(ratingBadgeLabel)
        NSLayoutConstraint.activate([
            ratingBadgeLabel.topAnchor.constraint(equalTo: ratingBadgeContainer.topAnchor, constant: 2),
            ratingBadgeLabel.bottomAnchor.constraint(equalTo: ratingBadgeContainer.bottomAnchor, constant: -2),
            ratingBadgeLabel.leadingAnchor.constraint(equalTo: ratingBadgeContainer.leadingAnchor, constant: 4),
            ratingBadgeLabel.trailingAnchor.constraint(equalTo: ratingBadgeContainer.trailingAnchor, constant: -4)
        ])

        btnStack.addArrangedSubview(playBtn)
        btnStack.addArrangedSubview(watchLaterBtn)
        
        tvContainer.addArrangedSubview(seasonsCollection)
        tvContainer.addArrangedSubview(episodesStack)

        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backdropImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backdropImageView.heightAnchor.constraint(equalToConstant: 280),

            gradientOverlay.topAnchor.constraint(equalTo: backdropImageView.topAnchor),
            gradientOverlay.leadingAnchor.constraint(equalTo: backdropImageView.leadingAnchor),
            gradientOverlay.trailingAnchor.constraint(equalTo: backdropImageView.trailingAnchor),
            gradientOverlay.bottomAnchor.constraint(equalTo: backdropImageView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: backdropImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            metaStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            metaStackView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaStackView.trailingAnchor.constraint(lessThanOrEqualTo: titleLabel.trailingAnchor),

            overviewLabel.topAnchor.constraint(equalTo: metaStackView.bottomAnchor, constant: 12),
            overviewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            overviewLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            btnStack.topAnchor.constraint(equalTo: overviewLabel.bottomAnchor, constant: 24),
            btnStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            btnStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            btnStack.heightAnchor.constraint(equalToConstant: 54),
            
            directStreamLabel.topAnchor.constraint(equalTo: btnStack.bottomAnchor, constant: 20),
            directStreamLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            directStreamLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            directStreamBtn.topAnchor.constraint(equalTo: directStreamLabel.bottomAnchor, constant: 12),
            directStreamBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            directStreamBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            directStreamBtn.heightAnchor.constraint(equalToConstant: 54),
            
            tvContainer.topAnchor.constraint(equalTo: directStreamBtn.bottomAnchor, constant: 24),
            tvContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tvContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tvContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            episodesStack.leadingAnchor.constraint(equalTo: tvContainer.leadingAnchor, constant: 16),
            episodesStack.trailingAnchor.constraint(equalTo: tvContainer.trailingAnchor, constant: -16),

            loadingIndicator.centerXAnchor.constraint(equalTo: btnStack.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: btnStack.centerYAnchor)
        ])
        
        seasonsCollection.dataSource = self
        seasonsCollection.delegate = self

        playBtn.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        watchLaterBtn.addTarget(self, action: #selector(watchLaterTapped), for: .touchUpInside)
        directStreamBtn.addTarget(self, action: #selector(directStreamTapped), for: .touchUpInside)
        
        [playBtn, watchLaterBtn, directStreamBtn].forEach { $0.addNetflixTouchEffect() }
        updateWatchLaterButton()
    }

    // MARK: - Populate
    private func populateData() {
        let movieBackdrop = movie?.backdropPath
        let tvBackdrop = tvShow?.backdropPath
        let moviePoster = movie?.posterPath
        let tvPoster = tvShow?.posterPath
        let imagePath = movieBackdrop ?? tvBackdrop ?? moviePoster ?? tvPoster
        if let path = imagePath {
            backdropImageView.loadImage(from: "\(Constants.backdropBaseURL)\(path)") { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    let grad = CAGradientLayer()
                    grad.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 280)
                    grad.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
                    grad.locations = [0.5, 1.0]
                    self.gradientOverlay.layer.addSublayer(grad)
                }
            }
        }

        titleLabel.text = movie?.title ?? tvShow?.name ?? "Unknown"

        if let m = movie {
            TMDBService.shared.fetchMovieDetail(id: m.id) { [weak self] detail in
                guard let self = self, let detail = detail else { return }
                self.movie = detail
                self.updateMetadata()
                
                TMDBService.shared.fetchExternalIDs(tmdbId: detail.id, isMovie: true) { imdbId in
                    ServerCheckManager.shared.startChecking(tmdbId: detail.id, isTVShow: false, imdbId: imdbId)
                }
            }
        } else if let tv = tvShow {
            tvContainer.isHidden = false
            TMDBService.shared.fetchTVDetail(id: tv.id) { [weak self] detail in
                guard let self = self, let detail = detail else { return }
                self.tvShow = detail
                let total = detail.numberOfSeasons ?? 1
                self.totalSeasons = total
                self.seasonsCollection.reloadData()
                self.loadEpisodes(season: 1)
                self.updateMetadata()
            }
        }
    }

    private func updateMetadata() {
        metaStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let year = (movie?.releaseDate ?? tvShow?.firstAirDate)?.prefix(4) ?? ""
        yearLabel.text = String(year)
        metaStackView.addArrangedSubview(yearLabel)
        
        // Age Rating
        var certification: String?
        if let movie = movie {
            certification = movie.releaseDates?.results.first(where: { $0.iso3166_1 == "US" })?.releaseDates.first(where: { !$0.certification.isEmpty })?.certification
            if certification == nil {
                certification = movie.releaseDates?.results.first?.releaseDates.first(where: { !$0.certification.isEmpty })?.certification
            }
        } else if let tv = tvShow {
            certification = tv.contentRatings?.results.first(where: { $0.iso3166_1 == "US" })?.rating
            if certification == nil {
                certification = tv.contentRatings?.results.first?.rating
            }
        }
        
        if let cert = certification, !cert.isEmpty {
            metaStackView.addArrangedSubview(createDot())
            ratingBadgeLabel.text = cert
            ratingBadgeContainer.isHidden = false
            metaStackView.addArrangedSubview(ratingBadgeContainer)
        }
        
        // Runtime
        let runtimeMinutes = movie?.runtime ?? tvShow?.episodeRunTime?.first ?? 0
        if runtimeMinutes > 0 {
            metaStackView.addArrangedSubview(createDot())
            let h = runtimeMinutes / 60
            let m = runtimeMinutes % 60
            runtimeLabel.text = h > 0 ? "\(h)h \(m)m" : "\(m)m"
            metaStackView.addArrangedSubview(runtimeLabel)
        }
        
        // Star Rating (Optional, but prompt said "same line as year and star rating", wait, "Show the age rating and runtime... in the same line as the year and star rating")
        // Okay, let's add star rating too.
        if let rating = movie?.voteAverage ?? tvShow?.voteAverage, rating > 0 {
            metaStackView.addArrangedSubview(createDot())
            let ratingLabel = UILabel()
            ratingLabel.textColor = .lightGray
            ratingLabel.font = .systemFont(ofSize: 15, weight: .medium)
            ratingLabel.text = "⭐ \(String(format: "%.1f", rating))"
            metaStackView.addArrangedSubview(ratingLabel)
        }
    }

    // MARK: - Play
    @objc private func playTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let contentTitle = movie?.title ?? tvShow?.name ?? "CineDream"
        let tmdbId = movie?.id ?? tvShow?.id ?? 0
        let isTVShow = tvShow != nil

        guard tmdbId > 0 else {
            showAlert(title: "Error", message: "No TMDB ID available for this title.")
            return
        }

        // Fetch IMDB ID
        TMDBService.shared.fetchExternalIDs(tmdbId: tmdbId, isMovie: !isTVShow) { [weak self] imdbId in
            guard let self = self else { return }
            
            let playerVC = PlayerVC()
            playerVC.tmdbId = tmdbId
            playerVC.titleText = contentTitle
            playerVC.releaseYear = String((self.movie?.releaseDate ?? self.tvShow?.firstAirDate ?? "").prefix(4))
            playerVC.isTVShow = isTVShow
            playerVC.posterPath = self.movie?.posterPath ?? self.tvShow?.posterPath
            playerVC.imdbId = imdbId
            playerVC.modalTransitionStyle = .crossDissolve
            
            if isTVShow {
                ServerCheckManager.shared.startChecking(tmdbId: tmdbId, isTVShow: true, imdbId: imdbId, season: 1, episode: 1)
            }
            
            print("[DetailVC] Presenting PlayerVC for: \(contentTitle)")
            DispatchQueue.main.async {
                self.present(playerVC, animated: true) {
                    print("[DetailVC] PlayerVC presentation complete.")
                }
            }
        }
    }

    // MARK: - Direct Stream
    @objc private func directStreamTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let contentTitle = movie?.title ?? tvShow?.name ?? "CineDream"
        let tmdbId = movie?.id ?? tvShow?.id ?? 0
        let isTVShow = tvShow != nil

        guard tmdbId > 0 else {
            showAlert(title: "Error", message: "No TMDB ID available for this title.")
            return
        }

        directStreamBtn.setTitle("Loading...", for: .normal)
        directStreamBtn.isEnabled = false

        // Fetch IMDB ID and open VidSrc.icu embed
        TMDBService.shared.fetchExternalIDs(tmdbId: tmdbId, isMovie: !isTVShow) { [weak self] imdbId in
            guard let self = self, let imdbId = imdbId else {
                DispatchQueue.main.async {
                    self?.directStreamBtn.setTitle("⚡ Direct Stream", for: .normal)
                    self?.directStreamBtn.isEnabled = true
                    self?.showAlert(title: "Error", message: "Could not find IMDB ID.")
                }
                return
            }

            let cleanImdbId = imdbId.trimmingCharacters(in: .whitespacesAndNewlines)

            // Build embed sources including VidSrc.icu and VidSrc.mov
            SourceManager.shared.buildAllEmbedSources(tmdbId: tmdbId, isTVShow: isTVShow, imdbId: imdbId) { allSources in
                DispatchQueue.main.async {
                    self.directStreamBtn.setTitle("⚡ Direct Stream", for: .normal)
                    self.directStreamBtn.isEnabled = true

                    // Create VidSrc.icu URL as primary direct stream
                    let vidsrcURL = URL(string: "https://vidsrc.icu/embed/movie/\(cleanImdbId)")!

                    let directStreamResult = StreamResult(
                        sourceId: "vidsrc.icu",
                        sourceName: "VidSrc.icu (Direct Stream)",
                        quality: "1080p",
                        url: vidsrcURL,
                        isEmbed: true,
                        headers: nil
                    )

                    // Create player with VidSrc.icu
                    let playerVC = PlayerVC()
                    playerVC.streamResult = directStreamResult
                    playerVC.allStreamResults = [directStreamResult] + allSources
                    playerVC.tmdbId = tmdbId
                    playerVC.titleText = contentTitle
                    playerVC.isTVShow = isTVShow
                    playerVC.imdbId = imdbId
                    playerVC.posterPath = self.movie?.posterPath ?? self.tvShow?.posterPath

                    print("[DetailVC] Presenting Direct Stream PlayerVC for: \(contentTitle)")
                    DispatchQueue.main.async {
                        self.present(playerVC, animated: true) {
                            print("[DetailVC] Direct Stream PlayerVC presentation complete.")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Watch Later
    private func getWatchLaterList() -> [HistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: "watchLater"),
              let list = try? JSONDecoder().decode([HistoryItem].self, from: data) else { return [] }
        return list
    }

    private func updateWatchLaterButton() {
        let tmdbId = movie?.id ?? tvShow?.id ?? 0
        let list = getWatchLaterList()
        let isSaved = list.contains(where: { $0.tmdbId == tmdbId })
        watchLaterBtn.setTitle(isSaved ? "✓ Saved" : "＋ Watch Later", for: .normal)
        watchLaterBtn.backgroundColor = isSaved ? .darkGray : .darkGray
        watchLaterBtn.setTitleColor(isSaved ? .green : .white, for: .normal)
    }

    @objc private func watchLaterTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let tmdbId = movie?.id ?? tvShow?.id ?? 0
        guard tmdbId > 0 else { return }

        var list = getWatchLaterList()
        if list.contains(where: { $0.tmdbId == tmdbId }) {
            list.removeAll { $0.tmdbId == tmdbId }
        } else {
            let item = HistoryItem(
                tmdbId: tmdbId,
                title: movie?.title ?? tvShow?.name ?? "Unknown",
                posterPath: movie?.posterPath ?? tvShow?.posterPath,
                contentType: tvShow != nil ? "TV" : "Movie",
                watchedDate: Date().toISO8601(),
                progressSeconds: 0,
                durationSeconds: 1
            )
            list.insert(item, at: 0)
        }

        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: "watchLater")
        }
        updateWatchLaterButton()
    }
    // MARK: - TV Episodes Logic
    private func loadEpisodes(season: Int) {
        currentSeason = season
        
        if totalSeasons > 0 {
            let ip = IndexPath(item: season - 1, section: 0)
            seasonsCollection.selectItem(at: ip, animated: true, scrollPosition: .centeredHorizontally)
        }
        
        guard let tv = tvShow else { return }
        
        episodesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let loader = UIActivityIndicatorView(style: .medium)
        loader.color = .white
        loader.startAnimating()
        episodesStack.addArrangedSubview(loader)
        
        TMDBService.shared.fetchTVEpisodes(id: tv.id, season: season) { [weak self] eps in
            guard let self = self else { return }
            loader.removeFromSuperview()
            self.episodes = eps
            
            for (idx, ep) in eps.enumerated() {
                let epView = self.createEpisodeRow(ep: ep, index: idx)
                self.episodesStack.addArrangedSubview(epView)
            }
        }
    }
    
    private func createEpisodeRow(ep: Episode, index: Int) -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.15, alpha: 1)
        v.layer.cornerRadius = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let title = UILabel()
        title.text = "\(ep.episodeNumber). \(ep.name ?? "Episode \(ep.episodeNumber)")"
        title.textColor = .white
        title.font = .boldSystemFont(ofSize: 16)
        title.translatesAutoresizingMaskIntoConstraints = false
        
        let sub = UILabel()
        sub.text = ep.airDate ?? "Unknown Date"
        sub.textColor = .lightGray
        sub.font = .systemFont(ofSize: 12)
        sub.translatesAutoresizingMaskIntoConstraints = false
        
        v.addSubview(title)
        v.addSubview(sub)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: v.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
            sub.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            sub.leadingAnchor.constraint(equalTo: title.leadingAnchor)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(episodeTapped(_:)))
        v.addGestureRecognizer(tap)
        v.tag = index
        return v
    }
    
    @objc private func episodeTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        let ep = episodes[view.tag]
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let contentTitle = "\(tvShow?.name ?? "Show") - S\(ep.seasonNumber)E\(ep.episodeNumber)"
        let tmdbId = tvShow?.id ?? 0
        
        guard tmdbId > 0 else { return }
        
        // Fetch IMDB ID and start checking
        TMDBService.shared.fetchExternalIDs(tmdbId: tmdbId, isMovie: false) { [weak self] imdbId in
            guard let self = self else { return }
            
            ServerCheckManager.shared.startChecking(tmdbId: tmdbId, isTVShow: true, imdbId: imdbId, season: ep.seasonNumber, episode: ep.episodeNumber)
            
            let playerVC = PlayerVC()
            playerVC.tmdbId = tmdbId
            playerVC.titleText = contentTitle
            playerVC.releaseYear = String((self.tvShow?.firstAirDate ?? "").prefix(4))
            playerVC.isTVShow = true
            playerVC.imdbId = imdbId
            playerVC.posterPath = self.tvShow?.posterPath
            playerVC.allEpisodes = self.episodes
            playerVC.currentEpisodeIndex = view.tag
            playerVC.modalPresentationStyle = .overFullScreen
            playerVC.modalTransitionStyle = .crossDissolve
            
            DispatchQueue.main.async {
                self.present(playerVC, animated: true)
            }
        }
    }
    
}

// MARK: - Season Picker Collection View
extension DetailVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalSeasons
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SeasonCell.identifier, for: indexPath) as? SeasonCell else {
            return UICollectionViewCell()
        }
        cell.titleLabel.text = "Season \(indexPath.item + 1)"
        cell.isSelected = (indexPath.item + 1 == currentSeason)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        loadEpisodes(season: indexPath.item + 1)
    }
}

class SeasonCell: UICollectionViewCell {
    static let identifier = "SeasonCell"
    let titleLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(white: 0.2, alpha: 1)
        contentView.layer.cornerRadius = 20
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = isSelected ? UIColor(hex: "#E50914") : UIColor(white: 0.2, alpha: 1)
        }
    }
}
