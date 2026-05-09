import Foundation
import WebKit

class ServerHealthChecker {
    
    static let shared = ServerHealthChecker()
    
    private var serverStatus: [String: ServerStatus] = [:]
    private let healthCheckTimeout: TimeInterval = 5.0
    
    private init() {}
    
    enum ServerStatus {
        case healthy
        case unhealthy
        case unknown
        case checking
        
        var color: String {
            switch self {
            case .healthy: return "🟢"
            case .unhealthy: return "🔴"
            case .unknown: return "🟡"
            case .checking: return "⏳"
            }
        }
        
        var isHealthy: Bool {
            return self == .healthy
        }
    }
    
    // MARK: - Public Methods
    
    func checkServerHealth(for source: StreamResult, completion: @escaping (ServerStatus) -> Void) {
        let serverId = source.sourceId
        
        // Return cached status if recent
        if let cachedStatus = serverStatus[serverId] {
            completion(cachedStatus)
            return
        }
        
        // Mark as checking
        serverStatus[serverId] = .checking
        
        // Perform health check
        performHealthCheck(for: source) { [weak self] status in
            self?.serverStatus[serverId] = status
            completion(status)
        }
    }
    
    func getHealthyServers(from sources: [StreamResult], completion: @escaping ([StreamResult]) -> Void) {
        var healthySources: [StreamResult] = []
        var remainingSources = sources
        var completedChecks = 0
        
        guard !sources.isEmpty else {
            completion([])
            return
        }
        
        for source in sources {
            checkServerHealth(for: source) { status in
                completedChecks += 1
                
                if status.isHealthy {
                    healthySources.append(source)
                }
                
                // Return when all checks complete or we have at least one healthy source
                if completedChecks == sources.count || !healthySources.isEmpty {
                    completion(healthySources)
                }
            }
        }
    }
    
    func preloadServerStatus(sources: [StreamResult]) {
        for source in sources {
            checkServerHealth(for: source) { _ in }
        }
    }
    
    // MARK: - Private Methods
    
    private func performHealthCheck(for source: StreamResult, completion: @escaping (ServerStatus) -> Void) {
        let request = URLRequest(url: source.url, timeoutInterval: healthCheckTimeout)
        
        // Simple URL session check
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 400 {
                        completion(.healthy)
                    } else {
                        completion(.unhealthy)
                    }
                } else if error != nil {
                    completion(.unhealthy)
                } else {
                    completion(.healthy)
                }
            }
        }.resume()
    }
    
    // MARK: - Server List Management
    
    func updateServerStatus(serverId: String, status: ServerStatus) {
        serverStatus[serverId] = status
    }
    
    func getServerStatus(serverId: String) -> ServerStatus {
        return serverStatus[serverId] ?? .unknown
    }
    
    func clearCache() {
        serverStatus.removeAll()
    }
    
    // MARK: - Batch Health Check
    
    func batchHealthCheck(sources: [StreamResult], completion: @escaping ([StreamResult]) -> Void) {
        var healthySources: [StreamResult] = []
        let group = DispatchGroup()
        
        for source in sources {
            group.enter()
            checkServerHealth(for: source) { status in
                if status.isHealthy {
                    healthySources.append(source)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(healthySources)
        }
    }
}
