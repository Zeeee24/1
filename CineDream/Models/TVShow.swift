import Foundation

struct TVShow: Codable, Equatable {
    let id: Int
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let contentRatings: ContentRatingsResponse?
    let episodeRunTime: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
        case contentRatings = "content_ratings"
        case episodeRunTime = "episode_run_time"
    }
}

struct ContentRatingsResponse: Codable, Equatable {
    let results: [ContentRatingResult]
}

struct ContentRatingResult: Codable, Equatable {
    let iso3166_1: String
    let rating: String
    
    enum CodingKeys: String, CodingKey {
        case iso3166_1 = "iso_3166_1"
        case rating
    }
}

// Genre helpers used by TMDBService
struct Genre: Codable {
    let id: Int
    let name: String
}

struct GenreResponse: Codable {
    let genres: [Genre]
}
