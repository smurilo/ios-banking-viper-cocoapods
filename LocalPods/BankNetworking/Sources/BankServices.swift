import Foundation
import BankCore

public protocol StatementServicing: Sendable {
    func account() async throws -> Account
    func transactions() async throws -> [Transaction]
}

public protocol TransferServicing: Sendable {
    func pix(key: PixKey, amount: Decimal, idempotencyKey: String) async throws -> PixReceipt
}

struct AccountDTO: Codable {
    let id, holder, branch, number, balance: String
}

struct TransactionDTO: Codable {
    let id, description, amount, type, dateTime: String
}

struct PixRequestDTO: Codable {
    let key, keyType, amount: String
}

struct PixReceiptDTO: Codable {
    let endToEndId, amount, recipientName: String
}

public final class BankAPI: StatementServicing, TransferServicing {
    private let client: HTTPClient
    private let decoder = JSONDecoder()
    private static let dateParser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    public init(client: HTTPClient) {
        self.client = client
    }

    public func account() async throws -> Account {
        let dto: AccountDTO = try await get("v1/account")
        return Account(id: dto.id, holder: dto.holder, branch: dto.branch, number: dto.number, balance: try decimal(dto.balance))
    }

    public func transactions() async throws -> [Transaction] {
        let dtos: [TransactionDTO] = try await get("v1/transactions")
        return try dtos.map { dto in
            guard let date = Self.dateParser.date(from: dto.dateTime) else { throw APIError.decoding }
            return Transaction(id: dto.id, title: dto.description, amount: try decimal(dto.amount),
                               kind: TransactionKind(rawValue: dto.type) ?? .card, date: date)
        }
    }

    public func pix(key: PixKey, amount: Decimal, idempotencyKey: String) async throws -> PixReceipt {
        let body = try JSONEncoder().encode(PixRequestDTO(key: key.value, keyType: key.typeName, amount: "\(amount)"))
        let data = try await client.send(Endpoint(path: "v1/pix/transfers", method: .post, body: body,
                                                  headers: ["Idempotency-Key": idempotencyKey]))
        let dto = try decode(PixReceiptDTO.self, data)
        return PixReceipt(endToEndId: dto.endToEndId, amount: try decimal(dto.amount), recipientName: dto.recipientName)
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try decode(T.self, try await client.send(Endpoint(path: path)))
    }

    private func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        do { return try decoder.decode(type, from: data) } catch { throw APIError.decoding }
    }

    /// Money travels as strings so no precision is lost in JSON doubles.
    private func decimal(_ s: String) throws -> Decimal {
        guard let d = Decimal(string: s, locale: Locale(identifier: "en_US_POSIX")) else { throw APIError.decoding }
        return d
    }
}
