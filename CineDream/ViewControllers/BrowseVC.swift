import UIKit

class BrowseVC: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    private var results: [SearchItem] = []

    private let typeSegment = UISegmentedControl(items: ["Movies", "TV Series"])
    private let genreBtn = UIButton(type: .system)
    private let langBtn = UIButton(type: .system)
    private let yearBtn = UIButton(type: .system)

    private var selectedGenreId: String = ""
    private var selectedLang: String = ""
    private var selectedYear: String = ""

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

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Browse"

        typeSegment.selectedSegmentIndex = 0
        typeSegment.addTarget(self, action: #selector(filterChanged), for: .valueChanged)

        setupFilterButton(genreBtn, title: "All Genres", action: #selector(selectGenre))
        setupFilterButton(langBtn, title: "All Languages", action: #selector(selectLanguage))
        setupFilterButton(yearBtn, title: "All Years", action: #selector(selectYear))

        let filterScrollView = UIScrollView()
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterScrollView)

        let stack = UIStackView(arrangedSubviews: [typeSegment, genreBtn, langBtn, yearBtn])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        filterScrollView.addSubview(stack)

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            filterScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterScrollView.heightAnchor.constraint(equalToConstant: 44),

            stack.topAnchor.constraint(equalTo: filterScrollView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor, constant: -16),
            stack.heightAnchor.constraint(equalTo: filterScrollView.heightAnchor),

            collectionView.topAnchor.constraint(equalTo: filterScrollView.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        fetchData()
    }

    private func setupFilterButton(_ btn: UIButton, title: String, action: Selector) {
        var config = UIButton.Configuration.filled()
        config.title = " \(title) ⌄ "
        config.baseBackgroundColor = UIColor(white: 0.2, alpha: 1)
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        btn.configuration = config
        btn.heightAnchor.constraint(equalToConstant: 32).isActive = true
        btn.addTarget(self, action: action, for: .touchUpInside)
    }

    @objc private func selectGenre() {
        let alert = UIAlertController(title: "Select Genre", message: nil, preferredStyle: .actionSheet)
        let genres = [
            ("All Genres", ""), ("Action", "28"), ("Adventure", "12"), ("Animation", "16"),
            ("Comedy", "35"), ("Crime", "80"), ("Documentary", "99"), ("Drama", "18"),
            ("Family", "10751"), ("Fantasy", "14"), ("History", "36"), ("Horror", "27"),
            ("Music", "10402"), ("Mystery", "9648"), ("Romance", "10749"), ("Sci-Fi", "878"),
            ("TV Movie", "10770"), ("Thriller", "53"), ("War", "10752"), ("Western", "37")
        ]
        for g in genres {
            alert.addAction(UIAlertAction(title: g.0, style: .default) { _ in
                self.genreBtn.setTitle(g.0, for: .normal)
                self.selectedGenreId = g.1
                self.fetchData()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func selectLanguage() {
        let alert = UIAlertController(title: "Select Language", message: nil, preferredStyle: .actionSheet)
        let langs = [("All Languages", ""), ("English", "en"), ("Hindi", "hi"), ("Spanish", "es"), ("Korean", "ko"), ("Japanese", "ja")]
        for l in langs {
            alert.addAction(UIAlertAction(title: l.0, style: .default) { _ in
                self.langBtn.setTitle(l.0, for: .normal)
                self.selectedLang = l.1
                self.fetchData()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func selectYear() {
        let alert = UIAlertController(title: "Select Year", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "All Years", style: .default) { _ in
            self.yearBtn.setTitle("All Years", for: .normal)
            self.selectedYear = ""
            self.fetchData()
        })
        let currentYear = Calendar.current.component(.year, from: Date())
        for y in (1990...currentYear).reversed() {
            alert.addAction(UIAlertAction(title: "\(y)", style: .default) { _ in
                self.yearBtn.setTitle("\(y)", for: .normal)
                self.selectedYear = "\(y)"
                self.fetchData()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func filterChanged() {
        fetchData()
    }

    private func fetchData() {
        let type = typeSegment.selectedSegmentIndex == 0 ? "movie" : "tv"
        var urlStr = "\(Constants.tmdbBaseURL)/discover/\(type)?api_key=\(Constants.tmdbAPIKey)&sort_by=popularity.desc"
        if !selectedGenreId.isEmpty { urlStr += "&with_genres=\(selectedGenreId)" }
        if !selectedLang.isEmpty { urlStr += "&with_original_language=\(selectedLang)" }
        if !selectedYear.isEmpty {
            urlStr += type == "movie" ? "&primary_release_year=\(selectedYear)" : "&first_air_date_year=\(selectedYear)"
        }

        guard let url = URL(string: urlStr) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data else { return }
            if type == "movie", let res = try? JSONDecoder().decode(TMDBResponse<Movie>.self, from: data) {
                self?.results = res.results.map { SearchItem.movie($0) }
            } else if type == "tv", let res = try? JSONDecoder().decode(TMDBResponse<TVShow>.self, from: data) {
                self?.results = res.results.map { SearchItem.tvShow($0) }
            }
            DispatchQueue.main.async { self?.collectionView.reloadData() }
        }.resume()
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cardCell = cell as? ContentCardCell {
            cardCell.animateAppearance()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        results.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContentCardCell.identifier, for: indexPath) as? ContentCardCell else {
            return UICollectionViewCell()
        }
        switch results[indexPath.row] {
        case .movie(let m): cell.configure(with: m)
        case .tvShow(let t): cell.configure(with: t)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < results.count else { return }
        let vc = DetailVC()
        switch results[indexPath.row] {
        case .movie(let m): vc.movie = m
        case .tvShow(let t): vc.tvShow = t
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}
