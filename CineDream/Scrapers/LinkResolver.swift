import Foundation

class LinkResolver {
    static func resolve(url: URL, completion: @escaping (URL?) -> Void) {
        let host = url.host ?? ""
        if host.contains("streamhub") || host.contains("vidhide") {
            resolveStreamHub(url: url, completion: completion)
        } else if host.contains("doodstream") || host.contains("dood") {
            resolveDoodStream(url: url, completion: completion)
        } else if host.contains("drive.google.com") || host.contains("docs.google.com") {
            resolveGDrive(url: url, completion: completion)
        } else if host.contains("streamtape") {
            resolveStreamTape(url: url, completion: completion)
        } else if host.contains("mixdrop") {
            resolveMixDrop(url: url, completion: completion)
        } else if host.contains("filemoon") {
            resolveFileMoon(url: url, completion: completion)
        } else if host.contains("streamwish") {
            resolveStreamWish(url: url, completion: completion)
        } else if host.contains("vidplay") || host.contains("vidmoly") {
            resolveVidPlay(url: url, completion: completion)
        } else {
            completion(url) // Fallback to original
        }
    }
    
    private static func resolveStreamHub(url: URL, completion: @escaping (URL?) -> Void) {
        fetchHTML(url: url) { html in
            guard let html = html else { return completion(nil) }
            if let m3u8 = html.matches(for: "sources:\\s*\\[\\{file:\\s*[\"']([^\"']+\\.m3u8)[\"']").first?.components(separatedBy: "file:").last?.trimmingCharacters(in: CharacterSet(charactersIn: " \"'")) {
                completion(URL(string: m3u8))
            } else {
                completion(nil)
            }
        }
    }
    
    private static func resolveDoodStream(url: URL, completion: @escaping (URL?) -> Void) {
        fetchHTML(url: url) { html in
            guard let html = html else { return completion(nil) }
            if let passPath = html.matches(for: "/pass_md5/[^\"']+").first {
                let token = url.lastPathComponent
                guard let host = url.host else { return completion(nil) }
                let passUrl = URL(string: "https://\(host)\(passPath)")
                guard let passUrl = passUrl else { return completion(nil) }
                var request = URLRequest(url: passUrl)
                request.addValue(url.absoluteString, forHTTPHeaderField: "Referer")
                URLSession.shared.dataTask(with: request) { data, _, _ in
                    if let data = data, let direct = String(data: data, encoding: .utf8) {
                        let finalUrl = "\(direct)1234567890?token=\(token)&expiry=\(Date().timeIntervalSince1970)"
                        completion(URL(string: finalUrl))
                    } else {
                        completion(nil)
                    }
                }.resume()
            } else {
                completion(nil)
            }
        }
    }
    
    private static func resolveGDrive(url: URL, completion: @escaping (URL?) -> Void) {
        if url.absoluteString.contains("/view") {
            let id = url.absoluteString.components(separatedBy: "/d/").last?.components(separatedBy: "/").first ?? ""
            let downloadUrl = "https://docs.google.com/uc?export=download&id=\(id)"
            completion(URL(string: downloadUrl))
        } else {
            completion(url)
        }
    }
    
    private static func resolveStreamTape(url: URL, completion: @escaping (URL?) -> Void) {
        fetchHTML(url: url) { html in
            guard let html = html else { return completion(nil) }
            if let robotlink = html.matches(for: "document\\.getElementById\\('robotlink'\\)\\.innerHTML = '([^']+)'").first {
                let extracted = robotlink.components(separatedBy: "'").dropFirst().first ?? ""
                if let token = html.matches(for: "\\+ \\('xcd([^']+)'\\)").first?.components(separatedBy: "'").dropFirst().first {
                    completion(URL(string: "https:\(extracted)\(token)"))
                    return
                }
            }
            completion(nil)
        }
    }
    
    private static func resolveMixDrop(url: URL, completion: @escaping (URL?) -> Void) {
        fetchHTML(url: url) { html in
            guard let html = html else { return completion(nil) }
            if let wurl = html.matches(for: "wurl=\"([^\"]+)\"").first?.components(separatedBy: "\"").dropFirst().first {
                completion(URL(string: wurl.hasPrefix("http") ? wurl : "https:\(wurl)"))
            } else {
                completion(nil)
            }
        }
    }
    
    private static func resolveFileMoon(url: URL, completion: @escaping (URL?) -> Void) {
        fetchHTML(url: url) { html in
            guard let html = html else { return completion(nil) }
            if let file = html.matches(for: "file:\\s*\"([^\"]+\\.m3u8)\"").first?.components(separatedBy: "\"").dropFirst().first {
                completion(URL(string: file))
            } else {
                completion(nil)
            }
        }
    }
    
    private static func resolveStreamWish(url: URL, completion: @escaping (URL?) -> Void) {
        fetchHTML(url: url) { html in
            guard let html = html else { return completion(nil) }
            if let file = html.matches(for: "file:\\s*\"([^\"]+\\.m3u8)\"").first?.components(separatedBy: "\"").dropFirst().first {
                completion(URL(string: file))
            } else {
                completion(nil)
            }
        }
    }
    
    private static func resolveVidPlay(url: URL, completion: @escaping (URL?) -> Void) {
        completion(url) // Placeholder for VidPlay resolver logic
    }
    
    private static func fetchHTML(url: URL, completion: @escaping (String?) -> Void) {
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: req) { data, _, _ in
            if let data = data {
                completion(String(data: data, encoding: .utf8))
            } else {
                completion(nil)
            }
        }.resume()
    }
}
