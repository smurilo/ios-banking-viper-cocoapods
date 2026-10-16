import XCTest
import BankCore
@testable import FeatureTransfer

@MainActor
final class TransferSpyView: TransferViewProtocol {
    var form: TransferForm?
    var errors: [String] = []
    func render(_ form: TransferForm) { self.form = form }
    func showSending(_ sending: Bool) {}
    func showError(_ message: String) { errors.append(message) }
}

@MainActor
final class TransferSpyRouter: TransferRouterProtocol {
    var receipt: PixReceipt?
    func showReceipt(_ receipt: PixReceipt) { self.receipt = receipt }
}

final class FlakyInteractor: TransferInteractorProtocol, @unchecked Sendable {
    var failuresLeft: Int
    var keysUsed: [String] = []
    init(failures: Int) { failuresLeft = failures }

    func send(key: PixKey, amount: Decimal, idempotencyKey: String) async throws -> PixReceipt {
        keysUsed.append(idempotencyKey)
        if failuresLeft > 0 { failuresLeft -= 1; throw URLError(.timedOut) }
        return PixReceipt(endToEndId: "E1", amount: amount, recipientName: "Bruno")
    }
}

@MainActor
final class TransferPresenterTests: XCTestCase {

    func testValidatesKeyAndLimit() async {
        let view = TransferSpyView()
        let presenter = TransferPresenter(interactor: FlakyInteractor(failures: 0), router: TransferSpyRouter())
        presenter.view = view

        presenter.keyChanged("ana@")
        XCTAssertEqual(view.form?.keyError, "Chave Pix inválida")

        presenter.keyChanged("ana@banco.com")
        presenter.amountChanged("1.500,00")
        XCTAssertEqual(view.form?.keyHint, "E-mail")
        XCTAssertEqual(view.form?.amountError, "Acima do limite de R$ 1.000,00")
        XCTAssertEqual(view.form?.canSubmit, false)

        presenter.amountChanged("150,00")
        XCTAssertEqual(view.form?.canSubmit, true)
    }

    func testRetryReusesIdempotencyKey() async {
        let interactor = FlakyInteractor(failures: 1)
        let router = TransferSpyRouter()
        let view = TransferSpyView()
        let presenter = TransferPresenter(interactor: interactor, router: router)
        presenter.view = view
        presenter.keyChanged("529.982.247-25")
        presenter.amountChanged("50")

        await presenter.submit()
        await presenter.submit()

        XCTAssertEqual(view.errors.count, 1)
        XCTAssertEqual(interactor.keysUsed.count, 2)
        XCTAssertEqual(interactor.keysUsed[0], interactor.keysUsed[1])
        XCTAssertEqual(router.receipt?.amount, 50)
    }
}
