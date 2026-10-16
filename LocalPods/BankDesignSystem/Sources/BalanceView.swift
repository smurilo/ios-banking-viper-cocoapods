#if canImport(UIKit)
import UIKit

/// Reusable balance header with a "hide values" toggle, common in Brazilian banking apps.
public final class BalanceView: UIView {

    private let greeting = UILabel()
    private let amount = UILabel()
    private let toggle = UIButton(type: .system)
    private var hidden = false { didSet { render() } }
    private var formattedBalance = ""

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func configure(holder: String, balance: String) {
        greeting.text = "Olá, \(holder)"
        formattedBalance = balance
        render()
    }

    private func setUp() {
        backgroundColor = Theme.primary
        layer.cornerRadius = 16
        greeting.textColor = .white
        greeting.font = .preferredFont(forTextStyle: .subheadline)
        amount.textColor = .white
        amount.font = .monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        amount.adjustsFontForContentSizeCategory = true
        toggle.tintColor = .white
        toggle.addAction(UIAction { [weak self] _ in self?.hidden.toggle() }, for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [amount, toggle])
        let stack = UIStackView(arrangedSubviews: [greeting, row])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Theme.spacing),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.spacing),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.spacing),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Theme.spacing),
        ])
    }

    private func render() {
        amount.text = hidden ? "R$ ••••••" : formattedBalance
        amount.accessibilityLabel = hidden ? "Saldo oculto" : "Saldo \(formattedBalance)"
        toggle.setImage(UIImage(systemName: hidden ? "eye" : "eye.slash"), for: .normal)
        toggle.accessibilityLabel = hidden ? "Mostrar saldo" : "Ocultar saldo"
    }
}
#endif
