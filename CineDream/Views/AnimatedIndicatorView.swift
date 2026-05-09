import UIKit

class AnimatedIndicatorView: UIView {
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let progressView = UIProgressView()
    private let percentageLabel = UILabel()
    private let barsStackView = UIStackView()
    
    private var isVolumeIndicator: Bool = true
    
    init(isVolume: Bool) {
        self.isVolumeIndicator = isVolume
        super.init(frame: CGRect(x: 0, y: 0, width: 150, height: 80))
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.05)
        layer.cornerRadius = 12
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Container for content
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon view (animated)
        iconImageView.tintColor = isVolumeIndicator ? UIColor.systemBlue : UIColor.systemYellow
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: isVolumeIndicator ? "speaker.wave.3.fill" : "sun.max.fill")
        
        // Progress bar
        progressView.progressTintColor = isVolumeIndicator ? UIColor.systemBlue : UIColor.systemYellow
        progressView.trackTintColor = UIColor.darkGray
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        // Percentage label
        percentageLabel.textColor = .white
        percentageLabel.font = .boldSystemFont(ofSize: 14)
        percentageLabel.textAlignment = .center
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Audio bars for volume
        if isVolumeIndicator {
            setupAudioBars()
            containerView.addSubview(barsStackView)
        }
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(progressView)
        containerView.addSubview(percentageLabel)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),
            
            progressView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            percentageLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            percentageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            percentageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        if isVolumeIndicator {
            NSLayoutConstraint.activate([
                barsStackView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
                barsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                barsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                barsStackView.heightAnchor.constraint(equalToConstant: 20)
            ])
        }
    }
    
    private func setupAudioBars() {
        barsStackView.axis = .horizontal
        barsStackView.distribution = .fillEqually
        barsStackView.spacing = 3
        
        for _ in 0..<5 {
            let bar = UIView()
            bar.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
            bar.layer.cornerRadius = 2
            bar.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                bar.widthAnchor.constraint(equalToConstant: 4),
                bar.heightAnchor.constraint(equalToConstant: 20)
            ])
            
            barsStackView.addArrangedSubview(bar)
        }
    }
    
    func updateValue(_ value: Float) {
        let percentage = Int(value * 100)
        percentageLabel.text = "\(percentage)%"
        progressView.progress = value
        
        if isVolumeIndicator {
            updateAudioBars(value: value)
            animateVolumeIcon(value: value)
        } else {
            animateBrightnessIcon(value: value)
        }
    }
    
    private func updateAudioBars(value: Float) {
        let activeBars = Int(value * 5)
        for (index, bar) in barsStackView.arrangedSubviews.enumerated() {
            let targetHeight: CGFloat = index < activeBars ? 20 : 8
            let targetAlpha: CGFloat = index < activeBars ? 1.0 : 0.3
            
            UIView.animate(withDuration: 0.2, delay: Double(index) * 0.05, options: .curveEaseOut) {
                bar.transform = CGAffineTransform(scaleX: 1.0, y: targetHeight / 20)
                bar.alpha = targetAlpha
            }
        }
    }
    
    private func animateVolumeIcon(value: Float) {
        let scale: CGFloat = 0.9 + (CGFloat(value) * 0.2)
        
        var iconName = "speaker.slash.fill"
        if value > 0 { iconName = "speaker.wave.1.fill" }
        if value > 0.3 { iconName = "speaker.wave.2.fill" }
        if value > 0.7 { iconName = "speaker.wave.3.fill" }
        
        UIView.animate(withDuration: 0.15, animations: {
            self.iconImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { _ in
            self.iconImageView.image = UIImage(systemName: iconName)
        }
    }
    
    private func animateBrightnessIcon(value: Float) {
        let scale: CGFloat = 0.9 + (CGFloat(value) * 0.2)
        let brightness: CGFloat = 0.5 + (CGFloat(value) * 0.5)
        
        UIView.animate(withDuration: 0.15, animations: {
            self.iconImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.iconImageView.tintColor = UIColor.systemYellow.withAlphaComponent(brightness)
        })
    }
    
    func show() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            self.alpha = 1
            self.transform = .identity
        }, completion: nil)
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
}

// MARK: - Indicator Manager
class IndicatorManager {
    
    static let shared = IndicatorManager()
    
    private var currentVolumeIndicator: AnimatedIndicatorView?
    private var currentBrightnessIndicator: AnimatedIndicatorView?
    
    private init() {}
    
    func showVolumeIndicator(value: Float, in view: UIView) {
        if let indicator = currentVolumeIndicator {
            indicator.updateValue(value)
            return
        }
        
        // Create new indicator
        let indicator = AnimatedIndicatorView(isVolume: true)
        indicator.updateValue(value)
        
        // Position on left side
        indicator.center = CGPoint(x: 80, y: view.bounds.height / 2)
        view.addSubview(indicator)
        
        currentVolumeIndicator = indicator
        indicator.show()
    }
    
    func showBrightnessIndicator(value: Float, in view: UIView) {
        if let indicator = currentBrightnessIndicator {
            indicator.updateValue(value)
            return
        }
        
        // Create new indicator
        let indicator = AnimatedIndicatorView(isVolume: false)
        indicator.updateValue(value)
        
        // Position on right side
        indicator.center = CGPoint(x: view.bounds.width - 80, y: view.bounds.height / 2)
        view.addSubview(indicator)
        
        currentBrightnessIndicator = indicator
        indicator.show()
    }
    
    func hideAllIndicators() {
        currentVolumeIndicator?.hide()
        currentVolumeIndicator = nil
        currentBrightnessIndicator?.hide()
        currentBrightnessIndicator = nil
    }
}
