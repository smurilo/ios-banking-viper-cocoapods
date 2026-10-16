import Foundation

/// Locale-pinned BRL formatting: the app shows "R$ 1.234,56" regardless of the device language.
public enum MoneyFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "pt_BR")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        f.usesGroupingSeparator = true
        return f
    }()

    public static func string(from value: Decimal) -> String {
        let abs = value < 0 ? -value : value
        let body = formatter.string(from: abs as NSDecimalNumber) ?? "0,00"
        return (value < 0 ? "-R$ " : "R$ ") + body
    }

    /// Accepts "1.234,56", "1234,5" or "1234.56".
    public static func decimal(from input: String) -> Decimal? {
        var clean = input.replacingOccurrences(of: "R$", with: "").trimmingCharacters(in: .whitespaces)
        if clean.contains(",") {
            clean = clean.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        }
        guard !clean.isEmpty, clean.allSatisfy({ $0.isNumber || $0 == "." }),
              clean.filter({ $0 == "." }).count <= 1,
              let value = Decimal(string: clean, locale: Locale(identifier: "en_US_POSIX")) else { return nil }
        var rounded = Decimal()
        var copy = value
        NSDecimalRound(&rounded, &copy, 2, .bankers)
        return rounded
    }
}
