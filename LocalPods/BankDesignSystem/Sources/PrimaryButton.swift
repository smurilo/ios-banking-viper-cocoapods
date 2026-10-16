#if canImport(UIKit)
import UIKit

public final class PrimaryButton: UIButton {

    public var isLoading = false {
        didSet {
            isEnabled = !isLoading
            configuration?.showsActivityIndicator = isLoading
        }
    }

    public convenience init(title: String) {
        self.init(configuration: .filled())
        configuration?.title = title
        configuration?.baseBackgroundColor = Theme.primary
        configuration?.cornerStyle = .large
        heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
    }
}
#endif
