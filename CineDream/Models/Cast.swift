import Foundation

struct Cast: Codable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }
}

struct CreditsResponse: Codable {
    let cast: [Cast]
}
