Pod::Spec.new do |s|
  s.name         = 'FeatureStatement'
  s.version      = '1.0.0'
  s.summary      = 'Módulo VIPER de extrato.'
  s.homepage     = 'https://github.com/smurilo/ios-banking-viper-cocoapods'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Sérgio Murilo' => 'smsmurilo@gmail.com' }
  s.source       = { :path => '.' }
  s.platform     = :ios, '15.0'
  s.swift_version = '5.9'
  s.source_files = 'Sources/**/*.swift'
  s.dependency 'BankCore'
  s.dependency 'BankNetworking'
  s.dependency 'BankDesignSystem'

  s.test_spec 'Tests' do |t|
    t.source_files = 'Tests/**/*.swift'
  end
end
