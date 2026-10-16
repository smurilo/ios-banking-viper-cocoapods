#if canImport(UIKit)
import UIKit
import BankCore
import BankNetworking
import BankDesignSystem

/// Assembles the VIPER stack. The app's DI container only needs to provide the service.
public enum StatementModule {
    @MainActor
    public static func build(service: StatementServicing, openTransfer: @escaping () -> Void) -> UIViewController {
        let view = StatementViewController()
        let router = StatementRouter(openTransferHandler: openTransfer)
        let presenter = StatementPresenter(interactor: StatementInteractor(service: service), router: router)
        presenter.view = view
        view.presenter = presenter
        router.viewController = view
        return view
    }
}

@MainActor
final class StatementRouter: StatementRouterProtocol {
    weak var viewController: UIViewController?
    private let openTransferHandler: () -> Void

    init(openTransferHandler: @escaping () -> Void) {
        self.openTransferHandler = openTransferHandler
    }

    func openTransfer() { openTransferHandler() }

    func openDetail(of transaction: Transaction) {
        let alert = UIAlertController(title: transaction.title, message: MoneyFormatter.string(from: transaction.amount), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Fechar", style: .cancel))
        viewController?.present(alert, animated: true)
    }
}

final class StatementViewController: UIViewController, StatementViewProtocol, UITableViewDelegate {

    var presenter: StatementPresenterProtocol!
    private let header = BalanceView()
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let refresh = UIRefreshControl()
    private var sections: [StatementViewModel.Section] = []
    private lazy var dataSource = UITableViewDiffableDataSource<StatementViewModel.Section, StatementViewModel.Row>(tableView: table) { table, indexPath, row in
        let cell = table.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        var content = UIListContentConfiguration.valueCell()
        content.text = row.title
        content.secondaryText = row.amount
        content.secondaryTextProperties.color = row.isCredit ? Theme.credit : Theme.debit
        cell.contentConfiguration = content
        cell.accessibilityLabel = "\(row.title), \(row.amount), às \(row.time)"
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Extrato"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Pix", primaryAction: UIAction { [weak self] _ in self?.presenter.didTapTransfer() })
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 120)
        table.tableHeaderView = header
        table.delegate = self
        table.refreshControl = refresh
        refresh.addAction(UIAction { [weak self] _ in self?.presenter.didPullToRefresh() }, for: .valueChanged)
        table.frame = view.bounds
        table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(table)
        presenter.viewDidLoad()
    }

    func showLoading(_ loading: Bool) {
        loading ? refresh.beginRefreshing() : refresh.endRefreshing()
    }

    func show(_ viewModel: StatementViewModel) {
        header.configure(holder: viewModel.holder, balance: viewModel.balance)
        sections = viewModel.sections
        var snapshot = NSDiffableDataSourceSnapshot<StatementViewModel.Section, StatementViewModel.Row>()
        snapshot.appendSections(viewModel.sections)
        viewModel.sections.forEach { snapshot.appendItems($0.rows, toSection: $0) }
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let row = dataSource.itemIdentifier(for: indexPath) { presenter.didSelect(transactionId: row.id) }
    }
}
#endif
