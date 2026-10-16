import Foundation
import BankCore
import BankNetworking

public struct TransferForm: Equatable {
    public var keyHint: String?
    public var keyError: String?
    public var amountError: String?
    public var canSubmit: Bool
}

@MainActor
public protocol TransferViewProtocol: AnyObject {
    func render(_ form: TransferForm)
    func showSending(_ sending: Bool)
    func showError(_ message: String)
}

@MainActor
public protocol TransferRouterProtocol: AnyObject {
    func showReceipt(_ receipt: PixReceipt)
}

public protocol TransferInteractorProtocol: Sendable {
    func send(key: PixKey, amount: Decimal, idempotencyKey: String) async throws -> PixReceipt
}

public final class TransferInteractor: TransferInteractorProtocol {
    private let service: TransferServicing
    public init(service: TransferServicing) { self.service = service }
    public func send(key: PixKey, amount: Decimal, idempotencyKey: String) async throws -> PixReceipt {
        try await service.pix(key: key, amount: amount, idempotencyKey: idempotencyKey)
    }
}

@MainActor
public final class TransferPresenter {

    public static let limit = Decimal(1000)

    public weak var view: TransferViewProtocol?
    private let interactor: TransferInteractorProtocol
    private let router: TransferRouterProtocol
    private var key: PixKey?
    private var amount: Decimal?
    private var keyInput = ""
    private var amountInput = ""
    private var sending = false
    /// Kept across retries so a timeout followed by "try again" never sends money twice.
    private var idempotencyKey = UUID().uuidString

    public init(interactor: TransferInteractorProtocol, router: TransferRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }

    public func keyChanged(_ text: String) {
        keyInput = text
        key = PixKey(text)
        render()
    }

    public func amountChanged(_ text: String) {
        amountInput = text
        amount = MoneyFormatter.decimal(from: text)
        render()
    }

    public func submit() async {
        guard !sending, let key, let amount, validate().canSubmit else { return }
        sending = true
        view?.showSending(true)
        defer {
            sending = false
            view?.showSending(false)
        }
        do {
            let receipt = try await interactor.send(key: key, amount: amount, idempotencyKey: idempotencyKey)
            idempotencyKey = UUID().uuidString
            router.showReceipt(receipt)
        } catch {
            view?.showError("Não foi possível concluir o Pix. Tente novamente.")
        }
    }

    private func render() { view?.render(validate()) }

    func validate() -> TransferForm {
        let keyError = !keyInput.isEmpty && key == nil ? "Chave Pix inválida" : nil
        let amountError: String?
        switch amount {
        case nil where !amountInput.isEmpty: amountError = "Valor inválido"
        case let value? where value <= 0: amountError = "Valor inválido"
        case let value? where value > Self.limit: amountError = "Acima do limite de \(MoneyFormatter.string(from: Self.limit))"
        default: amountError = nil
        }
        return TransferForm(keyHint: key?.typeName, keyError: keyError, amountError: amountError,
                            canSubmit: key != nil && amount != nil && amountError == nil)
    }
}
