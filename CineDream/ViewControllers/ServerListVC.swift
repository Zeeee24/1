import UIKit

class ServerListVC: UIViewController {
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Server"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Data
    var sources: [StreamResult] = []
    var currentSourceId: String?
    var onSelect: ((StreamResult) -> Void)?
    
    private var serverStatuses: [String: ServerHealthChecker.ServerStatus] = [:]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        checkServerStatuses()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.1, alpha: 1)
        
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ServerCell.self, forCellReuseIdentifier: ServerCell.identifier)
    }
    
    private func checkServerStatuses() {
        for source in sources {
            ServerHealthChecker.shared.checkServerHealth(for: source) { [weak self] status in
                DispatchQueue.main.async {
                    self?.serverStatuses[source.sourceId] = status
                    if let indexPath = self?.getIndexPath(for: source.sourceId) {
                        self?.tableView.reloadRows(at: [indexPath], with: .none)
                    }
                }
            }
        }
    }
    
    private func getIndexPath(for sourceId: String) -> IndexPath? {
        guard let index = sources.firstIndex(where: { $0.sourceId == sourceId }) else { return nil }
        return IndexPath(row: index, section: 0)
    }
}

// MARK: - Table View Data Source
extension ServerListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sources.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ServerCell.identifier, for: indexPath) as! ServerCell
        let source = sources[indexPath.row]
        let status = serverStatuses[source.sourceId] ?? .unknown
        let isCurrent = source.sourceId == currentSourceId
        
        cell.configure(with: source, status: status, isCurrent: isCurrent)
        
        return cell
    }
}

// MARK: - Table View Delegate
extension ServerListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let source = sources[indexPath.row]
        let status = serverStatuses[source.sourceId] ?? .unknown
        
        // Only allow selection of healthy servers
        if status.isHealthy {
            onSelect?(source)
            dismiss(animated: true)
        } else {
            showAlert(title: "Server Unavailable", message: "This server is currently down. Please select a green server.")
        }
    }
}

// MARK: - Server Cell
class ServerCell: UITableViewCell {
    static let identifier = "ServerCell"
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let qualityLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let currentIndicator: UILabel = {
        let label = UILabel()
        label.text = "✓"
        label.textColor = UIColor(hex: "#E50914")
        label.font = .boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor(white: 0.1, alpha: 1)
        selectionStyle = .none
        
        contentView.addSubview(statusLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(qualityLabel)
        contentView.addSubview(currentIndicator)
        
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 20),
            
            nameLabel.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: currentIndicator.leadingAnchor, constant: -12),
            
            qualityLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            qualityLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            qualityLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            currentIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            currentIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            currentIndicator.widthAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with source: StreamResult, status: ServerHealthChecker.ServerStatus, isCurrent: Bool) {
        statusLabel.text = status.color
        nameLabel.text = source.sourceName
        qualityLabel.text = source.quality
        currentIndicator.isHidden = !isCurrent
        
        // Update cell appearance based on status
        if status.isHealthy {
            nameLabel.textColor = .white
            accessoryType = isCurrent ? .checkmark : .disclosureIndicator
        } else {
            nameLabel.textColor = .gray
            accessoryType = .none
        }
    }
}
