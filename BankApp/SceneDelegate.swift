import UIKit
import Swinject

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let assembler = Assembler([NetworkingAssembly(), FeatureAssembly()])
    private var privacyCover: UIView?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = assembler.resolver.resolve(UIViewController.self, name: "root")
        window.makeKeyAndVisible()
        self.window = window
    }

    /// Hides balances in the app switcher snapshot.
    func sceneWillResignActive(_ scene: UIScene) {
        let cover = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        cover.frame = window?.bounds ?? .zero
        window?.addSubview(cover)
        privacyCover = cover
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        privacyCover?.removeFromSuperview()
    }
}
