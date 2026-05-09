import Foundation

struct Constants {
    // IMPORTANT: TMDB API Key configuration
    // Get your free API key from https://www.themoviedb.org/settings/api
    // For development: set environment variable TMDB_API_KEY or use .xcconfig
    // For CI/release: key is injected as build setting TMDB_API_KEY
    static let tmdbAPIKey: String = {
        #if DEBUG
        // Debug: Prefer environment variable for local dev
        let envKey = ProcessInfo.processInfo.environment["TMDB_API_KEY"]
        if let envKey = envKey, !envKey.isEmpty {
            return envKey
        }
        #endif
        // Release/Debug fallback: read from Info.plist (populated by build setting)
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String ?? ""
        if !plistKey.isEmpty && plistKey != "$(TMDB_API_KEY)" {
            return plistKey
        }
        // Hardcoded fallback
        return "b67e640f1b90b799a41e12416a891ed9"
    }()
    
    static let tmdbBaseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p/w500"
    static let backdropBaseURL = "https://image.tmdb.org/t/p/original"
    
    struct Scrapers {
        static let vegamovies = "vegamovies.mov"
        static let bollyflix = "bollyflix.day"
        static let movierulzhd = "movierulzhd.com"
        static let hdhub4u = "hdhub4u.nz"
        static let multimovies = "multimovies.cfd"
        static let moviesdrive = "moviesdrive.app"
        static let moviesmod = "moviesmod.pub"
        static let netflixmirror = "netflixmirror.com"
        static let watch32 = "watch32.sx"
        static let uhdmovies = "uhdmovies.charity"
        static let filmycab = "filmycab.net"
        static let filmyfiy = "filmyfiy.net"
        static let desicinemas = "desicinemas.to"
        static let allmovieland = "allmovieland.com"
        static let fourKHDHub = "4khdmovies.com"
        static let goojara = "goojara.to"
        static let xdmovies = "xdmovies.wtf"
        static let yflix = "yflix.to"
        static let cinestream = "cinestream.cc"
        static let vidsrcMovies = "https://vidsrc.mov/embed/movie/"
        static let vidsrcTV = "https://vidsrc.mov/embed/tv/"
    }
}
