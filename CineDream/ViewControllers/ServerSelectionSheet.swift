import UIKit

class ServerSelectionSheet: UIViewController {
    
    var servers: [StreamResult] = []
    var currentServerId: String?
    var serverStatuses: [String: ServerCheckResult] = [:]
    var onServerSelected: ((StreamResult) -> Void)?
    
    private let tableView = UITableView()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Select Server"
        l.font = .boldSystemFont(ofSize: 20)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        b.tintColor = .systemGray
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(tableView)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ServerSelectionCell.self, forCellReuseIdentifier: "ServerSelectionCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    func updateStatuses(_ statuses: [String: ServerCheckResult]) {
        self.serverStatuses = statuses
        self.tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ServerSelectionSheet: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return servers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServerSelectionCell", for: indexPath) as! ServerSelectionCell
        let server = servers[indexPath.row]
        let checkResult = serverStatuses[server.sourceId]
        let isCurrent = server.sourceId == currentServerId
        
        cell.configure(with: server, checkResult: checkResult, isCurrent: isCurrent)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let server = servers[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.onServerSelected?(server)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - Server Selection Cell
class ServerSelectionCell: UITableViewCell {
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let statusIndicator: GlowingIndicatorView = {
        let v = GlowingIndicatorView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let checkmarkImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark")
        iv.tintColor = UIColor(hex: "#E50914")
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    
    private var pulseAnimation: CABasicAnimation?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(statusIndicator)
        contentView.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            statusIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            nameLabel.leadingAnchor.constraint(equalTo: statusIndicator.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with server: StreamResult, checkResult: ServerCheckResult?, isCurrent: Bool) {
        nameLabel.text = server.sourceName
        checkmarkImageView.isHidden = !isCurrent
        
        if let result = checkResult {
            statusIndicator.setStatus(result.status)
        } else {
            statusIndicator.setStatus(.checking)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        statusIndicator.stopPulsing()
    }
}

// MARK: - Glowing Indicator View
class GlowingIndicatorView: UIView {
    
    private let indicatorLayer = CAShapeLayer()
    private let glowLayer = CAShapeLayer()
    private var isPulsing = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        let size: CGFloat = 12
        let rect = CGRect(x: (bounds.width - size) / 2, y: (bounds.height - size) / 2, width: size, height: size)
        let path = UIBezierPath(ovalIn: rect)
        
        indicatorLayer.path = path.cgPath
        indicatorLayer.fillColor = UIColor.systemGray.cgColor
        layer.addSublayer(indicatorLayer)
        
        glowLayer.path = path.cgPath
        glowLayer.fillColor = UIColor.clear.cgColor
        glowLayer.strokeColor = UIColor.systemGray.cgColor
        glowLayer.lineWidth = 2
        glowLayer.opacity = 0.5
        layer.addSublayer(glowLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let size: CGFloat = 12
        let rect = CGRect(x: (bounds.width - size) / 2, y: (bounds.height - size) / 2, width: size, height: size)
        let path = UIBezierPath(ovalIn: rect)
        indicatorLayer.path = path.cgPath
        glowLayer.path = path.cgPath
    }
    
    func setStatus(_ status: ServerQualityStatus) {
        let color = status.color
        indicatorLayer.fillColor = color.cgColor
        glowLayer.strokeColor = color.cgColor
        
        if status == .checking && !isPulsing {
            startPulsing()
        } else {
            stopPulsing()
            if status == .fast || status == .slow {
                // Soft glow for active servers
                glowLayer.opacity = 0.6
                glowLayer.shadowColor = color.cgColor
                glowLayer.shadowRadius = 4
                glowLayer.shadowOpacity = 0.8
                glowLayer.shadowOffset = .zero
            } else {
                glowLayer.opacity = 0
                glowLayer.shadowOpacity = 0
            }
        }
    }
    
    func startPulsing() {
        isPulsing = true
        
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0.3
        pulse.toValue = 0.8
        pulse.duration = 1.0
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 1.3
        scale.duration = 1.0
        scale.autoreverses = true
        scale.repeatCount = .infinity
        
        glowLayer.add(pulse, forKey: "pulse")
        glowLayer.add(scale, forKey: "scale")
    }
    
    func stopPulsing() {
        isPulsing = false
        glowLayer.removeAnimation(forKey: "pulse")
        glowLayer.removeAnimation(forKey: "scale")
    }
}
