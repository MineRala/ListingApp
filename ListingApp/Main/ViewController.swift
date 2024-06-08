//
//  ViewController.swift
//  ListingApp
//
//  Created by Mine Rala on 7.05.2024.
//

import UIKit
import Combine

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
    private var viewModel: ViewModel
    private var cancellables: Set<AnyCancellable> = .init()
    
    // MARK: - Cons & DeCons
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.fetchData()
        addListeners()
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
// MARK: - Listeners
extension ViewController {
    private func addListeners() {
        viewModel.people
            .receive(on: DispatchQueue.main)
            .sink { [weak self] presentations in
                guard let self else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
        
        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self else { return }
                print("Error: \(error)")
                self.showToast(message: error)
            }
            .store(in: &cancellables)
        
        viewModel.shouldShowEmptyView
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShowEmpty in
                guard let self else { return }
                self.tableView.backgroundView?.isHidden = !shouldShowEmpty
            }
            .store(in: &cancellables)
        
        viewModel.shouldRetryFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldRetry in
                guard let self, shouldRetry else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.viewModel.fetchData()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Actions
extension ViewController {
    @objc func refreshData() {
        viewModel.refresh()
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !viewModel.getPaginationFinishedStatus() && indexPath.row == viewModel.people.value.count - 3 {
            viewModel.fetchData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.people.value.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell") as? CustomTableViewCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        cell.setCell(person: viewModel.people.value[indexPath.row])
        return cell
    }
}
