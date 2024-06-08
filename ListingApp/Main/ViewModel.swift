//
//  ViewModel.swift
//  ListingApp
//
//  Created by Mine Rala on 6.06.2024.
//

import Foundation
import Combine

// MARK: - Class Bone
final class ViewModel {
    private var nextPageId: String? = nil
    private var isPaginationFinished = false
    private var retryCount = 0
    private var fetchLock = false
    
    private(set) var people = CurrentValueSubject<[Model], Never>([])
    private(set) var error = PassthroughSubject<String, Never>()
    private(set) var shouldShowEmptyView = CurrentValueSubject<Bool, Never>(false)
    private(set) var shouldRetryFetch = CurrentValueSubject<Bool, Never>(false)
    
}

// MARK: - Public
extension ViewModel {
    public func fetchData() {
        guard fetchLock == false else { return }
        fetchLock = true
        DataSource.fetch(next: nextPageId) { [weak self] response, error in
            guard let self else { return }
            self.fetchLock = false
            self.shouldRetryFetch.send(false)
            if let error {
                self.handleFaliure(error.errorDescription)
                return
            }
            self.retryCount = 0
            if let response {
                self.handleSuccess(with: response)
            }
        }
    }
    
    public func refresh() {
        isPaginationFinished = false
        nextPageId = nil
        fetchData()
    }
    
    public func getPaginationFinishedStatus() -> Bool {
        return isPaginationFinished
    }
}


// MARK: - Private
extension ViewModel {
    private func handleSuccess(with response: FetchResponse) {
        var mockPeople = people.value
        if !response.people.isEmpty {
            if !mockPeople.isEmpty && nextPageId == nil { // refreshden sonra yeni veriler için önceki data verileri temizlenir
                mockPeople.removeAll() // ilk success durumda girmez, data empty olduğu durumlarda tekar removelamasın
            }
            let uniquePersons = response.people
                .filter { person in
                    !mockPeople.contains(where: { $0.id == String(person.id) })
                }
                .map { person in
                    Model(id: String(person.id), name: person.fullName)
                }
            mockPeople.append(contentsOf: uniquePersons)
            if response.next == nil { // pagination son sayfaya ulaştıysa
                isPaginationFinished = true
                print("Son sayfaya ulaşıldı.")
            }
        } else if !mockPeople.isEmpty { // refreshden sonra empty state olursa
            mockPeople.removeAll()
        }
        shouldShowEmptyView.send(mockPeople.isEmpty)
        people.send(mockPeople)
        nextPageId = response.next
    }
    
    private func handleFaliure(_ error: String) {
        retryCount += 1
        
        if retryCount < 3 {
            let errorMessage = "Error occurred: \(error). Retrying... (\(retryCount)/3)"
            handleError(with: errorMessage)
            shouldRetryFetch.send(true)
        } else {
            handleError(with: "Error occurred after 3 attempts. Please try again later.")
        }
    }
    
    private func handleError(with error: String) {
        self.error.send(error)
        print("\(error)")
    }
}
