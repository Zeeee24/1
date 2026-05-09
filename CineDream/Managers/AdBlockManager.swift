import Foundation
import WebKit

class AdBlockManager {
    static let shared = AdBlockManager()
    
    private var contentRuleList: WKContentRuleList?
    
    private init() {
        compileRules()
    }
    
    private func compileRules() {
        let rules = """
        [
            {
                "trigger": {
                    "url-filter": ".*(doubleclick\\\\.net|googlesyndication\\\\.com|adservice\\\\.google\\\\.com|pagead2\\\\.googlesyndication\\\\.com|ads\\\\.yahoo\\\\.com|popads\\\\.net|popcash\\\\.net|exoclick\\\\.com|propellerads\\\\.com|adsterra\\\\.com|onclickmega\\\\.com|bidgear\\\\.com|bet365\\\\.com|1xbet\\\\.com).*"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": ".*(analytics|tracker|pixel|adserver|adsystem).*"
                },
                "action": {
                    "type": "block"
                }
            }
        ]
        """
        
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "CineDreamAdBlocker",
            encodedContentRuleList: rules
        ) { [weak self] list, error in
            if let error = error {
                print("Failed to compile ad block rules: \\(error)")
                return
            }
            self?.contentRuleList = list
        }
    }
    
    func applyAdBlocker(to webView: WKWebView) {
        // Apply Content Rule List
        if let ruleList = contentRuleList {
            webView.configuration.userContentController.add(ruleList)
        } else {
            // If it hasn't compiled yet, wait and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let ruleList = self.contentRuleList {
                    webView.configuration.userContentController.add(ruleList)
                }
            }
        }
    }
}
