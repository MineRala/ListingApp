//
//  ViewController.swift
//  ListingApp
//
//  Created by Mine Rala on 7.05.2024.
//

import UIKit

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
    private var nextPageId: String? = nil
    private var data: [Person] = []
    private var isPaginationFinished = false
    private var retryCount = 0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchData()
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
    
    private func updateUI() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.backgroundView?.isHidden = !self.data.isEmpty
            self.refreshControl.endRefreshing()
        }
    }
}

// MARK: - Data Fetch
extension ViewController {
    private func fetchData() {
        DataSource.fetch(next: nextPageId) { [weak self] response, error in
            guard let self else { return }
            if let error = error {
                self.handleFaliure(error.errorDescription)
                return
            }
            self.retryCount = 0
            if let response = response {
                self.handleSuccess(with: response.people, nextPage: response.next)
            }
            self.updateUI()
        }
    }
    
    private func handleSuccess(with newData: [Person], nextPage: String?) {
        if !newData.isEmpty {
            if !data.isEmpty && nextPageId == nil { // refreshden sonra yeni veriler için önceki data verileri temizlenir
                data.removeAll() // ilk success durumda girmez, data empty olduğu durumlarda tekar removelamasın
            }
            let uniquePersons = newData.filter { person in
                !data.contains(where: { $0.id == person.id })
            }
            data.append(contentsOf: uniquePersons)
            if nextPage == nil { // pagination son sayfaya ulaştıysa
                isPaginationFinished = true
                print("Son sayfaya ulaşıldı.")
            }
        } else if !data.isEmpty { // refreshden sonra empty state olursa
            data.removeAll()
        }
        nextPageId = nextPage
    }
    
    private func handleFaliure(_ error: String) {
        retryCount += 1
        
        if retryCount < 3 {
            let errorMessage = "Error occurred: \(error). Retrying... (\(retryCount)/3)"
            handleError(with: errorMessage)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.fetchData()
            }
        } else {
            handleError(with: "Error occurred after 3 attempts. Please try again later.")
            DispatchQueue.main.async { [weak self] in
                self?.refreshControl.endRefreshing()
            }
        }
    }
    
    private func handleError(with error: String) {
        showToast(message: error)
        print("\(error)")
    }
}

// MARK: - Actions
extension ViewController {
    @objc func refreshData() {
        isPaginationFinished = false
        nextPageId = nil
        fetchData()
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isPaginationFinished && indexPath.row == data.count - 3 {
            fetchData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
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
        cell.setCell(person: data[indexPath.row])
        return cell
    }
}
