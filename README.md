# Conta Digital iOS — VIPER + CocoaPods modular + Swinject

App bancário em **UIKit** com **arquitetura VIPER**, **modularizado em pods locais do CocoaPods** e **injeção de dependências com Swinject**. Cada feature é um pod independente, com seus próprios testes.

> Segmento: **Bancário**

## Stack
Swift 5.9 • **UIKit** (DiffableDataSource, UIListContentConfiguration, Dynamic Type) • **VIPER** • **CocoaPods** (development pods + `test_spec`) • **Swinject** (Assemblies) • async/await + `async let` • URLSession • Keychain • XCTest • XcodeGen • Swift Package Manager (espelho para CI)

## Modularização com CocoaPods

```
LocalPods/
├── BankCore            Foundation puro: Account, Transaction, PixKey (CPF/CNPJ/e-mail/celular/EVP), MoneyFormatter
├── BankNetworking      HTTPClient (protocolo) + URLSessionHTTPClient + BankAPI (DTOs, Decimal sem perda)
├── BankDesignSystem    BalanceView (ocultar saldo), PrimaryButton (loading), Theme
├── FeatureStatement    VIPER: View · Interactor · Presenter · Entity · Router  (+ testes)
└── FeatureTransfer     VIPER do Pix com idempotência  (+ testes)
BankApp/
├── DI/Assemblies       Swinject: NetworkingAssembly, FeatureAssembly
└── SceneDelegate       composição + capa de privacidade no app switcher
```
O grafo de dependências é explícito nos `.podspec`: features não se conhecem; o app as compõe pelo container de DI.

## VIPER

```
 ViewController ──eventos──► Presenter ──► Interactor ──► StatementServicing (protocolo)
       ▲                        │  formata dinheiro/datas,      (async let: conta + transações em paralelo)
       └──── ViewModel ─────────┘  agrupa por dia ("Hoje", "Ontem")
                                │
                             Router ──► navegação (Pix, detalhe)
```
- **Presenter e Interactor não importam UIKit**: são testados em qualquer máquina, inclusive Linux.
- Um novo *pull-to-refresh* **cancela** a requisição anterior (`Task.cancel`).
- Erro de conexão gera mensagem específica; os demais erros, mensagem genérica.

## Segurança
Token no **Keychain** (`WhenUnlockedThisDeviceOnly`), dinheiro trafegado como *string* → `Decimal`, **chave de idempotência** reaproveitada no retry do Pix e **blur** ao ir para o app switcher.

## Como executar
```bash
brew install xcodegen cocoapods
xcodegen && pod install
open BankApp.xcworkspace          # rode o esquema BankApp; os testes de cada pod aparecem como test specs

swift test                        # roda Core, Networking e os Presenters/Interactors VIPER via SPM (macOS ou Linux)
```
