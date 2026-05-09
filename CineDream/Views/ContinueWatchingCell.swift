import UIKit

class ContinueWatchingCell: UICollectionViewCell {
    static let identifier = "ContinueWatchingCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(with item: HistoryItem) {
        titleLabel.text = item.title
        if let path = item.posterPath {
            imageView.loadImage(from: "\(Constants.imageBaseURL)\(path)")
        } else {
            imageView.image = nil
        }
    }
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
                self.layer.shadowColor = self.isHighlighted ? UIColor.black.cgColor : UIColor.clear.cgColor
                self.layer.shadowOpacity = self.isHighlighted ? 0.6 : 0
                self.layer.shadowRadius = self.isHighlighted ? 15 : 0
                self.layer.shadowOffset = CGSize(width: 0, height: 10)
                self.contentView.layer.zPosition = self.isHighlighted ? 10 : 0
            }, completion: nil)
        }
    }
    
    func animateAppearance() {
        self.alpha = 0
        self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.alpha = 1
            self.transform = .identity
        })
    }
}
