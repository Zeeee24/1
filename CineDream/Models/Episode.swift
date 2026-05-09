import Foundation

struct Episode: Codable, Equatable {
    let id: Int
    let name: String?
    let overview: String?
    let stillPath: String?
    let episodeNumber: Int
    let seasonNumber: Int
    let airDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case stillPath = "still_path"
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case airDate = "air_date"
    }
}

struct SeasonResponse: Codable {
    let episodes: [Episode]
}

struct TVSeason: Codable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
    }
}
