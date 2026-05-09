import UIKit

// MARK: - Netflix Loading Collection View Cell
class NetflixLoadingCell: UICollectionViewCell {
    static let identifier = "NetflixLoadingCell"
    
    private let skeletonView = NetflixSkeletonView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(skeletonView)
        skeletonView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            skeletonView.topAnchor.constraint(equalTo: contentView.topAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        skeletonView.show()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        skeletonView.show()
    }
}

// MARK: - Netflix Loading Section View
class NetflixLoadingSectionView: UIView {
    
    private let titleLabel: NetflixSkeletonView = {
        let skeleton = NetflixSkeletonView()
        skeleton.translatesAutoresizingMaskIntoConstraints = false
        return skeleton
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 130, height: 195)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(NetflixLoadingCell.self, forCellWithReuseIdentifier: NetflixLoadingCell.identifier)
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.widthAnchor.constraint(equalToConstant: 120),
            titleLabel.heightAnchor.constraint(equalToConstant: 24),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 230),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        collectionView.dataSource = self
    }
    
    func showLoading() {
        isHidden = false
        titleLabel.show()
        collectionView.reloadData()
    }
    
    func hideLoading() {
        fadeOut(duration: 0.3) { _ in
            self.isHidden = true
        }
    }
}

extension NetflixLoadingSectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6 // Show 6 loading skeletons
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: NetflixLoadingCell.identifier, for: indexPath)
    }
}

// MARK: - Netflix Loading Hero View
class NetflixLoadingHeroView: UIView {
    
    private let skeletonView = NetflixSkeletonView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(skeletonView)
        skeletonView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            skeletonView.topAnchor.constraint(equalTo: topAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        skeletonView.show()
    }
    
    func showLoading() {
        isHidden = false
        skeletonView.show()
    }
    
    func hideLoading() {
        fadeOut(duration: 0.3) { _ in
            self.isHidden = true
        }
    }
}

// MARK: - Netflix Loading Manager
class NetflixLoadingManager {
    
    static let shared = NetflixLoadingManager()
    
    private var loadingSections: [NetflixLoadingSectionView] = []
    private var loadingHero: NetflixLoadingHeroView?
    
    private init() {}
    
    func showLoadingForSections(in container: UIStackView, count: Int) {
        // Remove existing loading views
        hideAllLoading()
        
        // Add loading hero
        let heroLoading = NetflixLoadingHeroView()
        heroLoading.heightAnchor.constraint(equalToConstant: 480).isActive = true
        container.insertArrangedSubview(heroLoading, at: 0)
        loadingHero = heroLoading
        
        // Add loading sections
        for i in 0..<count {
            let loadingSection = NetflixLoadingSectionView()
            loadingSection.heightAnchor.constraint(equalToConstant: 258).isActive = true
            container.insertArrangedSubview(loadingSection, at: i + 1)
            loadingSections.append(loadingSection)
        }
        
        // Animate in
        loadingHero?.fadeIn(duration: 0.3)
        
        for (index, section) in loadingSections.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                section.fadeIn(duration: 0.3)
            }
        }
    }
    
    func hideAllLoading() {
        loadingHero?.hideLoading()
        loadingHero = nil
        
        loadingSections.forEach { $0.hideLoading() }
        loadingSections.removeAll()
    }
}

// MARK: - Netflix Refresh Control
class NetflixRefreshControl: UIRefreshControl {
    
    private let loadingView = NetflixLoadingView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNetflixStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNetflixStyle()
    }
    
    private func setupNetflixStyle() {
        tintColor = UIColor(hex: "#E50914") ?? .red
        
        // Add custom loading view
        loadingView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        loadingView.color = UIColor(hex: "#E50914") ?? .red
        addSubview(loadingView)
        
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 30),
            loadingView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    override func beginRefreshing() {
        super.beginRefreshing()
        loadingView.startAnimating()
    }
    
    override func endRefreshing() {
        super.endRefreshing()
        loadingView.stopAnimating()
    }
}

// MARK: - Netflix Loading View (Custom Spinner)
class NetflixLoadingView: UIView {
    
    private let circleLayer = CAShapeLayer()
    private let animationDuration: TimeInterval = 1.0
    
    var color: UIColor = UIColor(hex: "#E50914") ?? .red {
        didSet {
            circleLayer.strokeColor = color.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLoadingView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLoadingView()
    }
    
    private func setupLoadingView() {
        let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = color.cgColor
        circleLayer.lineWidth = 3
        circleLayer.lineCap = .round
        circleLayer.strokeEnd = 0
        
        layer.addSublayer(circleLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circleLayer.frame = bounds
        
        let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        circleLayer.path = circlePath.cgPath
    }
    
    func startAnimating() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = Float.pi * 2
        rotationAnimation.duration = animationDuration
        rotationAnimation.repeatCount = .infinity
        circleLayer.add(rotationAnimation, forKey: "rotation")
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0
        strokeAnimation.toValue = 1
        strokeAnimation.duration = animationDuration * 0.7
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        strokeAnimation.repeatCount = .infinity
        strokeAnimation.autoreverses = true
        circleLayer.add(strokeAnimation, forKey: "stroke")
    }
    
    func stopAnimating() {
        circleLayer.removeAllAnimations()
    }
}
