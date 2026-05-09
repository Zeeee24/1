import UIKit
import WebKit

class PlaybackErrorHandler {
    
    static let shared = PlaybackErrorHandler()
    
    private init() {}
    
    // MARK: - Error Detection
    func detectPlaybackError(in webView: WKWebView, completion: @escaping (Bool, String?) -> Void) {
        // Inject JavaScript to detect common playback errors
        let errorDetectionScript = """
        (function() {
            // Check for common error indicators
            var errorSelectors = [
                '.error-message',
                '.player-error',
                '.video-error',
                '[class*="error"]',
                '[id*="error"]'
            ];
            
            for (var i = 0; i < errorSelectors.length; i++) {
                var elements = document.querySelectorAll(errorSelectors[i]);
                if (elements.length > 0) {
                    return elements[0].textContent || 'Playback error detected';
                }
            }
            
            // Check for video element issues
            var videos = document.querySelectorAll('video');
            for (var i = 0; i < videos.length; i++) {
                var video = videos[i];
                if (video.error) {
                    return 'Video error: ' + video.error.message;
                }
                if (video.readyState === 0) {
                    return 'Video not loading';
                }
            }
            
            // Check for common error text
            var bodyText = document.body.innerText.toLowerCase();
            var errorKeywords = [
                'error', 'failed', 'not available', 'cannot play', 
                'video not found', 'source not found', '404', '500'
            ];
            
            for (var i = 0; i < errorKeywords.length; i++) {
                if (bodyText.includes(errorKeywords[i])) {
                    return 'Error detected: ' + errorKeywords[i];
                }
            }
            
            return null;
        })();
        """
        
        webView.evaluateJavaScript(errorDetectionScript) { result, error in
            if let errorMessage = result as? String, !errorMessage.isEmpty {
                completion(true, errorMessage)
            } else {
                completion(false, nil)
            }
        }
    }
    
    // MARK: - Auto Retry Logic
    func setupAutoRetry(for webView: WKWebView, sources: [StreamResult], currentIndex: Int, onRetry: @escaping (StreamResult) -> Void) {
        // Wait a few seconds then check for errors
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.detectPlaybackError(in: webView) { hasError, errorMessage in
                if hasError, currentIndex < sources.count - 1 {
                    print("Playback error detected: \(errorMessage ?? "Unknown error")")
                    print("Retrying with next source...")
                    
                    // Try next source
                    let nextIndex = currentIndex + 1
                    let nextSource = sources[nextIndex]
                    onRetry(nextSource)
                }
            }
        }
    }
    
    // MARK: - Source Quality Assessment
    func assessSourceQuality(sourceId: String) -> Int {
        // Priority scores for different sources (lower = better)
        let sourcePriorities: [String: Int] = [
            "vidsrc_to": 1,
            "2embed": 2,
            "autoembed": 3,
            "multiembed": 4,
            "vidsrc_me": 5,
            "embed_su": 6,
            "vidsrc_mov": 7,
            "smashy": 8,
            "vidbinge": 9,
            "vidsrc_in": 10,
            "vidsrc_pm": 11
        ]
        
        return sourcePriorities[sourceId] ?? 999
    }
    
    // MARK: - Enhanced WebView Setup
    func setupWebViewForReliability(_ webView: WKWebView) {
        // Enhanced configuration for better compatibility
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        webView.configuration.allowsPictureInPictureMediaPlayback = true
        
        // Add user agent for better compatibility
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        // Enable JavaScript for error detection
        webView.configuration.preferences.javaScriptEnabled = true
        
        // Allow mixed content for older sources
        webView.configuration.allowsAirPlayForMediaPlayback = true
        webView.configuration.allowsInlineMediaPlayback = true
        
        // Apply robust ad blocker
        AdBlockManager.shared.applyAdBlocker(to: webView)
    }
    
    // MARK: - Fallback Content
    func getFallbackSources(tmdbId: Int, isTVShow: Bool, season: Int = 1, episode: Int = 1) -> [StreamResult] {
        var fallbacks: [StreamResult] = []
        
        // Add some generic fallback URLs that work for most content
        if isTVShow {
            let fallbackUrls = [
                ("flicks", "Flicks", "https://flicks.ink/embed/tv/\(tmdbId)/\(season)/\(episode)"),
                ("dood", "DoodStream", "https://dood.so/e/\(tmdbId)"),
                ("streamtape", "StreamTape", "https://streamtape.com/e/\(tmdbId)")
            ]
            
            for (id, name, urlString) in fallbackUrls {
                if let url = URL(string: urlString) {
                    fallbacks.append(StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil))
                }
            }
        } else {
            let fallbackUrls = [
                ("flicks", "Flicks", "https://flicks.ink/embed/movie/\(tmdbId)"),
                ("dood", "DoodStream", "https://dood.so/e/\(tmdbId)"),
                ("streamtape", "StreamTape", "https://streamtape.com/e/\(tmdbId)")
            ]
            
            for (id, name, urlString) in fallbackUrls {
                if let url = URL(string: urlString) {
                    fallbacks.append(StreamResult(sourceId: id, sourceName: name, quality: "Auto", url: url, isEmbed: true, headers: nil))
                }
            }
        }
        
        return fallbacks
    }
}
