import Foundation
import BankCore

// MARK: - VIPER contracts
// View ← Presenter → Interactor → Services, Presenter → Router. Only the View and Router know UIKit.

@MainActor
public protocol StatementViewProtocol: AnyObject {
    func showLoading(_ loading: Bool)
    func show(_ viewModel: StatementViewModel)
    func showError(_ message: String)
}

public protocol StatementInteractorProtocol: Sendable {
    func loadStatement() async throws -> (Account, [Transaction])
}

@MainActor
public protocol StatementRouterProtocol: AnyObject {
    func openTransfer()
    func openDetail(of transaction: Transaction)
}

@MainActor
public protocol StatementPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didPullToRefresh()
    func didSelect(transactionId: String)
    func didTapTransfer()
}

// MARK: - Entities shown by the view (already formatted, no business logic left in the view)

public struct StatementViewModel: Equatable {
    public struct Row: Equatable, Hashable {
        public let id: String
        public let title: String
        public let time: String
        public let amount: String
        public let isCredit: Bool
    }

    public struct Section: Equatable, Hashable {
        public let title: String
        public let rows: [Row]
    }

    public let holder: String
    public let balance: String
    public let sections: [Section]
}
