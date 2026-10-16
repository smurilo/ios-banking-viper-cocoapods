import XCTest
import BankCore
import BankNetworking
@testable import FeatureStatement

@MainActor
final class SpyView: StatementViewProtocol {
    var loading: [Bool] = []
    var shown: StatementViewModel?
    var error: String?
    func showLoading(_ loading: Bool) { self.loading.append(loading) }
    func show(_ viewModel: StatementViewModel) { shown = viewModel }
    func showError(_ message: String) { error = message }
}

@MainActor
final class SpyRouter: StatementRouterProtocol {
    var openedTransfer = false
    var detail: Transaction?
    func openTransfer() { openedTransfer = true }
    func openDetail(of transaction: Transaction) { detail = transaction }
}

struct StubInteractor: StatementInteractorProtocol {
    var result: Result<(Account, [Transaction]), Error>
    func loadStatement() async throws -> (Account, [Transaction]) { try result.get() }
}

@MainActor
final class StatementPresenterTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return c
    }()

    private func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        f.timeZone = calendar.timeZone
        return f.date(from: s)!
    }

    private let account = Account(id: "1", holder: "Ana", branch: "0001", number: "1-1", balance: Decimal(string: "8432.17")!)

    func testGroupsByDayWithRelativeTitlesAndFormatsMoney() async {
        let txs = [
            Transaction(id: "a", title: "Salário", amount: 7500, kind: .salary, date: date("2026-03-05T08:00:00-03:00")),
            Transaction(id: "b", title: "Mercado", amount: Decimal(string: "-287.43")!, kind: .card, date: date("2026-03-04T19:12:00-03:00")),
            Transaction(id: "c", title: "Luz", amount: -198, kind: .bill, date: date("2026-03-01T09:00:00-03:00")),
        ]
        let view = SpyView()
        let presenter = StatementPresenter(interactor: StubInteractor(result: .success((account, txs))), router: SpyRouter(),
                                           calendar: calendar, now: { self.date("2026-03-05T12:00:00-03:00") })
        presenter.view = view

        await presenter.load()

        XCTAssertEqual(view.loading, [true, false])
        XCTAssertEqual(view.shown?.balance, "R$ 8.432,17")
        XCTAssertEqual(view.shown?.sections.map(\.title).prefix(2), ["Hoje", "Ontem"])
        XCTAssertEqual(view.shown?.sections[1].rows.first?.amount, "-R$ 287,43")
        XCTAssertEqual(view.shown?.sections.count, 3)
    }

    func testOfflineErrorShowsSpecificMessage() async {
        let view = SpyView()
        let presenter = StatementPresenter(interactor: StubInteractor(result: .failure(APIError.offline)), router: SpyRouter())
        presenter.view = view

        await presenter.load()

        XCTAssertEqual(view.error, "Você está sem conexão. Verifique sua internet.")
        XCTAssertEqual(view.loading.last, false)
    }

    func testRoutesSelectionAndTransfer() async {
        let tx = Transaction(id: "x", title: "Pix", amount: 10, kind: .pixIn, date: Date())
        let router = SpyRouter()
        let presenter = StatementPresenter(interactor: StubInteractor(result: .success((account, [tx]))), router: router)
        await presenter.load()

        presenter.didSelect(transactionId: "x")
        presenter.didSelect(transactionId: "unknown")
        presenter.didTapTransfer()

        XCTAssertEqual(router.detail, tx)
        XCTAssertTrue(router.openedTransfer)
    }
}
