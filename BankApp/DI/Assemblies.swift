import UIKit
import Swinject
import BankNetworking
import FeatureStatement
import FeatureTransfer

/// Infrastructure: one HTTP client and one API facade for the whole app.
final class NetworkingAssembly: Assembly {
    func assemble(container: Container) {
        container.register(HTTPClient.self) { _ in
            URLSessionHTTPClient(baseURL: URL(string: "https://api.banco-exemplo.com.br")!,
                                 tokenProvider: { KeychainTokenStore.shared.accessToken })
        }.inObjectScope(.container)

        container.register(BankAPI.self) { r in BankAPI(client: r.resolve(HTTPClient.self)!) }
            .inObjectScope(.container)
        container.register(StatementServicing.self) { r in r.resolve(BankAPI.self)! }
        container.register(TransferServicing.self) { r in r.resolve(BankAPI.self)! }
    }
}

/// Features only receive protocols: swapping the API for a mock (UI tests, previews) is one registration.
final class FeatureAssembly: Assembly {
    func assemble(container: Container) {
        container.register(UIViewController.self, name: "transfer") { r in
            MainActor.assumeIsolated { TransferModule.build(service: r.resolve(TransferServicing.self)!) }
        }
        container.register(UIViewController.self, name: "root") { r in
            MainActor.assumeIsolated {
                var navigation: UINavigationController?
                let statement = StatementModule.build(service: r.resolve(StatementServicing.self)!) {
                    guard let transfer = r.resolve(UIViewController.self, name: "transfer") else { return }
                    navigation?.present(transfer, animated: true)
                }
                navigation = UINavigationController(rootViewController: statement)
                navigation?.navigationBar.prefersLargeTitles = true
                return navigation!
            }
        }
    }
}
