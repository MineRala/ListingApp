//
//  ViewController.swift
//  ListingApp
//
//  Created by Mine Rala on 7.05.2024.
//

import UIKit

protocol ViewControllerInterface: AnyObject {
    func retryFetchData()
    func reloadTableView()
    func isTableBackgroundViewHidden(_ isEmptyData : Bool)
    func endRefreshing()
    func showToast(_ message: String)
}

// MARK: - Class Bone
final class ViewController: UIViewController {
    // MARK: Properties
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "CustomTableViewCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        refreshControl.translatesAutoresizingMaskIntoConstraints = false
        return refreshControl
    }()
    
    private lazy var emptyListView: UIView = {
        let emptyView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        let messageLabel = UILabel()
        messageLabel.text = "No one here :)"
        messageLabel.font = UIFont(name: "Montserrat-Light", size: 12)
        messageLabel.textColor = .gray
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(messageLabel)
        messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
        return emptyView
    }()
    
    // MARK: - Attributes
    private let presenter: ViewControllerPresenter!
    
    init(presenter: ViewControllerPresenter! = ViewControllerPresenter()) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.view = self
        setupUI()
        presenter.fetchData()
    }
}

// MARK: - UI
extension ViewController {
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            tableView.widthAnchor.constraint(equalTo: view.widthAnchor),
            tableView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        tableView.refreshControl = refreshControl
        tableView.backgroundView = emptyListView
        tableView.backgroundView?.isHidden = true
    }
}

// MARK: - Actions
extension ViewController {
    @objc private func refreshData() {
        presenter.refreshData()
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        presenter.willDisplay(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.numberOfRowsInSection
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        CGFloat(presenter.heightForRowAt)
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell") as? CustomTableViewCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        cell.setCell(person: presenter.getPerson(at: indexPath))
        return cell
    }
}

// MARK: - ViewControllerInterface
extension ViewController: ViewControllerInterface {
    func retryFetchData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.presenter.fetchData()
        }
    }
    
    func reloadTableView() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func isTableBackgroundViewHidden(_ isEmptyData : Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.backgroundView?.isHidden = !isEmptyData
        }
    }
    
    func endRefreshing() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
    
    func showToast(_ message: String) {
        showToast(message: message)
    }
}
