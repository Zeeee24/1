import Foundation

class TMDBService {
    static let shared = TMDBService()
    
    func fetchTrendingMovies(completion: @escaping ([Movie]) -> Void) {
        let url = "\(Constants.tmdbBaseURL)/trending/movie/day?api_key=\(Constants.tmdbAPIKey)"
        fetch(url: url, completion: completion)
    }
    
    func fetchTrendingTV(completion: @escaping ([TVShow]) -> Void) {
        let url = "\(Constants.tmdbBaseURL)/trending/tv/day?api_key=\(Constants.tmdbAPIKey)"
        fetch(url: url, completion: completion)
    }
    
    func fetchMovies(endpoint: String, completion: @escaping ([Movie]) -> Void) {
        let url = "\(Constants.tmdbBaseURL)/movie/\(endpoint)?api_key=\(Constants.tmdbAPIKey)"
        fetch(url: url, completion: completion)
    }
    
    func fetchTVShows(endpoint: String, completion: @escaping ([TVShow]) -> Void) {
        let url = "\(Constants.tmdbBaseURL)/tv/\(endpoint)?api_key=\(Constants.tmdbAPIKey)"
        fetch(url: url, completion: completion)
    }
    
    func fetchMovieDetail(id: Int, completion: @escaping (Movie?) -> Void) {
        let url = "\(Constants.tmdbBaseURL)/movie/\(id)?api_key=\(Constants.tmdbAPIKey)&append_to_response=release_dates"
        fetchSingle(url: url, completion: completion)
    }
    
    func fetchTVDetail(id: Int, completion: @escaping (TVShow?) -> Void) {
        let url = "\(Constants.tmdbBaseURL)/tv/\(id)?api_key=\(Constants.tmdbAPIKey)&append_to_response=content_ratings"
        fetchSingle(url: url, completion: completion)
    }
    
    func getTVShowDetails(id: Int, completion: @escaping (Result<TVShow, Error>) -> Void) {
        let url = "\(Constants.tmdbBaseURL)/tv/\(id)?api_key=\(Constants.tmdbAPIKey)&language=en-US"
        performRequest(url: url) { result in
            completion(result.flatMap { data in
                Result { try JSONDecoder().decode(TVShow.self, from: data) }
            })
        }
    }
    
    func fetchCast(id: Int, isMovie: Bool, completion: @escaping ([Cast]) -> Void) {
        let type = isMovie ? "movie" : "tv"
        let url = "\(Constants.tmdbBaseURL)/\(type)/\(id)/credits?api_key=\(Constants.tmdbAPIKey)"
        guard let url = URL(string: url) else {
            DispatchQueue.main.async { completion([]) }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let response = try? JSONDecoder().decode(CreditsResponse.self, from: data) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            DispatchQueue.main.async { completion(response.cast) }
        }.resume()
    }
    
    func fetchTopRatedMovies(completion: @escaping ([Movie]) -> Void) {
        let url = "\(Constants.tmdbBaseURL)/movie/top_rated?api_key=\(Constants.tmdbAPIKey)"
        fetch(url: url, completion: completion)
    }
    
    func fetchTVEpisodes(id: Int, season: Int, completion: @escaping ([Episode]) -> Void) {
        let url = "\(Constants.tmdbBaseURL)/tv/\(id)/season/\(season)?api_key=\(Constants.tmdbAPIKey)"
        guard let url = URL(string: url) else {
            DispatchQueue.main.async { completion([]) }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let response = try? JSONDecoder().decode(SeasonResponse.self, from: data) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            DispatchQueue.main.async { completion(response.episodes) }
        }.resume()
    }
    
    // MARK: - Advanced Search
    func advancedSearch(parameters: [String: Any], completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        let query = parameters["query"] as? String ?? ""
        let genres = parameters["genres"] as? [String] ?? []
        let year = parameters["year"] as? String ?? ""
        let rating = parameters["rating"] as? String ?? ""
        let language = parameters["language"] as? String ?? ""
        
        let genreMap: [String: String] = [
            "Action": "28", "Adventure": "12", "Animation": "16",
            "Comedy": "35", "Crime": "80", "Documentary": "99",
            "Drama": "18", "Family": "10751", "Fantasy": "14",
            "History": "36", "Horror": "27", "Music": "10402",
            "Mystery": "9648", "Romance": "10749", "Sci-Fi": "878",
            "TV Movie": "10770", "Thriller": "53", "War": "10752",
            "Western": "37"
        ]
        let genreIDs = genres.compactMap { genreMap[$0] }.joined(separator: ",")
        
        let ratingValue: String? = {
            let s = rating.trimmingCharacters(in: .whitespaces)
            if s == "Any" || s.isEmpty { return nil }
            return s.replacingOccurrences(of: "+", with: "")
        }()
        
        let isSearch = !query.isEmpty
        let movieEndpoint = isSearch ? "search/movie" : "discover/movie"
        let tvEndpoint = isSearch ? "search/tv" : "discover/tv"
        
        var movieURL = "\(Constants.tmdbBaseURL)/\(movieEndpoint)?api_key=\(Constants.tmdbAPIKey)&sort_by=popularity.desc"
        var tvURL = "\(Constants.tmdbBaseURL)/\(tvEndpoint)?api_key=\(Constants.tmdbAPIKey)&sort_by=popularity.desc"
        
        if isSearch {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            movieURL += "&query=\(encoded)"
            tvURL += "&query=\(encoded)"
        }
        
        if !genreIDs.isEmpty {
            movieURL += "&with_genres=\(genreIDs)"
            tvURL += "&with_genres=\(genreIDs)"
        }
        if !language.isEmpty && language != "Any" {
            movieURL += "&with_original_language=\(language)"
            tvURL += "&with_original_language=\(language)"
        }
        if !year.isEmpty {
            let movieYearParam = isSearch ? "year" : "primary_release_year"
            movieURL += "&\(movieYearParam)=\(year)"
            tvURL += "&first_air_date_year=\(year)"
        }
        if let rating = ratingValue, !rating.isEmpty {
            movieURL += "&vote_average.gte=\(rating)"
            tvURL += "&vote_average.gte=\(rating)"
        }
        
        let group = DispatchGroup()
        var allResults: [SearchResult] = []
        
        group.enter()
        self.fetch(url: movieURL) { (results: [Movie]) in
            allResults.append(contentsOf: results.map { SearchResult(movie: $0, tvShow: nil) })
            group.leave()
        }
        
        group.enter()
        self.fetch(url: tvURL) { (results: [TVShow]) in
            allResults.append(contentsOf: results.map { SearchResult(movie: nil, tvShow: $0) })
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(.success(allResults))
        }
    }
    
    // MARK: - Private Helpers
    private func fetch<T: Codable>(url: String, completion: @escaping ([T]) -> Void) {
        guard let url = URL(string: url) else { return completion([]) }
        
        guard !Constants.tmdbAPIKey.isEmpty else {
            print("⚠️ TMDB API key missing")
            DispatchQueue.main.async { completion([]) }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                HapticManager.shared.strong()
                DispatchQueue.main.async { completion([]) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            do {
                let tmdbResponse = try JSONDecoder().decode(TMDBResponse<T>.self, from: data)
                DispatchQueue.main.async { completion(tmdbResponse.results) }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }
    
    private func fetchSingle<T: Codable>(url: String, completion: @escaping (T?) -> Void) {
        guard let url = URL(string: url) else { return completion(nil) }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let response = try? JSONDecoder().decode(T.self, from: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(response) }
        }.resume()
    }
    
    private func performRequest(url: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        guard !Constants.tmdbAPIKey.isEmpty else {
            print("⚠️ TMDB API key missing.")
            completion(.failure(NSError(domain: "", code: -401, userInfo: [NSLocalizedDescriptionKey: "TMDB API key not configured"])))
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                completion(.success(data))
            }
        }.resume()
    }
    
    /// Fetch external IDs including IMDB ID for movies or TV shows
    func fetchExternalIDs(tmdbId: Int, isMovie: Bool, completion: @escaping (String?) -> Void) {
        let type = isMovie ? "movie" : "tv"
        let urlString = "\(Constants.tmdbBaseURL)/\(type)/\(tmdbId)/external_ids?api_key=\(Constants.tmdbAPIKey)"
        print("[TMDB] Fetching external IDs from: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("[TMDB] Error: Invalid URL")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("[TMDB] Error fetching external IDs: \(error.localizedDescription)")
                HapticManager.shared.strong()
            }

            guard let data = data else {
                print("[TMDB] Error: No data received")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Print raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[TMDB] External IDs response: \(jsonString)")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("[TMDB] Error: Could not parse JSON")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let rawImdbId = json["imdb_id"] as? String
            let imdbId = rawImdbId?.trimmingCharacters(in: .whitespacesAndNewlines)
            print("[TMDB] Raw IMDB ID: '\(rawImdbId ?? "nil")', Cleaned: '\(imdbId ?? "nil")'")

            // Also check for other ID formats
            if imdbId == nil {
                print("[TMDB] Available keys in response: \(json.keys.sorted())")
            }

            DispatchQueue.main.async { completion(imdbId) }
        }.resume()
    }
}
