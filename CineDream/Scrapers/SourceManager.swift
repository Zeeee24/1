import Foundation

protocol StreamSource {
    var id: String { get }
    var name: String { get }
    var isEnabled: Bool { get }
    func search(query: String, year: String?, completion: @escaping (Result<[StreamResult], Error>) -> Void)
    func fetchEpisode(tmdbId: Int, season: Int, episode: Int, completion: @escaping (Result<[StreamResult], Error>) -> Void)
}

class SourceManager {
    static let shared = SourceManager()

    // TMDB-ID embed providers — in order of reliability
    let embedProviders: [AnyObject] = [
        VidSrcIcuScraper(),      // 1. Most reliable, multilingual
        VidSrcMeScraper(),       // 2. Oldest and most stable
        TwoEmbedScraper(),       // 3. 2embed.cc
        TwoEmbedSkinScraper(),   // 4. 2embed.skin (needs IMDB)
        VidSrcMovScraper(),      // 6. VidSrc.mov
        AutoEmbedScraper(),      // 7. AutoEmbed (needs IMDB)
        MoviesApiClubScraper()   // 8. Final fallback
    ]

    // HTML scrapers — try these concurrently, may fail due to Cloudflare
    let htmlScrapers: [BaseScraper] = [
        VegaMoviesScraper(),
        BollyflixScraper(),
        MovierulzhdScraper(),
        HDhub4uScraper(),
        MultiMoviesScraper(),
        MoviesDriveScraper(),
        MoviesmodScraper(),
        Watch32Scraper(),
        GoojaraScraper()
    ]

    private init() {}

    /// Builds all embed source URLs asynchronously (some need IMDB ID lookup).
    /// Prioritizes working sources in order of reliability.
    func buildAllEmbedSources(tmdbId: Int, isTVShow: Bool, season: Int = 1, episode: Int = 1, imdbId: String? = nil, completion: @escaping ([StreamResult]) -> Void) {
        guard tmdbId > 0 else {
            completion([])
            return
        }
        
        var sources: [StreamResult] = []
        
        // Build sources in order: VidSrc.icu, VidSrc.me, MultiEmbed, FilmU, 2Embed, 2embed.skin, VidSrc.mov, AutoEmbed, MoviesAPI.club
        if isTVShow {
            // 1. VidSrc.icu
            if let url = URL(string: "https://vidsrc.icu/embed/tv?tmdb=\(tmdbId)&season=\(season)&episode=\(episode)") {
                sources.append(StreamResult(sourceId: "vidsrc_icu", sourceName: "VidSrc.icu", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 2. VidSrc.me
            if let url = URL(string: "https://vidsrc.me/embed/tv?tmdb=\(tmdbId)&season=\(season)&episode=\(episode)") {
                sources.append(StreamResult(sourceId: "vidsrc_me", sourceName: "VidSrc.me", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }

            // 4. MultiEmbed (IMDB-based)
            if let imdb = imdbId, !imdb.isEmpty {
                if let url = URL(string: "https://multiembed.mov/?video_id=\(imdb)&s=\(season)&e=\(episode)") {
                    sources.append(StreamResult(sourceId: "multiembed", sourceName: "MultiEmbed", quality: "Auto", url: url, isEmbed: true, headers: nil))
                }
            }
            // 4. FilmU (IMDB-based)
            if let imdb = imdbId, !imdb.isEmpty {
                if let url = URL(string: "https://embed.filmu.in/tv/\(imdb)/\(season)/\(episode)") {
                    sources.append(StreamResult(sourceId: "filmu", sourceName: "FilmU", quality: "Auto", url: url, isEmbed: true, headers: nil))
                }
            }
            // 5. 2embed.cc
            if let url = URL(string: "https://www.2embed.cc/embedtv/\(tmdbId)&s=\(season)&e=\(episode)") {
                sources.append(StreamResult(sourceId: "2embed", sourceName: "2Embed", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 6. 2embed.skin (IMDB-based)
            if let imdb = imdbId, !imdb.isEmpty {
                if let url = URL(string: "https://www.2embed.skin/embed/\(imdb)") {
                    sources.append(StreamResult(sourceId: "2embed_skin", sourceName: "2embed.skin", quality: "Auto", url: url, isEmbed: true, headers: nil))
                }
            }
            // 7. VidSrc.mov
            if let url = URL(string: "https://vidsrc.mov/embed/tv/\(tmdbId)/\(season)/\(episode)") {
                sources.append(StreamResult(sourceId: "vidsrc_mov", sourceName: "VidSrc.mov", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 8. AutoEmbed (IMDB-based)
            if let imdb = imdbId, !imdb.isEmpty {
                if let url = URL(string: "https://autoembed.cc/tv/imdb/\(imdb)/\(season)/\(episode)") {
                    sources.append(StreamResult(sourceId: "autoembed", sourceName: "AutoEmbed", quality: "Auto", url: url, isEmbed: true, headers: nil))
                }
            }
            // 9. MoviesAPI.club
            if let url = URL(string: "https://moviesapi.club/tv/\(tmdbId)-\(season)-\(episode)") {
                sources.append(StreamResult(sourceId: "moviesapi_club", sourceName: "MoviesAPI.club", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
        } else {
            // 1. VidSrc.icu
            if let url = URL(string: "https://vidsrc.icu/embed/movie?tmdb=\(tmdbId)") {
                sources.append(StreamResult(sourceId: "vidsrc_icu", sourceName: "VidSrc.icu", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 2. VidSrc.me
            if let url = URL(string: "https://vidsrc.me/embed/movie?tmdb=\(tmdbId)") {
                sources.append(StreamResult(sourceId: "vidsrc_me", sourceName: "VidSrc.me", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }

            // 4. MultiEmbed (IMDB-based)
            if let imdb = imdbId, !imdb.isEmpty {
                if let url = URL(string: "https://multiembed.mov/?video_id=\(imdb)") {
                    sources.append(StreamResult(sourceId: "multiembed", sourceName: "MultiEmbed", quality: "Auto", url: url, isEmbed: true, headers: nil))
                }
            }
            // 4. FilmU (IMDB-based)
            if let imdb = imdbId, !imdb.isEmpty {
                if let url = URL(string: "https://embed.filmu.in/movie/\(imdb)") {
                    sources.append(StreamResult(sourceId: "filmu", sourceName: "FilmU", quality: "Auto", url: url, isEmbed: true, headers: nil))
                }
            }
            // 5. 2embed.cc
            if let url = URL(string: "https://www.2embed.cc/embed/\(tmdbId)") {
                sources.append(StreamResult(sourceId: "2embed", sourceName: "2Embed", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 6. 2embed.skin (IMDB-based)
            if let imdb = imdbId, !imdb.isEmpty {
                if let url = URL(string: "https://www.2embed.skin/embed/\(imdb)") {
                    sources.append(StreamResult(sourceId: "2embed_skin", sourceName: "2embed.skin", quality: "Auto", url: url, isEmbed: true, headers: nil))
                }
            }
            // 7. VidSrc.mov
            if let url = URL(string: "https://vidsrc.mov/embed/movie/\(tmdbId)") {
                sources.append(StreamResult(sourceId: "vidsrc_mov", sourceName: "VidSrc.mov", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 8. AutoEmbed (IMDB-based)
            if let imdb = imdbId, !imdb.isEmpty {
                if let url = URL(string: "https://autoembed.cc/movie/imdb/\(imdb)") {
                    sources.append(StreamResult(sourceId: "autoembed", sourceName: "AutoEmbed", quality: "Auto", url: url, isEmbed: true, headers: nil))
                }
            }
            // 9. MoviesAPI.club
            if let url = URL(string: "https://moviesapi.club/movie/\(tmdbId)") {
                sources.append(StreamResult(sourceId: "moviesapi_club", sourceName: "MoviesAPI.club", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
        }
        
        completion(sources)
    }
    
    /// Legacy sync version - builds sources without IMDB-requiring servers
    func buildAllEmbedSourcesSync(tmdbId: Int, isTVShow: Bool, season: Int = 1, episode: Int = 1) -> [StreamResult] {
        guard tmdbId > 0 else { return [] }
        var sources: [StreamResult] = []
        
        if isTVShow {
            // 1. VidSrc.icu
            if let url = URL(string: "https://vidsrc.icu/embed/tv?tmdb=\(tmdbId)&season=\(season)&episode=\(episode)") {
                sources.append(StreamResult(sourceId: "vidsrc_icu", sourceName: "VidSrc.icu", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 2. VidSrc.me
            if let url = URL(string: "https://vidsrc.me/embed/tv?tmdb=\(tmdbId)&season=\(season)&episode=\(episode)") {
                sources.append(StreamResult(sourceId: "vidsrc_me", sourceName: "VidSrc.me", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 3. VidBox
            if let url = URL(string: "https://vidbox.dev/tv/\(tmdbId)/\(season)/\(episode)") {
                sources.append(StreamResult(sourceId: "vidbox", sourceName: "VidBox", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 4. 2embed.cc
            if let url = URL(string: "https://www.2embed.cc/embedtv/\(tmdbId)&s=\(season)&e=\(episode)") {
                sources.append(StreamResult(sourceId: "2embed", sourceName: "2Embed", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 5. VidSrc.mov
            if let url = URL(string: "https://vidsrc.mov/embed/tv/\(tmdbId)/\(season)/\(episode)") {
                sources.append(StreamResult(sourceId: "vidsrc_mov", sourceName: "VidSrc.mov", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 7. MoviesAPI.club
            if let url = URL(string: "https://moviesapi.club/tv/\(tmdbId)-\(season)-\(episode)") {
                sources.append(StreamResult(sourceId: "moviesapi_club", sourceName: "MoviesAPI.club", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
        } else {
            // 1. VidSrc.icu
            if let url = URL(string: "https://vidsrc.icu/embed/movie?tmdb=\(tmdbId)") {
                sources.append(StreamResult(sourceId: "vidsrc_icu", sourceName: "VidSrc.icu", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 2. VidSrc.me
            if let url = URL(string: "https://vidsrc.me/embed/movie?tmdb=\(tmdbId)") {
                sources.append(StreamResult(sourceId: "vidsrc_me", sourceName: "VidSrc.me", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 3. VidBox
            if let url = URL(string: "https://vidbox.dev/movie/\(tmdbId)") {
                sources.append(StreamResult(sourceId: "vidbox", sourceName: "VidBox", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 4. 2embed.cc
            if let url = URL(string: "https://www.2embed.cc/embed/\(tmdbId)") {
                sources.append(StreamResult(sourceId: "2embed", sourceName: "2Embed", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 5. VidSrc.mov
            if let url = URL(string: "https://vidsrc.mov/embed/movie/\(tmdbId)") {
                sources.append(StreamResult(sourceId: "vidsrc_mov", sourceName: "VidSrc.mov", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
            // 7. MoviesAPI.club
            if let url = URL(string: "https://moviesapi.club/movie/\(tmdbId)") {
                sources.append(StreamResult(sourceId: "moviesapi_club", sourceName: "MoviesAPI.club", quality: "Auto", url: url, isEmbed: true, headers: nil))
            }
        }
        return sources
    }
    
    /// Builds anime sources using TBCPL curated anime sites
    func buildAnimeSources(animeId: Int, episode: Int = 1) -> [StreamResult] {
        guard animeId > 0 else { return [] }
        return TBCPLScraper.getTBCPLAnimeSources(animeId: animeId, episode: episode)
    }
    
    /// Builds manga sources using TBCPL curated manga sites
    func buildMangaSources(mangaId: Int, chapter: Int = 1) -> [StreamResult] {
        guard mangaId > 0 else { return [] }
        return TBCPLScraper.getTBCPLMangaSources(mangaId: mangaId, chapter: chapter)
    }

    /// Primary method: tries TMDB-ID embed sources first (instant, reliable),
    /// then fires HTML scrapers concurrently in background.
    /// Returns results progressively via completion (called multiple times).
    func fetchSources(
        tmdbId: Int,
        imdbId: String? = nil,
        title: String,
        year: String?,
        isTVShow: Bool,
        season: Int = 1,
        episode: Int = 1,
        onResult: @escaping (StreamResult) -> Void,
        onComplete: @escaping () -> Void
    ) {
        let group = DispatchGroup()

        // 1. TMDB-ID embed providers — immediate results, always work
        for provider in embedProviders {
            group.enter()
            
            // Helper to handle results
            let handleResult: (Result<[StreamResult], Error>) -> Void = { result in
                if case .success(let streams) = result {
                    streams.forEach { onResult($0) }
                }
                group.leave()
            }

            if let p = provider as? VidSrcIcuScraper {
                if isTVShow { p.fetchTV(tmdbId: tmdbId, season: season, episode: episode, completion: handleResult) }
                else { p.fetchMovie(tmdbId: tmdbId, completion: handleResult) }
            } else if let p = provider as? VidSrcMeScraper {
                if isTVShow { p.fetchTV(tmdbId: tmdbId, season: season, episode: episode, completion: handleResult) }
                else { p.fetchMovie(tmdbId: tmdbId, completion: handleResult) }

            } else if let p = provider as? TwoEmbedScraper {
                if isTVShow { p.fetchTV(tmdbId: tmdbId, season: season, episode: episode, completion: handleResult) }
                else { p.fetchMovie(tmdbId: tmdbId, completion: handleResult) }
            } else if let p = provider as? TwoEmbedSkinScraper {
                if let imdb = imdbId, !imdb.isEmpty {
                    if isTVShow { p.fetchTV(tmdbId: tmdbId, imdbId: imdb, season: season, episode: episode, completion: handleResult) }
                    else { p.fetchMovie(tmdbId: tmdbId, imdbId: imdb, completion: handleResult) }
                } else {
                    group.leave()
                }
            } else if let p = provider as? VidSrcMovScraper {
                if isTVShow { p.fetchTV(tmdbId: tmdbId, season: season, episode: episode, completion: handleResult) }
                else { p.fetchMovie(tmdbId: tmdbId, completion: handleResult) }
            } else if let p = provider as? AutoEmbedScraper {
                if let imdb = imdbId, !imdb.isEmpty {
                    if isTVShow { p.fetchTV(tmdbId: tmdbId, imdbId: imdb, season: season, episode: episode, completion: handleResult) }
                    else { p.fetchMovie(tmdbId: tmdbId, imdbId: imdb, completion: handleResult) }
                } else {
                    group.leave()
                }
            } else if let p = provider as? MoviesApiClubScraper {
                if isTVShow { p.fetchTV(tmdbId: tmdbId, season: season, episode: episode, completion: handleResult) }
                else { p.fetchMovie(tmdbId: tmdbId, completion: handleResult) }
            } else {
                group.leave()
            }
        }

        // 2. HTML scrapers — fire concurrently in background
        for scraper in htmlScrapers where scraper.isEnabled {
            group.enter()
            scraper.search(query: title, year: year) { result in
                if case .success(let streams) = result { streams.forEach { onResult($0) } }
                group.leave()
            }
        }

        group.notify(queue: .main) { onComplete() }
    }

    /// Convenience wrapper used by DetailVC — picks the first result immediately
    /// and calls completion once the first reliable source is found (doesn't wait for all scrapers).
    func fetchBestSource(
        tmdbId: Int,
        imdbId: String? = nil,
        title: String,
        year: String?,
        isTVShow: Bool,
        season: Int = 1,
        episode: Int = 1,
        completion: @escaping (StreamResult?) -> Void
    ) {
        var found = false
        let lock = NSLock()

        fetchSources(
            tmdbId: tmdbId,
            imdbId: imdbId,
            title: title,
            year: year,
            isTVShow: isTVShow,
            season: season,
            episode: episode,
            onResult: { result in
                lock.lock()
                let alreadyFound = found
                if !found { found = true }
                lock.unlock()
                if !alreadyFound {
                    DispatchQueue.main.async { completion(result) }
                }
            },
            onComplete: {
                lock.lock()
                let wasFound = found
                lock.unlock()
                if !wasFound {
                    DispatchQueue.main.async { completion(nil) }
                }
            }
        )
    }

    // Legacy compatibility for old callers
    func fetchSourcesWithStatusUpdates(
        query: String,
        year: String?,
        statusCallback: @escaping (String, SourceStatus) -> Void,
        completion: @escaping ([StreamResult]) -> Void
    ) {
        // This is called from DetailVC without tmdbId, so we just complete with empty
        // DetailVC should now use fetchBestSource(tmdbId:...) instead
        completion([])
    }
}
