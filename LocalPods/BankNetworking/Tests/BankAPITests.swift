import XCTest
import BankCore
@testable import BankNetworking

final class StubClient: HTTPClient, @unchecked Sendable {
    var responses: [String: Result<Data, Error>] = [:]
    private(set) var sent: [Endpoint] = []

    func send(_ endpoint: Endpoint) async throws -> Data {
        sent.append(endpoint)
        return try responses[endpoint.path, default: .failure(APIError.status(404))].get()
    }
}

final class BankAPITests: XCTestCase {

    func testDecodesAccountAndTransactionsKeepingDecimalPrecision() async throws {
        let client = StubClient()
        client.responses["v1/account"] = .success(#"{"id":"1","holder":"Ana","branch":"0001","number":"123-4","balance":"0.10"}"#.data(using: .utf8)!)
        client.responses["v1/transactions"] = .success(#"[{"id":"t1","description":"Mercado","amount":"-287.43","type":"CARD","dateTime":"2026-03-04T19:12:00"}]"#.data(using: .utf8)!)
        let api = BankAPI(client: client)

        let account = try await api.account()
        let transactions = try await api.transactions()

        XCTAssertEqual(account.balance, Decimal(string: "0.10"))
        XCTAssertEqual(transactions.first?.amount, Decimal(string: "-287.43"))
        XCTAssertEqual(transactions.first?.kind, .card)
    }

    func testPixSendsIdempotencyKeyHeader() async throws {
        let client = StubClient()
        client.responses["v1/pix/transfers"] = .success(#"{"endToEndId":"E1","amount":"50.00","recipientName":"Bruno"}"#.data(using: .utf8)!)

        let receipt = try await BankAPI(client: client).pix(key: .email("b@x.com"), amount: 50, idempotencyKey: "abc")

        XCTAssertEqual(receipt.recipientName, "Bruno")
        XCTAssertEqual(client.sent.first?.headers["Idempotency-Key"], "abc")
        XCTAssertEqual(client.sent.first?.method, .post)
    }

    func testMalformedPayloadBecomesDecodingError() async {
        let client = StubClient()
        client.responses["v1/account"] = .success(Data("{}".utf8))
        do {
            _ = try await BankAPI(client: client).account()
            XCTFail("expected error")
        } catch {
            XCTAssertEqual(error as? APIError, .decoding)
        }
    }
}
