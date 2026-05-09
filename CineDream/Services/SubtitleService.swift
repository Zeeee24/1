import Foundation

// MARK: - OpenSubtitles Models
struct OpenSubtitleResult: Codable {
    let data: [SubtitleData]
}

struct SubtitleData: Codable, Identifiable {
    let id: String
    let attributes: SubtitleAttributes
    
    var languageName: String {
        attributes.language
    }
    
    var downloadUrl: String? {
        attributes.url
    }
}

struct SubtitleAttributes: Codable {
    let language: String
    let url: String?
    let aiTranslated: Bool?
    let machineTranslated: Bool?
    let release: String?
    let uploader: UploaderInfo?
    let ratings: Double?
    let votes: Int?
}

struct UploaderInfo: Codable {
    let name: String
    let rank: String?
}

struct SubtitleDownload: Codable {
    let link: String
    let fileName: String?
    let requests: Int?
    let remaining: Int?
    let message: String?
}

// MARK: - Subtitle Language
struct SubtitleLanguage: Identifiable {
    let id: String
    let code: String
    let name: String
    var isSelected: Bool = false
}

class SubtitleService {
    static let shared = SubtitleService()
    
    private let apiKey = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImplenNsd3lod3hvdnNpanFhdmNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3OTAxOTMsImV4cCI6MjA5MzM2NjE5M30.q2WXGLwp83Yl0InAFZzd_Nh8RGouTPxUhVRP1myA9YE" // Free tier key
    private let baseURL = "https://api.opensubtitles.com/api/v1"
    
    // Common languages
    let availableLanguages: [SubtitleLanguage] = [
        SubtitleLanguage(id: "en", code: "en", name: "English"),
        SubtitleLanguage(id: "es", code: "es", name: "Spanish"),
        SubtitleLanguage(id: "fr", code: "fr", name: "French"),
        SubtitleLanguage(id: "de", code: "de", name: "German"),
        SubtitleLanguage(id: "it", code: "it", name: "Italian"),
        SubtitleLanguage(id: "pt", code: "pt", name: "Portuguese"),
        SubtitleLanguage(id: "ru", code: "ru", name: "Russian"),
        SubtitleLanguage(id: "ja", code: "ja", name: "Japanese"),
        SubtitleLanguage(id: "ko", code: "ko", name: "Korean"),
        SubtitleLanguage(id: "zh", code: "zh", name: "Chinese"),
        SubtitleLanguage(id: "ar", code: "ar", name: "Arabic"),
        SubtitleLanguage(id: "hi", code: "hi", name: "Hindi"),
        SubtitleLanguage(id: "tr", code: "tr", name: "Turkish"),
        SubtitleLanguage(id: "pl", code: "pl", name: "Polish"),
        SubtitleLanguage(id: "nl", code: "nl", name: "Dutch"),
        SubtitleLanguage(id: "sv", code: "sv", name: "Swedish"),
        SubtitleLanguage(id: "da", code: "da", name: "Danish"),
        SubtitleLanguage(id: "no", code: "no", name: "Norwegian"),
        SubtitleLanguage(id: "fi", code: "fi", name: "Finnish"),
        SubtitleLanguage(id: "cs", code: "cs", name: "Czech"),
        SubtitleLanguage(id: "hu", code: "hu", name: "Hungarian"),
        SubtitleLanguage(id: "el", code: "el", name: "Greek"),
        SubtitleLanguage(id: "he", code: "he", name: "Hebrew"),
        SubtitleLanguage(id: "th", code: "th", name: "Thai"),
        SubtitleLanguage(id: "vi", code: "vi", name: "Vietnamese"),
        SubtitleLanguage(id: "id", code: "id", name: "Indonesian"),
        SubtitleLanguage(id: "ms", code: "ms", name: "Malay"),
        SubtitleLanguage(id: "uk", code: "uk", name: "Ukrainian"),
        SubtitleLanguage(id: "ro", code: "ro", name: "Romanian"),
        SubtitleLanguage(id: "bg", code: "bg", name: "Bulgarian")
    ]
    
    // MARK: - Search Subtitles
    func searchSubtitles(imdbId: String, language: String? = nil, completion: @escaping ([SubtitleData]) -> Void) {
        var urlString = "\(baseURL)/subtitles?imdb_id=\(imdbId)"
        if let lang = language {
            urlString += "&languages=\(lang)"
        }
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("[SubtitleService] Error fetching subtitles: \(error?.localizedDescription ?? "Unknown")")
                completion([])
                return
            }
            
            do {
                let result = try JSONDecoder().decode(OpenSubtitleResult.self, from: data)
                completion(result.data)
            } catch {
                print("[SubtitleService] Error decoding subtitles: \(error)")
                completion([])
            }
        }.resume()
    }
    
    // MARK: - Download Subtitle
    func downloadSubtitle(subtitleId: String, completion: @escaping (URL?) -> Void) {
        let urlString = "\(baseURL)/download"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "file_id": subtitleId,
            "sub_format": "vtt"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                let result = try JSONDecoder().decode(SubtitleDownload.self, from: data)
                let link = result.link
                if let url = URL(string: link) {
                    // Download the actual subtitle file
                    self.downloadSubtitleFile(from: url, completion: completion)
                } else {
                    completion(nil)
                }
            } catch {
                print("[SubtitleService] Error decoding download: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    private func downloadSubtitleFile(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                completion(nil)
                return
            }
            
            // Move to permanent location
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let subtitlePath = documentsPath.appendingPathComponent(UUID().uuidString + ".vtt")
            
            try? FileManager.default.moveItem(at: localURL, to: subtitlePath)
            completion(subtitlePath)
        }
        task.resume()
    }
    
    // MARK: - VTT Parsing
    func parseVTT(from string: String) -> [SubtitleCue] {
        var cues = [SubtitleCue]()
        let lines = string.components(separatedBy: .newlines)
        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.contains("-->") {
                let times = line.components(separatedBy: "-->")
                if times.count == 2 {
                    let start = parseTime(times[0])
                    let end = parseTime(times[1])
                    i += 1
                    var text = ""
                    while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
                        text += lines[i] + "\n"
                        i += 1
                    }
                    cues.append(SubtitleCue(startTime: start, endTime: end, text: text.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
            } else {
                i += 1
            }
        }
        return cues
    }
    
    private func parseTime(_ string: String) -> TimeInterval {
        let parts = string.trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
        if parts.count == 3 {
            let h = Double(parts[0]) ?? 0
            let m = Double(parts[1]) ?? 0
            let sParts = parts[2].components(separatedBy: ".")
            let s = Double(sParts[0]) ?? 0
            let ms = sParts.count > 1 ? (Double(sParts[1]) ?? 0) / 1000.0 : 0
            return h * 3600 + m * 60 + s + ms
        }
        return 0
    }
}
