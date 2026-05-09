import UIKit

class UserProfilesVC: BaseViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profilesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 140)
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 30
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(ProfileCell.self, forCellWithReuseIdentifier: ProfileCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let addProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ Add Profile", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 0.2, alpha: 1)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addNetflixTouchEffect()
        return button
    }()
    
    private let manageProfilesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Manage Profiles", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 0.2, alpha: 1)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addNetflixTouchEffect()
        return button
    }()
    
    // MARK: - Data
    private var profiles: [AppUserProfile] = []
    private var currentProfileId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Who's Watching?"
        setupUI()
        loadProfiles()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(profilesCollectionView)
        contentView.addSubview(addProfileButton)
        contentView.addSubview(manageProfilesButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            profilesCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            profilesCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            profilesCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            profilesCollectionView.heightAnchor.constraint(equalToConstant: 320),
            
            addProfileButton.topAnchor.constraint(equalTo: profilesCollectionView.bottomAnchor, constant: 30),
            addProfileButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            addProfileButton.widthAnchor.constraint(equalToConstant: 200),
            addProfileButton.heightAnchor.constraint(equalToConstant: 50),
            
            manageProfilesButton.topAnchor.constraint(equalTo: addProfileButton.bottomAnchor, constant: 20),
            manageProfilesButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            manageProfilesButton.widthAnchor.constraint(equalToConstant: 200),
            manageProfilesButton.heightAnchor.constraint(equalToConstant: 50),
            manageProfilesButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
        
        profilesCollectionView.dataSource = self
        profilesCollectionView.delegate = self
        
        addProfileButton.addTarget(self, action: #selector(addProfileTapped), for: .touchUpInside)
        manageProfilesButton.addTarget(self, action: #selector(manageProfilesTapped), for: .touchUpInside)
    }
    
    private func loadProfiles() {
        // Load profiles from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "userProfiles"),
           let savedProfiles = try? JSONDecoder().decode([AppUserProfile].self, from: data) {
            profiles = savedProfiles
        } else {
            // Create default profiles
            profiles = [
                AppUserProfile(id: "main", name: "Main Profile", avatar: "person.crop.circle.fill", color: "#E50914", isKids: false, isCurrent: true),
                AppUserProfile(id: "kids", name: "Kids", avatar: "star.fill", color: "#00A8E1", isKids: true, isCurrent: false),
                AppUserProfile(id: "guest", name: "Guest", avatar: "person.crop.circle", color: "#888888", isKids: false, isCurrent: false)
            ]
            saveProfiles()
        }
        
        currentProfileId = UserDefaults.standard.string(forKey: "currentProfileId")
        profilesCollectionView.reloadData()
    }
    
    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: "userProfiles")
        }
    }
    
    @objc private func addProfileTapped() {
        let alert = UIAlertController(title: "Add Profile", message: "Enter a name for the new profile", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Profile Name"
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self?.createProfile(name: name)
        }
        
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func manageProfilesTapped() {
        let manageVC = ManageProfilesVC()
        manageVC.profiles = profiles
        manageVC.onProfilesUpdated = { [weak self] (updatedProfiles: [AppUserProfile]) in
            self?.profiles = updatedProfiles
            self?.saveProfiles()
            self?.profilesCollectionView.reloadData()
        }
        
        let navController = UINavigationController(rootViewController: manageVC)
        present(navController, animated: true)
    }
    
    private func createProfile(name: String) {
        let colors = ["#E50914", "#00A8E1", "#50C878", "#FFB347", "#9B59B6", "#E67E22"]
        let avatars = ["person.crop.circle.fill", "star.fill", "heart.fill", "bolt.fill", "leaf.fill", "flame.fill"]
        
        let randomColor = colors.randomElement() ?? "#E50914"
        let randomAvatar = avatars.randomElement() ?? "person.crop.circle.fill"
        
        let newProfile = AppUserProfile(
            id: UUID().uuidString,
            name: name,
            avatar: randomAvatar,
            color: randomColor,
            isKids: false,
            isCurrent: false
        )
        
        profiles.append(newProfile)
        saveProfiles()
        profilesCollectionView.reloadData()
        
        // Animate new profile
        let indexPath = IndexPath(item: profiles.count - 1, section: 0)
        profilesCollectionView.insertItems(at: [indexPath])
    }
    
    private func selectProfile(_ profile: AppUserProfile) {
        // Update current profile
        profiles.indices.forEach { profiles[$0].isCurrent = false }
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index].isCurrent = true
        }
        
        currentProfileId = profile.id
        UserDefaults.standard.set(profile.id, forKey: "currentProfileId")
        saveProfiles()
        
        // Navigate to home with selected profile
        if let tabBarController = presentingViewController as? UITabBarController {
            tabBarController.dismiss(animated: true) {
                // Post notification that profile changed
                NotificationCenter.default.post(name: .profileDidChange, object: profile)
            }
        }
    }
}

// MARK: - Collection View Data Source
extension UserProfilesVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return profiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileCell.identifier, for: indexPath) as! ProfileCell
        
        let profile = profiles[indexPath.row]
        cell.configure(with: profile)
        
        return cell
    }
}

// MARK: - Collection View Delegate
extension UserProfilesVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let profile = profiles[indexPath.row]
        selectProfile(profile)
    }
}

// MARK: - Profile Cell
class ProfileCell: UICollectionViewCell {
    static let identifier = "ProfileCell"
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let lockIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "lock.fill"))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addNetflixHoverEffect()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        addNetflixHoverEffect()
    }
    
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(lockIcon)
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            lockIcon.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: -4),
            lockIcon.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: -4),
            lockIcon.widthAnchor.constraint(equalToConstant: 16),
            lockIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    func configure(with profile: AppUserProfile) {
        nameLabel.text = profile.name
        avatarImageView.image = UIImage(systemName: profile.avatar)
        
        // Set background color
        contentView.backgroundColor = UIColor(hex: profile.color)
        contentView.layer.cornerRadius = 8
        
        // Show lock icon for kids profiles
        lockIcon.isHidden = !profile.isKids
        
        // Highlight current profile
        if profile.isCurrent {
            contentView.layer.borderWidth = 3
            contentView.layer.borderColor = UIColor.white.cgColor
        } else {
            contentView.layer.borderWidth = 0
        }
    }
}

// MARK: - Manage Profiles View Controller
class ManageProfilesVC: BaseViewController {
    
    var profiles: [AppUserProfile] = []
    var onProfilesUpdated: (([AppUserProfile]) -> Void)?
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Manage Profiles"
        setupUI()
        setupNavigationBar()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ManageProfileCell.self, forCellReuseIdentifier: ManageProfileCell.identifier)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }
    
    @objc private func doneTapped() {
        onProfilesUpdated?(profiles)
        dismiss(animated: true)
    }
}

extension ManageProfilesVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ManageProfileCell.identifier, for: indexPath) as! ManageProfileCell
        
        let profile = profiles[indexPath.row]
        cell.configure(with: profile)
        
        cell.onEditTapped = { [weak self] in
            self?.editProfile(profile)
        }
        
        cell.onDeleteTapped = { [weak self] in
            self?.deleteProfile(profile)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    private func editProfile(_ profile: AppUserProfile) {
        let alert = UIAlertController(title: "Edit Profile", message: "Enter a new name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = profile.name
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self?.updateProfile(profile, name: name)
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func updateProfile(_ profile: AppUserProfile, name: String) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = AppUserProfile(
                id: profile.id,
                name: name,
                avatar: profile.avatar,
                color: profile.color,
                isKids: profile.isKids,
                isCurrent: profile.isCurrent
            )
            tableView.reloadData()
        }
    }
    
    private func deleteProfile(_ profile: AppUserProfile) {
        guard profiles.count > 1 else {
            showAlert(title: "Cannot Delete", message: "You must have at least one profile")
            return
        }
        
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }
}

// MARK: - Manage Profile Cell
class ManageProfileCell: UITableViewCell {
    static let identifier = "ManageProfileCell"
    
    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "trash"), for: .normal)
        button.tintColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        backgroundColor = .black
        selectionStyle = .none
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(editButton)
        contentView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            editButton.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -16),
            editButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 30),
            editButton.heightAnchor.constraint(equalToConstant: 30),
            
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 30),
            deleteButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }
    
    @objc private func editTapped() {
        onEditTapped?()
    }
    
    @objc private func deleteTapped() {
        onDeleteTapped?()
    }
    
    func configure(with profile: AppUserProfile) {
        nameLabel.text = profile.name
        avatarImageView.image = UIImage(systemName: profile.avatar)
        avatarImageView.backgroundColor = UIColor(hex: profile.color)
        avatarImageView.layer.cornerRadius = 20
    }
}

// MARK: - User Profile Model
struct AppUserProfile: Codable {
    let id: String
    var name: String
    let avatar: String
    let color: String
    let isKids: Bool
    var isCurrent: Bool
}

// MARK: - Notification Extension
extension Notification.Name {
    static let profileDidChange = Notification.Name("profileDidChange")
}
