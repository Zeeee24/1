import Foundation

struct Movie: Codable, Equatable {
    let id: Int
    let title: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let runtime: Int?
    let releaseDates: ReleaseDatesResponse?
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case runtime
        case releaseDates = "release_dates"
    }
}

struct ReleaseDatesResponse: Codable, Equatable {
    let results: [ReleaseDateResult]
}

struct ReleaseDateResult: Codable, Equatable {
    let iso3166_1: String
    let releaseDates: [ReleaseDateInfo]
    
    enum CodingKeys: String, CodingKey {
        case iso3166_1 = "iso_3166_1"
        case releaseDates = "release_dates"
    }
}

struct ReleaseDateInfo: Codable, Equatable {
    let certification: String
}


struct TMDBResponse<T: Codable>: Codable {
    let results: [T]
}
