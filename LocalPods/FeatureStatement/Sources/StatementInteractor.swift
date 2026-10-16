import Foundation
import BankCore
import BankNetworking

public final class StatementInteractor: StatementInteractorProtocol {
    private let service: StatementServicing

    public init(service: StatementServicing) {
        self.service = service
    }

    /// Account and transactions are fetched concurrently.
    public func loadStatement() async throws -> (Account, [Transaction]) {
        async let account = service.account()
        async let transactions = service.transactions()
        return try await (account, transactions.sorted { $0.date > $1.date })
    }
}
