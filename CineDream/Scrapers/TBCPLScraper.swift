import Foundation

class TBCPLScraper: BaseScraper {
    
    override func search(query: String, year: String?, completion: @escaping (Result<[StreamResult], Error>) -> Void) {
        // TBCPL doesn't have a direct search API, so we'll use their curated list
        // For now, we'll return empty results and let users browse their collection
        DispatchQueue.global().async {
            completion(.success([]))
        }
    }

    
    // MARK: - TBCPL Recommended Sites Integration
    
    static func getTBCPLMovieSources(tmdbId: Int) -> [StreamResult] {
        // Top TBCPL recommended movie streaming sites
        let tbcplSites = [
            ("tbcpl_1", "TBCPL #1", "https://vidsrc.to/embed/movie/\(tmdbId)"),
            ("tbcpl_2", "TBCPL #2", "https://www.2embed.cc/embed/\(tmdbId)"),
            ("tbcpl_3", "TBCPL #3", "https://autoembed.co/movie/tmdb/\(tmdbId)"),
            ("tbcpl_4", "TBCPL #4", "https://multiembed.mov/?video_id=\(tmdbId)&tmdb=1"),
            ("tbcpl_5", "TBCPL #5", "https://embed.su/embed/movie/\(tmdbId)")
        ]
        
        var sources: [StreamResult] = []
        for (id, name, urlString) in tbcplSites {
            if let url = URL(string: urlString) {
                sources.append(StreamResult(sourceId: id, sourceName: name, quality: "HD", url: url, isEmbed: true, headers: nil))
            }
        }
        
        return sources
    }
    
    static func getTBCPLTVSources(tmdbId: Int, season: Int, episode: Int) -> [StreamResult] {
        // Top TBCPL recommended TV streaming sites
        let tbcplSites = [
            ("tbcpl_tv1", "TBCPL TV #1", "https://vidsrc.to/embed/tv/\(tmdbId)/\(season)/\(episode)"),
            ("tbcpl_tv2", "TBCPL TV #2", "https://www.2embed.cc/embedtv/\(tmdbId)&s=\(season)&e=\(episode)"),
            ("tbcpl_tv3", "TBCPL TV #3", "https://autoembed.co/tv/tmdb/\(tmdbId)-\(season)-\(episode)"),
            ("tbcpl_tv4", "TBCPL TV #4", "https://multiembed.mov/?video_id=\(tmdbId)&tmdb=1&s=\(season)&e=\(episode)"),
            ("tbcpl_tv5", "TBCPL TV #5", "https://embed.su/embed/tv/\(tmdbId)/\(season)/\(episode)")
        ]
        
        var sources: [StreamResult] = []
        for (id, name, urlString) in tbcplSites {
            if let url = URL(string: urlString) {
                sources.append(StreamResult(sourceId: id, sourceName: name, quality: "HD", url: url, isEmbed: true, headers: nil))
            }
        }
        
        return sources
    }
    
    // MARK: - Anime Integration
    
    static func getTBCPLAnimeSources(animeId: Int, episode: Int = 1) -> [StreamResult] {
        // TBCPL recommended anime streaming sites
        let animeSites = [
            ("tbcpl_anime1", "TBCPL Anime #1", "https://vidsrc.to/embed/tv/\(animeId)/1/\(episode)"),
            ("tbcpl_anime2", "TBCPL Anime #2", "https://www.2embed.cc/embedtv/\(animeId)&s=1&e=\(episode)"),
            ("tbcpl_anime3", "TBCPL Anime #3", "https://autoembed.co/tv/tmdb/\(animeId)-1-\(episode)"),
            ("tbcpl_anime4", "TBCPL Anime #4", "https://multiembed.mov/?video_id=\(animeId)&tmdb=1&s=1&e=\(episode)")
        ]
        
        var sources: [StreamResult] = []
        for (id, name, urlString) in animeSites {
            if let url = URL(string: urlString) {
                sources.append(StreamResult(sourceId: id, sourceName: name, quality: "HD", url: url, isEmbed: true, headers: nil))
            }
        }
        
        return sources
    }
    
    // MARK: - Manga Integration (Reading)
    
    static func getTBCPLMangaSources(mangaId: Int, chapter: Int = 1) -> [StreamResult] {
        // TBCPL recommended manga reading sites
        let mangaSites = [
            ("tbcpl_manga1", "TBCPL Manga #1", "https://mangadex.org/chapter/\(mangaId)/\(chapter)"),
            ("tbcpl_manga2", "TBCPL Manga #2", "https://mangasee123.com/read-online/\(mangaId)/chapter-\(chapter).html"),
            ("tbcpl_manga3", "TBCPL Manga #3", "https://mangakakalot.com/chapter/\(mangaId)/\(chapter)")
        ]
        
        var sources: [StreamResult] = []
        for (id, name, urlString) in mangaSites {
            if let url = URL(string: urlString) {
                sources.append(StreamResult(sourceId: id, sourceName: name, quality: "HD", url: url, isEmbed: true, headers: nil))
            }
        }
        
        return sources
    }
}
