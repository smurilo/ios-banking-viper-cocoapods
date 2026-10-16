import XCTest
@testable import BankCore

final class BankCoreTests: XCTestCase {

    func testFormatsBRLRegardlessOfDeviceLocale() {
        XCTAssertEqual(MoneyFormatter.string(from: Decimal(string: "1234.5")!), "R$ 1.234,50")
        XCTAssertEqual(MoneyFormatter.string(from: Decimal(string: "-80")!), "-R$ 80,00")
    }

    func testParsesBrazilianInput() {
        XCTAssertEqual(MoneyFormatter.decimal(from: "1.234,56"), Decimal(string: "1234.56"))
        XCTAssertEqual(MoneyFormatter.decimal(from: "R$ 10,5"), Decimal(string: "10.5"))
        XCTAssertNil(MoneyFormatter.decimal(from: "12,3,4"))
        XCTAssertNil(MoneyFormatter.decimal(from: "abc"))
    }

    func testDetectsPixKeys() {
        XCTAssertEqual(PixKey("529.982.247-25"), .cpf("52998224725"))
        XCTAssertEqual(PixKey("11.222.333/0001-81"), .cnpj("11222333000181"))
        XCTAssertEqual(PixKey(" Ana@Banco.com "), .email("ana@banco.com"))
        XCTAssertEqual(PixKey("+55 (82) 99999-0000"), .phone("+5582999990000"))
        XCTAssertNil(PixKey("111.111.111-11"))
        XCTAssertNil(PixKey("529.982.247-24"))
    }
}
