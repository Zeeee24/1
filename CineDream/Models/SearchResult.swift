import Foundation

struct SearchResult {
    let movie: Movie?
    let tvShow: TVShow?
    
    var id: Int {
        return movie?.id ?? tvShow?.id ?? 0
    }
    
    var title: String {
        return movie?.title ?? tvShow?.name ?? "Unknown"
    }
    
    var overview: String {
        return movie?.overview ?? tvShow?.overview ?? ""
    }
    
    var posterPath: String? {
        return movie?.posterPath ?? tvShow?.posterPath
    }
    
    var backdropPath: String? {
        return movie?.backdropPath ?? tvShow?.backdropPath
    }
    
    var releaseDate: String? {
        return movie?.releaseDate ?? tvShow?.firstAirDate
    }
    
    var voteAverage: Double {
        return movie?.voteAverage ?? tvShow?.voteAverage ?? 0.0
    }
    
    var isMovie: Bool {
        return movie != nil
    }
    
    var isTVShow: Bool {
        return tvShow != nil
    }
}
