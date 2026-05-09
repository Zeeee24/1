import Foundation

struct StreamResult: Codable {
    let sourceId: String
    let sourceName: String
    let quality: String
    let url: URL
    let isEmbed: Bool
    let headers: [String: String]?
}

enum SourceStatus {
    case notStarted
    case loading
    case found
    case failed
}

struct WatchProgress: Codable {
    let tmdbId: Int
    let progressSeconds: Double
    let durationSeconds: Double
}

struct ContinueWatchingItem: Codable {
    let tmdbId: Int
    let title: String
    let posterPath: String?
    let backdropPath: String?
    let contentType: String
    let season: Int?
    let episode: Int?
    let progressSeconds: Double
    let durationSeconds: Double
    let lastWatched: Date
}

struct HistoryItem: Codable {
    let tmdbId: Int
    let title: String
    let posterPath: String?
    let contentType: String
    let watchedDate: String
    let progressSeconds: Double
    let durationSeconds: Double
}

struct SubtitleCue: Codable {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
}
