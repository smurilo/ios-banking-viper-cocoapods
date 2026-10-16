import Foundation
import BankCore
import BankNetworking

@MainActor
public final class StatementPresenter: StatementPresenterProtocol {

    public weak var view: StatementViewProtocol?
    private let interactor: StatementInteractorProtocol
    private let router: StatementRouterProtocol
    private let calendar: Calendar
    private let now: () -> Date
    private var transactions: [Transaction] = []
    private var loadTask: Task<Void, Never>?

    public init(interactor: StatementInteractorProtocol, router: StatementRouterProtocol,
                calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.interactor = interactor
        self.router = router
        self.calendar = calendar
        self.now = now
    }

    public func viewDidLoad() { reload() }
    public func didPullToRefresh() { reload() }

    public func didSelect(transactionId: String) {
        guard let transaction = transactions.first(where: { $0.id == transactionId }) else { return }
        router.openDetail(of: transaction)
    }

    public func didTapTransfer() { router.openTransfer() }

    private func reload() {
        loadTask?.cancel() // a new pull-to-refresh supersedes an in-flight request
        loadTask = Task { await load() }
    }

    /// Exposed for tests; the view triggers it through `viewDidLoad`/`didPullToRefresh`.
    public func load() async {
        view?.showLoading(true)
        defer { view?.showLoading(false) }
        do {
            let (account, transactions) = try await interactor.loadStatement()
            guard !Task.isCancelled else { return }
            self.transactions = transactions
            view?.show(makeViewModel(account: account, transactions: transactions))
        } catch APIError.offline {
            view?.showError("Você está sem conexão. Verifique sua internet.")
        } catch {
            view?.showError("Não foi possível carregar seu extrato.")
        }
    }

    func makeViewModel(account: Account, transactions: [Transaction]) -> StatementViewModel {
        let time = DateFormatter()
        time.dateFormat = "HH:mm"
        time.timeZone = calendar.timeZone
        let day = DateFormatter()
        day.locale = Locale(identifier: "pt_BR")
        day.dateFormat = "EEEE, d 'de' MMMM"
        day.timeZone = calendar.timeZone

        let grouped = Dictionary(grouping: transactions) { calendar.startOfDay(for: $0.date) }
        let sections = grouped.keys.sorted(by: >).map { date -> StatementViewModel.Section in
            let title: String
            if calendar.isDate(date, inSameDayAs: now()) {
                title = "Hoje"
            } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now()), calendar.isDate(date, inSameDayAs: yesterday) {
                title = "Ontem"
            } else {
                title = day.string(from: date).capitalized(with: Locale(identifier: "pt_BR"))
            }
            let rows = grouped[date, default: []].map {
                StatementViewModel.Row(id: $0.id, title: $0.title, time: time.string(from: $0.date),
                                       amount: MoneyFormatter.string(from: $0.amount), isCredit: $0.isCredit)
            }
            return .init(title: title, rows: rows)
        }
        return StatementViewModel(holder: account.holder, balance: MoneyFormatter.string(from: account.balance), sections: sections)
    }
}
