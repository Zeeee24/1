import UIKit

class SearchVC: BaseViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    private var results: [SearchItem] = []
    private var searchTask: DispatchWorkItem?

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.searchBarStyle = .minimal
        sb.placeholder = "Search or use filters below..."
        sb.barStyle = .black
        sb.tintColor = UIColor(hex: "#E50914")
        sb.searchTextField.textColor = .white
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

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
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 20, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(ContentCardCell.self, forCellWithReuseIdentifier: ContentCardCell.identifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Search for movies & TV shows"
        l.textColor = .gray
        l.font = .systemFont(ofSize: 16)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .medium)
        aiv.color = UIColor(hex: "#E50914")
        aiv.hidesWhenStopped = true
        aiv.translatesAutoresizingMaskIntoConstraints = false
        return aiv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search"
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        collectionView.dataSource = self
        collectionView.delegate = self

        view.addSubview(searchBar)
        view.addSubview(emptyLabel)
        view.addSubview(loadingIndicator)

        typeSegment.selectedSegmentIndex = 0
        typeSegment.addTarget(self, action: #selector(filterChanged), for: .valueChanged)

        setupFilterButton(genreBtn, title: "Genre", action: #selector(selectGenre))
        setupFilterButton(langBtn, title: "Language", action: #selector(selectLanguage))
        setupFilterButton(yearBtn, title: "Year", action: #selector(selectYear))

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
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            filterScrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
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
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: filterScrollView.bottomAnchor, constant: 40)
        ])

        runSearch()
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

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.runSearch()
        }
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        runSearch()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        runSearch()
    }

    @objc private func filterChanged() {
        runSearch()
    }

    @objc private func selectGenre() {
        let alert = UIAlertController(title: "Select Genre", message: nil, preferredStyle: .actionSheet)
        let genres = [
            ("All", ""), ("Action", "28"), ("Adventure", "12"), ("Animation", "16"),
            ("Comedy", "35"), ("Crime", "80"), ("Documentary", "99"), ("Drama", "18"),
            ("Family", "10751"), ("Fantasy", "14"), ("History", "36"), ("Horror", "27"),
            ("Music", "10402"), ("Mystery", "9648"), ("Romance", "10749"), ("Sci-Fi", "878"),
            ("TV Movie", "10770"), ("Thriller", "53"), ("War", "10752"), ("Western", "37")
        ]
        for g in genres {
            alert.addAction(UIAlertAction(title: g.0, style: .default) { _ in
                self.genreBtn.setTitle(g.0 == "All" ? "Genre" : g.0, for: .normal)
                self.selectedGenreId = g.1
                self.runSearch()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func selectLanguage() {
        let alert = UIAlertController(title: "Select Language", message: nil, preferredStyle: .actionSheet)
        let langs = [("All", ""), ("English", "en"), ("Hindi", "hi"), ("Spanish", "es"), ("Korean", "ko"), ("Japanese", "ja")]
        for l in langs {
            alert.addAction(UIAlertAction(title: l.0, style: .default) { _ in
                self.langBtn.setTitle(l.0 == "All" ? "Language" : l.0, for: .normal)
                self.selectedLang = l.1
                self.runSearch()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func selectYear() {
        let alert = UIAlertController(title: "Select Year", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "All Years", style: .default) { _ in
            self.yearBtn.setTitle("Year", for: .normal)
            self.selectedYear = ""
            self.runSearch()
        })
        let currentYear = Calendar.current.component(.year, from: Date())
        for y in (1990...currentYear).reversed() {
            alert.addAction(UIAlertAction(title: "\(y)", style: .default) { _ in
                self.yearBtn.setTitle("\(y)", for: .normal)
                self.selectedYear = "\(y)"
                self.runSearch()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func runSearch() {
        let query = searchBar.text ?? ""
        let type = typeSegment.selectedSegmentIndex == 0 ? "movie" : "tv"

        var urlStr = ""
        if query.isEmpty {
            urlStr = "\(Constants.tmdbBaseURL)/discover/\(type)?api_key=\(Constants.tmdbAPIKey)&sort_by=popularity.desc"
            if !selectedGenreId.isEmpty { urlStr += "&with_genres=\(selectedGenreId)" }
            if !selectedLang.isEmpty { urlStr += "&with_original_language=\(selectedLang)" }
            if !selectedYear.isEmpty {
                urlStr += type == "movie" ? "&primary_release_year=\(selectedYear)" : "&first_air_date_year=\(selectedYear)"
            }
        } else {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            urlStr = "\(Constants.tmdbBaseURL)/search/\(type)?api_key=\(Constants.tmdbAPIKey)&query=\(encoded)"
            if !selectedYear.isEmpty {
                urlStr += type == "movie" ? "&year=\(selectedYear)" : "&first_air_date_year=\(selectedYear)"
            }
        }

        guard let url = URL(string: urlStr) else { return }
        
        DispatchQueue.main.async {
            self.loadingIndicator.startAnimating()
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data else { 
                DispatchQueue.main.async { self?.loadingIndicator.stopAnimating() }
                return 
            }
            var temp: [SearchItem] = []
            if type == "movie", let res = try? JSONDecoder().decode(TMDBResponse<Movie>.self, from: data) {
                temp = res.results.map { SearchItem.movie($0) }
            } else if type == "tv", let res = try? JSONDecoder().decode(TMDBResponse<TVShow>.self, from: data) {
                temp = res.results.map { SearchItem.tvShow($0) }
            }

            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.results = temp
                UIView.transition(with: self?.collectionView ?? UIView(), duration: 0.3, options: .transitionCrossDissolve, animations: {
                    self?.collectionView.reloadData()
                }, completion: nil)
                self?.emptyLabel.isHidden = !temp.isEmpty
                self?.emptyLabel.text = temp.isEmpty ? "No results found" : ""
            }
        }.resume()
    }

    // MARK: - Collection
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
