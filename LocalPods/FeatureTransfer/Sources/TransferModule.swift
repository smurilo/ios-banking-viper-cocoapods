#if canImport(UIKit)
import UIKit
import BankCore
import BankNetworking
import BankDesignSystem

public enum TransferModule {
    @MainActor
    public static func build(service: TransferServicing) -> UIViewController {
        let view = TransferViewController()
        let router = TransferRouter()
        let presenter = TransferPresenter(interactor: TransferInteractor(service: service), router: router)
        presenter.view = view
        view.presenter = presenter
        router.viewController = view
        return UINavigationController(rootViewController: view)
    }
}

@MainActor
final class TransferRouter: TransferRouterProtocol {
    weak var viewController: UIViewController?

    func showReceipt(_ receipt: PixReceipt) {
        let alert = UIAlertController(title: "Pix enviado ✅",
                                      message: "\(MoneyFormatter.string(from: receipt.amount)) para \(receipt.recipientName)\nID \(receipt.endToEndId)",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Concluir", style: .default) { [weak self] _ in self?.viewController?.dismiss(animated: true) })
        viewController?.present(alert, animated: true)
    }
}

final class TransferViewController: UIViewController, TransferViewProtocol {
    var presenter: TransferPresenter!
    private let keyField = UITextField()
    private let keyInfo = UILabel()
    private let amountField = UITextField()
    private let amountInfo = UILabel()
    private let button = PrimaryButton(title: "Transferir")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pix"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })

        keyField.placeholder = "CPF, CNPJ, e-mail, celular ou chave aleatória"
        amountField.placeholder = "Valor (R$)"
        amountField.keyboardType = .decimalPad
        [keyField, amountField].forEach { $0.borderStyle = .roundedRect }
        [keyInfo, amountInfo].forEach { $0.font = .preferredFont(forTextStyle: .caption1) }
        keyField.addAction(UIAction { [weak self] _ in self?.presenter.keyChanged(self?.keyField.text ?? "") }, for: .editingChanged)
        amountField.addAction(UIAction { [weak self] _ in self?.presenter.amountChanged(self?.amountField.text ?? "") }, for: .editingChanged)
        button.addAction(UIAction { [weak self] _ in Task { await self?.presenter.submit() } }, for: .touchUpInside)
        button.isEnabled = false

        let stack = UIStackView(arrangedSubviews: [keyField, keyInfo, amountField, amountInfo, button])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Theme.spacing),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.spacing),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.spacing),
        ])
    }

    func render(_ form: TransferForm) {
        keyInfo.text = form.keyError ?? form.keyHint.map { "Chave \($0)" }
        keyInfo.textColor = form.keyError == nil ? .secondaryLabel : .systemRed
        amountInfo.text = form.amountError
        amountInfo.textColor = .systemRed
        button.isEnabled = form.canSubmit
    }

    func showSending(_ sending: Bool) { button.isLoading = sending }

    func showError(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
#endif
