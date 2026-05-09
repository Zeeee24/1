import UIKit

// MARK: - Netflix-style Animation Extensions
extension UIView {
    
    // Netflix spring animation
    func animateWithSpring(duration: TimeInterval = 0.3, 
                          delay: TimeInterval = 0, 
                          damping: CGFloat = 0.8, 
                          velocity: CGFloat = 0.5, 
                          animations: @escaping () -> Void, 
                          completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, 
                       delay: delay, 
                       usingSpringWithDamping: damping, 
                       initialSpringVelocity: velocity, 
                       options: [.curveEaseInOut, .allowUserInteraction], 
                       animations: animations, 
                       completion: completion)
    }
    
    // Netflix fade in animation
    func fadeIn(duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) {
        alpha = 0
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
            self.alpha = 1
        }, completion: completion)
    }
    
    // Netflix fade out animation
    func fadeOut(duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
            self.alpha = 0
        }, completion: completion)
    }
    
    // Netflix slide up animation
    func slideUp(from: CGFloat = 50, duration: TimeInterval = 0.3, completion: ((Bool) -> Void)? = nil) {
        transform = CGAffineTransform(translationX: 0, y: from)
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.transform = .identity
        }, completion: completion)
    }
    
    // Netflix scale animation
    func scaleTo(_ scale: CGFloat, duration: TimeInterval = 0.3, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: completion)
    }
}

// MARK: - Netflix Button Animation
extension UIButton {
    
    func addNetflixTouchEffect() {
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc func touchDown() {
        HapticManager.shared.light()
        animateWithSpring(duration: 0.1, damping: 0.6, velocity: 0.8) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.alpha = 0.8
        }
    }
    
    @objc func touchUp() {
        animateWithSpring(duration: 0.2, damping: 0.6, velocity: 0.8) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }
}

// MARK: - Netflix Collection View Cell Animation
extension UICollectionViewCell {
    
    func addNetflixHoverEffect() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowOpacity = 0
        layer.shadowRadius = 12
        layer.masksToBounds = false
        
        // Only add hover gesture on macOS/iPadOS where it's supported
        #if targetEnvironment(macCatalyst) || os(visionOS)
        addGestureRecognizer(UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:))))
        #endif
    }
    
    @objc private func handleHover(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            animateWithSpring(duration: 0.3, damping: 0.8, velocity: 0.5) {
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.layer.shadowOpacity = 0.3
                self.layer.zPosition = 1000
            }
        case .ended:
            animateWithSpring(duration: 0.3, damping: 0.8, velocity: 0.5) {
                self.transform = .identity
                self.layer.shadowOpacity = 0
                self.layer.zPosition = 0
            }
        default:
            break
        }
    }
}

// MARK: - Netflix Navigation Bar Animation
extension UINavigationBar {
    
    func addNetflixStyle() {
        barTintColor = UIColor.black
        tintColor = .white
        titleTextAttributes = [.foregroundColor: UIColor.white]
        isTranslucent = false
        shadowImage = UIImage()
        setBackgroundImage(UIImage(), for: .default)
    }
}

// MARK: - Netflix Tab Bar Animation
extension UITabBar {
    
    func addNetflixStyle() {
        barTintColor = UIColor.black
        tintColor = UIColor(hex: "#E50914")
        unselectedItemTintColor = .gray
        isTranslucent = false
        shadowImage = UIImage()
        backgroundImage = UIImage()
        
        // Add spring animation to tab selection
        let delegate = NetflixTabBarDelegate()
        UITabBar.delegateProxy.delegate = delegate
        self.delegate = delegate
    }
    
    private struct delegateProxy {
        static var delegate: UITabBarDelegate?
    }
}

private class NetflixTabBarDelegate: NSObject, UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let view = item.value(forKey: "view") as? UIView else { return }
        
        view.animateWithSpring(duration: 0.3, damping: 0.6, velocity: 0.8) {
            view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { _ in
            view.animateWithSpring(duration: 0.2, damping: 0.6, velocity: 0.8) {
                view.transform = .identity
            }
        }
    }
}

// MARK: - Netflix Loading Animation
extension UIActivityIndicatorView {
    
    func addNetflixStyle() {
        style = .large
        color = UIColor(hex: "#E50914")
        hidesWhenStopped = true
    }
}

// MARK: - Netflix Shimmer Effect
class NetflixShimmerView: UIView {
    
    private let gradientLayer = CAGradientLayer()
    private let animationDuration: TimeInterval = 1.5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShimmer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupShimmer()
    }
    
    private func setupShimmer() {
        backgroundColor = UIColor(white: 0.1, alpha: 1)
        
        gradientLayer.colors = [
            UIColor(white: 0.1, alpha: 1).cgColor,
            UIColor(white: 0.2, alpha: 1).cgColor,
            UIColor(white: 0.1, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: -1, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.locations = [0, 0.5, 1]
        layer.addSublayer(gradientLayer)
        
        startShimmer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    func startShimmer() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = animationDuration
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "shimmer")
    }
    
    func stopShimmer() {
        gradientLayer.removeAnimation(forKey: "shimmer")
    }
}

// MARK: - Netflix Skeleton View
class NetflixSkeletonView: UIView {
    
    private let shimmerView = NetflixShimmerView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSkeleton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSkeleton()
    }
    
    private func setupSkeleton() {
        backgroundColor = UIColor(white: 0.1, alpha: 1)
        layer.cornerRadius = 8
        clipsToBounds = true
        
        addSubview(shimmerView)
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shimmerView.topAnchor.constraint(equalTo: topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func show() {
        isHidden = false
        shimmerView.startShimmer()
    }
    
    func hide() {
        shimmerView.stopShimmer()
        fadeOut(duration: 0.3) { _ in
            self.isHidden = true
        }
    }
}
