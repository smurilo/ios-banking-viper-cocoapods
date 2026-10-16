import Foundation

/// PIX key types from the Central Bank's DICT, detected from free user input.
public enum PixKey: Equatable, Sendable {
    case cpf(String), cnpj(String), email(String), phone(String), random(String)

    public var value: String {
        switch self {
        case let .cpf(v), let .cnpj(v), let .email(v), let .phone(v), let .random(v): return v
        }
    }

    public var typeName: String {
        switch self {
        case .cpf: return "CPF"
        case .cnpj: return "CNPJ"
        case .email: return "E-mail"
        case .phone: return "Celular"
        case .random: return "Chave aleatória"
        }
    }

    public init?(_ raw: String) {
        let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = input.filter(\.isNumber)
        if input.range(of: #"^[\w.+-]+@[\w-]+(\.[\w-]+)+$"#, options: .regularExpression) != nil {
            self = .email(input.lowercased())
        } else if input.lowercased().range(of: #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#, options: .regularExpression) != nil {
            self = .random(input.lowercased())
        } else if input.hasPrefix("+"), digits.hasPrefix("55"), (12...13).contains(digits.count) {
            self = .phone("+" + digits)
        } else if digits.count == 11, Self.isValidCPF(digits) {
            self = .cpf(digits)
        } else if digits.count == 14, Self.isValidCNPJ(digits) {
            self = .cnpj(digits)
        } else {
            return nil
        }
    }

    static func isValidCPF(_ cpf: String) -> Bool {
        let n = cpf.compactMap(\.wholeNumberValue)
        guard n.count == 11, Set(n).count > 1 else { return false }
        func dv(_ len: Int) -> Int {
            let sum = (0..<len).reduce(0) { $0 + n[$1] * (len + 1 - $1) }
            let r = (sum * 10) % 11
            return r == 10 ? 0 : r
        }
        return dv(9) == n[9] && dv(10) == n[10]
    }

    static func isValidCNPJ(_ cnpj: String) -> Bool {
        let n = cnpj.compactMap(\.wholeNumberValue)
        guard n.count == 14, Set(n).count > 1 else { return false }
        func dv(_ weights: [Int]) -> Int {
            let r = zip(n, weights).reduce(0) { $0 + $1.0 * $1.1 } % 11
            return r < 2 ? 0 : 11 - r
        }
        return dv([5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) == n[12] && dv([6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) == n[13]
    }
}
