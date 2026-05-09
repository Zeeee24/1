import UIKit

class AdvancedSearchVC: BaseViewController {
    
    // MARK: - UI Components
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Search movies, TV shows, actors..."
        textField.backgroundColor = UIColor(white: 0.2, alpha: 1)
        textField.textColor = .white
        textField.layer.cornerRadius = 25
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 40))
        textField.leftViewMode = .always
        textField.font = .systemFont(ofSize: 16)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Search", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#E50914")
        button.layer.cornerRadius = 25
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addNetflixTouchEffect()
        return button
    }()
    
    private let filterScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let filterStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let resultsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 110, height: 180)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(ContentCardCell.self, forCellWithReuseIdentifier: ContentCardCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isHidden = true
        return collectionView
    }()
    
    private let loadingView = NetflixLoadingView()
    private let emptyStateView = createEmptyStateView()
    
    // MARK: - Data
    private var searchResults: [SearchResult] = []
    private var selectedGenres: Set<String> = []
    private var selectedYear: String?
    private var selectedRating: String?
    private var selectedLanguage: String?
    
    // MARK: - Filter Options
    private let genres = ["Action", "Comedy", "Drama", "Horror", "Romance", "Sci-Fi", "Thriller", "Animation", "Documentary", "Crime", "Adventure", "Fantasy"]
    private let years = ["2024", "2023", "2022", "2021", "2020", "2019", "2018", "2017", "2016", "2015"]
    private let ratings = ["9+", "8+", "7+", "6+", "5+", "Any"]
    private let languages = ["English", "Spanish", "French", "German", "Italian", "Japanese", "Korean", "Chinese", "Hindi", "Any"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Advanced Search"
        setupUI()
        setupFilters()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Search bar
        view.addSubview(searchTextField)
        view.addSubview(searchButton)
        
        // Filters
        view.addSubview(filterScrollView)
        filterScrollView.addSubview(filterStackView)
        
        // Results
        view.addSubview(resultsCollectionView)
        view.addSubview(loadingView)
        view.addSubview(emptyStateView)
        
        // Constraints
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -12),
            searchTextField.heightAnchor.constraint(equalToConstant: 50),
            
            searchButton.topAnchor.constraint(equalTo: searchTextField.topAnchor),
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchButton.widthAnchor.constraint(equalToConstant: 80),
            searchButton.heightAnchor.constraint(equalToConstant: 50),
            
            filterScrollView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20),
            filterScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterScrollView.heightAnchor.constraint(equalToConstant: 60),
            
            filterStackView.topAnchor.constraint(equalTo: filterScrollView.topAnchor),
            filterStackView.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor, constant: 16),
            filterStackView.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor, constant: -16),
            filterStackView.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor),
            filterStackView.heightAnchor.constraint(equalToConstant: 60),
            
            resultsCollectionView.topAnchor.constraint(equalTo: filterScrollView.bottomAnchor, constant: 20),
            resultsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        searchButton.addTarget(self, action: #selector(performSearch), for: .touchUpInside)
        searchTextField.delegate = self
        resultsCollectionView.dataSource = self
        resultsCollectionView.delegate = self
        
        emptyStateView.isHidden = false
    }
    
    private func setupFilters() {
        // Genre filters
        let genreLabel = createFilterLabel("Genres")
        filterStackView.addArrangedSubview(genreLabel)
        
        let genreScrollView = createFilterScrollView()
        let genreStack = createFilterStack()
        
        for genre in genres {
            let button = createFilterButton(title: genre, type: .genre)
            genreStack.addArrangedSubview(button)
        }
        
        genreScrollView.addSubview(genreStack)
        filterStackView.addArrangedSubview(genreScrollView)
        
        // Year filters
        let yearLabel = createFilterLabel("Year")
        filterStackView.addArrangedSubview(yearLabel)
        
        let yearScrollView = createFilterScrollView()
        let yearStack = createFilterStack()
        
        for year in years {
            let button = createFilterButton(title: year, type: .year)
            yearStack.addArrangedSubview(button)
        }
        
        yearScrollView.addSubview(yearStack)
        filterStackView.addArrangedSubview(yearScrollView)
        
        // Rating filters
        let ratingLabel = createFilterLabel("Rating")
        filterStackView.addArrangedSubview(ratingLabel)
        
        let ratingScrollView = createFilterScrollView()
        let ratingStack = createFilterStack()
        
        for rating in ratings {
            let button = createFilterButton(title: rating, type: .rating)
            ratingStack.addArrangedSubview(button)
        }
        
        ratingScrollView.addSubview(ratingStack)
        filterStackView.addArrangedSubview(ratingScrollView)
        
        // Language filters
        let languageLabel = createFilterLabel("Language")
        filterStackView.addArrangedSubview(languageLabel)
        
        let languageScrollView = createFilterScrollView()
        let languageStack = createFilterStack()
        
        for language in languages {
            let button = createFilterButton(title: language, type: .language)
            languageStack.addArrangedSubview(button)
        }
        
        languageScrollView.addSubview(languageStack)
        filterStackView.addArrangedSubview(languageScrollView)
    }
    
    private func createFilterLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(hex: "#E50914")
        label.font = .boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        return label
    }
    
    private func createFilterScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }
    
    private func createFilterStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
    
    private func createFilterButton(title: String, type: FilterType) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 0.3, alpha: 1)
        button.layer.cornerRadius = 15
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        button.addNetflixTouchEffect()
        
        button.tag = type.rawValue
        button.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func filterTapped(_ sender: UIButton) {
        guard let type = FilterType(rawValue: sender.tag) else { return }
        let title = sender.title(for: .normal) ?? ""
        
        switch type {
        case .genre:
            if selectedGenres.contains(title) {
                selectedGenres.remove(title)
                sender.backgroundColor = UIColor(white: 0.3, alpha: 1)
            } else {
                selectedGenres.insert(title)
                sender.backgroundColor = UIColor(hex: "#E50914")
            }
        case .year:
            if selectedYear == title {
                selectedYear = nil
                sender.backgroundColor = UIColor(white: 0.3, alpha: 1)
            } else {
                selectedYear = title
                // Reset other year buttons
                resetFilterButtons(in: sender.superview as? UIStackView, except: sender)
                sender.backgroundColor = UIColor(hex: "#E50914")
            }
        case .rating:
            if selectedRating == title {
                selectedRating = nil
                sender.backgroundColor = UIColor(white: 0.3, alpha: 1)
            } else {
                selectedRating = title
                // Reset other rating buttons
                resetFilterButtons(in: sender.superview as? UIStackView, except: sender)
                sender.backgroundColor = UIColor(hex: "#E50914")
            }
        case .language:
            if selectedLanguage == title {
                selectedLanguage = nil
                sender.backgroundColor = UIColor(white: 0.3, alpha: 1)
            } else {
                selectedLanguage = title
                // Reset other language buttons
                resetFilterButtons(in: sender.superview as? UIStackView, except: sender)
                sender.backgroundColor = UIColor(hex: "#E50914")
            }
        }
    }
    
    private func resetFilterButtons(in stackView: UIStackView?, except selectedButton: UIButton) {
        guard let stackView = stackView else { return }
        for case let button as UIButton in stackView.arrangedSubviews {
            if button != selectedButton {
                button.backgroundColor = UIColor(white: 0.3, alpha: 1)
            }
        }
    }
    
    @objc private func performSearch() {
        guard let query = searchTextField.text, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Error", message: "Please enter a search term")
            return
        }
        
        showLoading()
        emptyStateView.isHidden = true
        resultsCollectionView.isHidden = true
        
        // Build search parameters
        var parameters: [String: Any] = ["query": query]
        
        if !selectedGenres.isEmpty {
            parameters["genres"] = Array(selectedGenres)
        }
        if let year = selectedYear, year != "Any" {
            parameters["year"] = year
        }
        if let rating = selectedRating, rating != "Any" {
            parameters["rating"] = rating
        }
        if let language = selectedLanguage, language != "Any" {
            parameters["language"] = language
        }
        
        // Perform search with filters
        TMDBService.shared.advancedSearch(parameters: parameters) { [weak self] result in
            DispatchQueue.main.async {
                self?.hideLoading()
                
                switch result {
                case .success(let results):
                    self?.searchResults = results
                    if results.isEmpty {
                        self?.showEmptyState()
                    } else {
                        self?.showResults()
                    }
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }
    
    private func showLoading() {
        loadingView.startAnimating()
        loadingView.isHidden = false
    }
    
    private func hideLoading() {
        loadingView.stopAnimating()
        loadingView.isHidden = true
    }
    
    private func showResults() {
        resultsCollectionView.isHidden = false
        emptyStateView.isHidden = true
        resultsCollectionView.reloadData()
    }
    
    private func showEmptyState() {
        resultsCollectionView.isHidden = true
        emptyStateView.isHidden = false
    }
    
    private func showError(_ error: Error) {
        showAlert(title: "Search Error", message: error.localizedDescription)
    }
    
    private static func createEmptyStateView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        imageView.tintColor = .lightGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "No results found\nTry different keywords or filters"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(imageView)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
}

// MARK: - Filter Types
enum FilterType: Int {
    case genre = 0
    case year = 1
    case rating = 2
    case language = 3
}

// MARK: - UITextField Delegate
extension AdvancedSearchVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        performSearch()
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Collection View Data Source
extension AdvancedSearchVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContentCardCell.identifier, for: indexPath) as! ContentCardCell
        
        let result = searchResults[indexPath.row]
        
        if let movie = result.movie {
            cell.configure(with: movie)
        } else if let tvShow = result.tvShow {
            cell.configure(with: tvShow)
        }
        
        return cell
    }
}

extension AdvancedSearchVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cardCell = cell as? ContentCardCell {
            cardCell.animateAppearance()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        
        if let movie = result.movie {
            let detailVC = DetailVC()
            detailVC.movie = movie
            navigationController?.pushViewController(detailVC, animated: true)
        } else if let tvShow = result.tvShow {
            let detailVC = DetailVC()
            detailVC.tvShow = tvShow
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}


