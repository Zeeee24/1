import Foundation
import WebKit

class StreamResolverService: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let shared = StreamResolverService()
    
    private var webView: WKWebView?
    private var completion: ((URL?) -> Void)?
    private var timer: Timer?
    private var currentImdbId: String = ""
    private var isFallback = false
    
    private override init() {
        super.init()
        
        DispatchQueue.main.async {
            let config = WKWebViewConfiguration()
            let controller = WKUserContentController()
            controller.add(self, name: "streamFound")
            config.userContentController = controller
            
            // Inject JS to intercept network requests and find video sources
            let js = """
            (function() {
                // Intercept XHR
                var open = XMLHttpRequest.prototype.open;
                XMLHttpRequest.prototype.open = function() {
                    var url = arguments[1];
                    if (url && (url.includes('.m3u8') || url.includes('.mp4') || url.includes('playlist.m3u8'))) {
                        window.webkit.messageHandlers.streamFound.postMessage(url);
                    }
                    open.apply(this, arguments);
                };
                
                // Intercept Fetch
                var originalFetch = window.fetch;
                window.fetch = function() {
                    var url = arguments[0];
                    if (typeof url === 'string' && (url.includes('.m3u8') || url.includes('.mp4') || url.includes('playlist.m3u8'))) {
                        window.webkit.messageHandlers.streamFound.postMessage(url);
                    }
                    return originalFetch.apply(this, arguments);
                };
                
                // Monitor video elements
                setInterval(function() {
                    var videos = document.getElementsByTagName('video');
                    for (var i = 0; i < videos.length; i++) {
                        var src = videos[i].src || (videos[i].querySelector('source') ? videos[i].querySelector('source').src : '');
                        if (src && (src.includes('.m3u8') || src.includes('.mp4') || src.includes('playlist.m3u8'))) {
                            window.webkit.messageHandlers.streamFound.postMessage(src);
                        }
                    }
                }, 1000);
            })();
            """
            let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            controller.addUserScript(script)
            
            self.webView = WKWebView(frame: .zero, configuration: config)
            self.webView?.navigationDelegate = self
            
            if let webView = self.webView {
                AdBlockManager.shared.applyAdBlocker(to: webView)
            }
            
            // Set a generic user agent to avoid some blocks
            self.webView?.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
        }
    }
    
    func resolve(imdbId: String, isTVShow: Bool, season: Int? = nil, episode: Int? = nil, completion: @escaping (URL?) -> Void) {
        DispatchQueue.main.async {
            self.currentImdbId = imdbId
            self.completion = completion
            self.isFallback = false
            
            let type = isTVShow ? "tv" : "movie"
            let path = isTVShow ? "\(imdbId)/\(season ?? 1)/\(episode ?? 1)" : imdbId
            
            self.currentType = type
            self.currentPath = path
            
            self.loadSource(url: "https://vidsrc.icu/embed/\(type)/\(path)")
        }
    }
    
    private var currentType: String = ""
    private var currentPath: String = ""
    
    private func loadSource(url: String) {
        print("[StreamResolver] Resolving: \(url)")
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.handleTimeout()
        }
        
        if let requestUrl = URL(string: url) {
            webView?.load(URLRequest(url: requestUrl))
        }
    }
    
    private func handleTimeout() {
        if !isFallback {
            print("[StreamResolver] Source 1 timed out, trying Source 2 (vidsrc.mov)")
            isFallback = true
            loadSource(url: "https://vidsrc.mov/embed/\(currentType)/\(currentPath)")
        } else {
            print("[StreamResolver] All sources timed out")
            completion?(nil)
            cleanup()
        }
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        completion = nil
        webView?.stopLoading()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "streamFound", let urlString = message.body as? String {
            // Basic validation for video URLs
            if urlString.contains(".m3u8") || urlString.contains(".mp4") || urlString.contains("playlist.m3u8") {
                if let url = URL(string: urlString) {
                    print("[StreamResolver] Found stream: \(urlString)")
                    completion?(url)
                    cleanup()
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Intercept navigation to direct video files if any
        if let url = navigationAction.request.url {
            let urlString = url.absoluteString
            if urlString.contains(".m3u8") || urlString.contains(".mp4") {
                print("[StreamResolver] Intercepted navigation to stream: \(urlString)")
                completion?(url)
                cleanup()
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}
