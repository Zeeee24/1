import Foundation
import UIKit

class ServerCheckManager {
    static let shared = ServerCheckManager()
    
    // Keyed by TMDB ID
    private var results: [Int: [String: ServerCheckResult]] = [:]
    private var allSourcesCache: [Int: [StreamResult]] = [:]
    
    // Observers can subscribe to updates
    var onUpdate: ((Int) -> Void)?
    
    private init() {}
    
    func startChecking(tmdbId: Int, isTVShow: Bool, imdbId: String?, season: Int = 1, episode: Int = 1) {
        // Clear previous results for this ID
        results[tmdbId] = [:]
        
        SourceManager.shared.buildAllEmbedSources(tmdbId: tmdbId, isTVShow: isTVShow, season: season, episode: episode, imdbId: imdbId) { [weak self] allSources in
            guard let self = self else { return }
            self.allSourcesCache[tmdbId] = allSources
            
            // Simultaneously check all servers
            for source in allSources {
                // Initial checking status
                self.results[tmdbId]?[source.sourceId] = ServerCheckResult(source: source, status: .checking, responseTime: 0)
                DispatchQueue.main.async { self.onUpdate?(tmdbId) }
                
                self.checkServerResponseTime(source) { result in
                    self.results[tmdbId]?[source.sourceId] = result
                    DispatchQueue.main.async { self.onUpdate?(tmdbId) }
                }
            }
        }
    }
    
    func getResults(for tmdbId: Int) -> [String: ServerCheckResult] {
        return results[tmdbId] ?? [:]
    }
    
    func getAllSources(for tmdbId: Int) -> [StreamResult] {
        return allSourcesCache[tmdbId] ?? []
    }
    
    private func checkServerResponseTime(_ source: StreamResult, completion: @escaping (ServerCheckResult) -> Void) {
        let startTime = Date()
        
        var request = URLRequest(url: source.url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let responseTime = Date().timeIntervalSince(startTime)
            DispatchQueue.main.async {
                if let error = error {
                    completion(ServerCheckResult(source: source, status: .dead, responseTime: responseTime))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(ServerCheckResult(source: source, status: .dead, responseTime: responseTime))
                    return
                }
                
                if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 400) || httpResponse.statusCode == 403 || httpResponse.statusCode == 503 {
                    let status: ServerQualityStatus = responseTime < 1.0 ? .fast : .slow
                    completion(ServerCheckResult(source: source, status: status, responseTime: responseTime))
                } else {
                    // Try a GET request if HEAD fails (some servers block HEAD with 405 Method Not Allowed)
                    if httpResponse.statusCode == 405 {
                        var getRequest = URLRequest(url: source.url)
                        getRequest.timeoutInterval = 3.0
                        URLSession.shared.dataTask(with: getRequest) { _, getResponse, _ in
                            let getResponseTime = Date().timeIntervalSince(startTime)
                            DispatchQueue.main.async {
                                if let getResp = getResponse as? HTTPURLResponse, (getResp.statusCode >= 200 && getResp.statusCode < 400) || getResp.statusCode == 403 || getResp.statusCode == 503 {
                                    let status: ServerQualityStatus = getResponseTime < 1.0 ? .fast : .slow
                                    completion(ServerCheckResult(source: source, status: status, responseTime: getResponseTime))
                                } else {
                                    completion(ServerCheckResult(source: source, status: .dead, responseTime: getResponseTime))
                                }
                            }
                        }.resume()
                    } else {
                        completion(ServerCheckResult(source: source, status: .dead, responseTime: responseTime))
                    }
                }
            }
        }.resume()
    }
}
