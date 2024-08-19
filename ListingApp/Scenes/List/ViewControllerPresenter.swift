//
//  ViewControllerPresenter.swift
//  ListingApp
//
//  Created by Mine Rala on 13.08.2024.
//

import Foundation

protocol ViewControllerPresenterInterface {
    var numberOfRowsInSection: Int { get }
    var heightForRowAt: Int { get }

    func fetchData()
    func refreshData()
    func willDisplay(at indexPath: IndexPath)
    func getPerson(at indexPath: IndexPath) -> Person
}

final class ViewControllerPresenter {
    // MARK: - Attributes
    weak var view: ViewControllerInterface!
    private var nextPageId: String? = nil
    private var data: [Person] = []
    private var isPaginationFinished = false
    private var retryCount = 0
    
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
            view.retryFetchData()
        } else {
            handleError(with: "Error occurred after 3 attempts. Please try again later.")
            view.endRefreshing()
        }
    }
    
    private func handleError(with error: String) {
        view.showToast(error)
        print("\(error)")
    }
}
    
// MARK: - ViewControllerPresenterInterface
extension ViewControllerPresenter: ViewControllerPresenterInterface {
    var numberOfRowsInSection: Int { data.count }
    var heightForRowAt: Int { 50 }
    
    func fetchData() {
        DataSource.fetch(next: nextPageId) { [weak self] response, error in
            guard let self else { return }
            if let error = error {
                self.handleFaliure(error.errorDescription)
                return
            }
            self.retryCount = 0
            if let response {
                self.handleSuccess(with: response.people, nextPage: response.next)
            }
            self.view.reloadTableView()
            self.view.isTableBackgroundViewHidden(data.isEmpty)
            self.view.endRefreshing()
        }
    }
    
    func refreshData() {
        isPaginationFinished = false
        nextPageId = nil
        fetchData()
    }
    
    func willDisplay(at indexPath: IndexPath) {
        if !isPaginationFinished && indexPath.row == data.count - 3 {
            fetchData()
        }
    }
    
    func getPerson(at indexPath: IndexPath) -> Person {
        data[indexPath.row]
    }

}
