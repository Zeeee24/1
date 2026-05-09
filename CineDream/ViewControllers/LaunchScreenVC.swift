import UIKit

class LaunchScreenVC: UIViewController {
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "CineDream"
        if let descriptor = UIFont.systemFont(ofSize: 48, weight: .black).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 48)
        } else {
            label.font = .boldSystemFont(ofSize: 48)
        }
        label.textColor = UIColor(hex: "#E50914")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0
        return label
    }()
    
    private let playIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .black)
        iv.image = UIImage(systemName: "play.fill", withConfiguration: config)
        iv.tintColor = UIColor(hex: "#E50914")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.alpha = 0
        return iv
    }()
    
    private var emitter: CAEmitterLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupParticles()
    }
    
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(logoLabel)
        containerView.addSubview(playIcon)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            logoLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 20),
            
            playIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            playIcon.bottomAnchor.constraint(equalTo: logoLabel.topAnchor, constant: -10)
        ])
    }
    
    private func setupParticles() {
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        emitterLayer.emitterSize = CGSize(width: view.bounds.width, height: view.bounds.height)
        emitterLayer.emitterShape = .rectangle
        
        let cell = CAEmitterCell()
        cell.birthRate = 3
        cell.lifetime = 10.0
        cell.velocity = 15
        cell.velocityRange = 10
        cell.emissionRange = .pi * 2
        cell.spin = 0.5
        cell.spinRange = 0.2
        cell.scale = 0.05
        cell.scaleRange = 0.03
        cell.alphaSpeed = -0.1
        
        // Create a small red circle for the particle
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor(hex: "#E50914")!.withAlphaComponent(0.6).cgColor)
        context.setShadow(offset: .zero, blur: 5, color: UIColor(hex: "#E50914")!.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        cell.contents = image?.cgImage
        
        emitterLayer.emitterCells = [cell]
        view.layer.insertSublayer(emitterLayer, at: 0)
        self.emitter = emitterLayer
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate fade in
        UIView.animate(withDuration: 1.5, delay: 0.5, options: .curveEaseInOut, animations: {
            self.logoLabel.alpha = 1
            self.playIcon.alpha = 1
        }) { _ in
            // Wait then transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showInitialScreen()
            }
        }
    }
    
    private func showInitialScreen() {
        let tabBar = MainTabBarController()
        tabBar.modalPresentationStyle = .fullScreen
        tabBar.modalTransitionStyle = .crossDissolve
        present(tabBar, animated: true)
    }
}
