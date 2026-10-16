import Foundation

public struct Account: Equatable, Sendable {
    public let id: String
    public let holder: String
    public let branch: String
    public let number: String
    public let balance: Decimal

    public init(id: String, holder: String, branch: String, number: String, balance: Decimal) {
        self.id = id
        self.holder = holder
        self.branch = branch
        self.number = number
        self.balance = balance
    }
}

public enum TransactionKind: String, Codable, Sendable {
    case pixIn = "PIX_IN", pixOut = "PIX_OUT", card = "CARD", bill = "BILL", salary = "SALARY"
}

public struct Transaction: Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let amount: Decimal
    public let kind: TransactionKind
    public let date: Date

    public var isCredit: Bool { amount > 0 }

    public init(id: String, title: String, amount: Decimal, kind: TransactionKind, date: Date) {
        self.id = id
        self.title = title
        self.amount = amount
        self.kind = kind
        self.date = date
    }
}

public struct PixReceipt: Equatable, Sendable {
    public let endToEndId: String
    public let amount: Decimal
    public let recipientName: String

    public init(endToEndId: String, amount: Decimal, recipientName: String) {
        self.endToEndId = endToEndId
        self.amount = amount
        self.recipientName = recipientName
    }
}
