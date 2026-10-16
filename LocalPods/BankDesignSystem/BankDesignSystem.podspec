Pod::Spec.new do |s|
  s.name         = 'BankDesignSystem'
  s.version      = '1.0.0'
  s.summary      = 'Componentes UIKit reutilizáveis e tema do app.'
  s.homepage     = 'https://github.com/smurilo/ios-banking-viper-cocoapods'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Sérgio Murilo' => 'smsmurilo@gmail.com' }
  s.source       = { :path => '.' }
  s.platform     = :ios, '15.0'
  s.swift_version = '5.9'
  s.source_files = 'Sources/**/*.swift'
  s.dependency 'BankCore'
  s.frameworks = 'UIKit'

end
