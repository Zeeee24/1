import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.tintColor = UIColor(hex: "#E50914")
        tabBar.unselectedItemTintColor = .gray
        
        let homeVC = UINavigationController(rootViewController: HomeVC())
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)
        
        let searchVC = UINavigationController(rootViewController: SearchVC())
        searchVC.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 1)
        
        let browseVC = UINavigationController(rootViewController: BrowseVC())
        browseVC.tabBarItem = UITabBarItem(title: "Browse", image: UIImage(systemName: "square.grid.2x2.fill"), tag: 2)
        
        let watchLaterVC = UINavigationController(rootViewController: WatchLaterVC())
        watchLaterVC.tabBarItem = UITabBarItem(title: "Watch Later", image: UIImage(systemName: "heart.fill"), tag: 3)
        
        let settingsVC = UINavigationController(rootViewController: SettingsVC())
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: 4)
        
        viewControllers = [homeVC, searchVC, browseVC, watchLaterVC, settingsVC]
    }
}
