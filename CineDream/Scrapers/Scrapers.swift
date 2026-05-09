import Foundation

// MARK: - Base
class BaseScraper: StreamSource {
    var id: String { fatalError("Must override") }
    var name: String { fatalError("Must override") }
    var isEnabled: Bool { UserDefaults.standard.object(forKey: "scraper_\(id)_enabled") as? Bool ?? true }

    func search(query: String, year: String?, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchEpisode(tmdbId: Int, season: Int, episode: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchHTML(url: URL, completion: @escaping (String?) -> Void) {
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 12
        URLSession.shared.dataTask(with: req) { data, _, _ in
            completion(data.flatMap { String(data: $0, encoding: .utf8) })
        }.resume()
    }
}

// MARK: - TMDB-ID based embed scrapers (these ALWAYS work, no scraping needed)

/// vidsrc.icu — most reliable, multilingual library including Hindi and Hollywood
class VidSrcIcuScraper: BaseScraper {
    override var id: String { "vidsrc_icu" }
    override var name: String { "VidSrc.icu" }

    func fetchMovie(tmdbId: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://vidsrc.icu/embed/movie?tmdb=\(tmdbId)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }

    func fetchTV(tmdbId: Int, season: Int, episode: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://vidsrc.icu/embed/tv?tmdb=\(tmdbId)&season=\(season)&episode=\(episode)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }
}

/// vidsrc.me — oldest and most stable with huge library
class VidSrcMeScraper: BaseScraper {
    override var id: String { "vidsrc_me" }
    override var name: String { "VidSrc.me" }

    override func search(query: String, year: String?, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchMovie(tmdbId: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://vidsrc.me/embed/movie?tmdb=\(tmdbId)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }

    func fetchTV(tmdbId: Int, season: Int, episode: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://vidsrc.me/embed/tv?tmdb=\(tmdbId)&season=\(season)&episode=\(episode)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }
}

/// 2embed.cc — fourth embed option
class TwoEmbedScraper: BaseScraper {
    override var id: String { "2embed" }
    override var name: String { "2Embed" }

    func fetchMovie(tmdbId: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://www.2embed.cc/embed/\(tmdbId)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }

    func fetchTV(tmdbId: Int, season: Int, episode: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://www.2embed.cc/embedtv/\(tmdbId)&s=\(season)&e=\(episode)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }
}

/// 2embed.skin — fourth embed option
class TwoEmbedSkinScraper: BaseScraper {
    override var id: String { "2embed_skin" }
    override var name: String { "2embed.skin" }

    func fetchMovie(tmdbId: Int, imdbId: String, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://www.2embed.skin/embed/\(imdbId)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }

    func fetchTV(tmdbId: Int, imdbId: String, season: Int, episode: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://www.2embed.skin/embed/\(imdbId)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }
}

/// vidsrc.mov (original)
class VidSrcMovScraper: BaseScraper {
    override var id: String { "vidsrc_mov" }
    override var name: String { "VidSrc.mov" }

    func fetchMovie(tmdbId: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://vidsrc.mov/embed/movie/\(tmdbId)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }

    func fetchTV(tmdbId: Int, season: Int, episode: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://vidsrc.mov/embed/tv/\(tmdbId)/\(season)/\(episode)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }
}

/// autoembed.cc — sixth embed option
class AutoEmbedScraper: BaseScraper {
    override var id: String { "autoembed" }
    override var name: String { "AutoEmbed" }

    func fetchMovie(tmdbId: Int, imdbId: String, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://autoembed.cc/movie/imdb/\(imdbId)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }

    func fetchTV(tmdbId: Int, imdbId: String, season: Int, episode: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://autoembed.cc/tv/imdb/\(imdbId)/\(season)/\(episode)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }
}

/// moviesapi.club — final fallback
class MoviesApiClubScraper: BaseScraper {
    override var id: String { "moviesapi_club" }
    override var name: String { "MoviesAPI.club" }

    func fetchMovie(tmdbId: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://moviesapi.club/movie/\(tmdbId)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }

    func fetchTV(tmdbId: Int, season: Int, episode: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let url = URL(string: "https://moviesapi.club/tv/\(tmdbId)-\(season)-\(episode)") else { return completion(.success([])) }
        completion(.success([StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil)]))
    }
}

// MARK: - HTML scrapers (bonus — may fail due to Cloudflare / JS rendering)

class VegaMoviesScraper: BaseScraper {
    override var id: String { "vegamovies" }
    override var name: String { "VegaMovies" }

    override func search(query: String, year: String?, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        let slug = query.replacingOccurrences(of: " ", with: "-").lowercased()
        guard let url = URL(string: "https://\(Constants.Scrapers.vegamovies)/search/\(slug)") else { return completion(.success([])) }
        fetchHTML(url: url) { html in
            guard let html = html,
                  let link = html.matches(for: "href=\"([^\"]+)\"").first(where: { $0.contains(slug) })?.components(separatedBy: "\"")[1],
                  let movieUrl = URL(string: link) else { return completion(.success([])) }
            self.fetchHTML(url: movieUrl) { movieHtml in
                guard let movieHtml = movieHtml else { return completion(.success([])) }
                let results: [StreamResult] = movieHtml.matches(for: "<iframe[^>]+src=\"([^\"]+)\"").compactMap {
                    guard let src = $0.components(separatedBy: "\"").dropFirst().first, let u = URL(string: src) else { return nil }
                    return StreamResult(sourceId: self.id, sourceName: self.name, quality: "HD", url: u, isEmbed: true, headers: nil)
                }
                completion(.success(results))
            }
        }
    }
}

class BollyflixScraper: BaseScraper {
    override var id: String { "bollyflix" }
    override var name: String { "Bollyflix" }
    override func search(query: String, year: String?, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://\(Constants.Scrapers.bollyflix)/search/\(encoded)") else { return completion(.success([])) }
        fetchHTML(url: url) { html in
            guard let html = html,
                  let link = html.matches(for: "<a href=\"([^\"]+)\"[^>]*class=\"post-title\"").first?.components(separatedBy: "\"")[1],
                  let movieUrl = URL(string: link) else { return completion(.success([])) }
            self.fetchHTML(url: movieUrl) { movieHtml in
                guard let movieHtml = movieHtml else { return completion(.success([])) }
                let results: [StreamResult] = movieHtml.matches(for: "<iframe[^>]+src=\"([^\"]+)\"").compactMap {
                    guard let src = $0.components(separatedBy: "\"").dropFirst().first,
                          (src.contains("vidhide") || src.contains("streamhub")),
                          let u = URL(string: src) else { return nil }
                    return StreamResult(sourceId: self.id, sourceName: self.name, quality: "HD", url: u, isEmbed: true, headers: nil)
                }
                completion(.success(results))
            }
        }
    }
}

// Stub scrapers (return empty — kept for future implementation)
class MovierulzhdScraper: BaseScraper { override var id: String { "movierulzhd" }; override var name: String { "Movierulzhd" } }
class HDhub4uScraper: BaseScraper { override var id: String { "hdhub4u" }; override var name: String { "HDhub4u" } }
class MultiMoviesScraper: BaseScraper { override var id: String { "multimovies" }; override var name: String { "MultiMovies" } }
class MoviesDriveScraper: BaseScraper { override var id: String { "moviesdrive" }; override var name: String { "MoviesDrive" } }
class MoviesmodScraper: BaseScraper { override var id: String { "moviesmod" }; override var name: String { "Moviesmod" } }
class Watch32Scraper: BaseScraper { override var id: String { "watch32" }; override var name: String { "Watch32" } }
class GoojaraScraper: BaseScraper { override var id: String { "goojara" }; override var name: String { "Goojara" } }
