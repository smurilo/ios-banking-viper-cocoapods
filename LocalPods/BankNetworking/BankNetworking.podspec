Pod::Spec.new do |s|
  s.name         = 'BankNetworking'
  s.version      = '1.0.0'
  s.summary      = 'Cliente HTTP async/await, endpoints e serviços da API.'
  s.homepage     = 'https://github.com/smsmurilo/ios-banking-viper-cocoapods'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Sérgio Murilo' => 'smsmurilo@gmail.com' }
  s.source       = { :path => '.' }
  s.platform     = :ios, '15.0'
  s.swift_version = '5.9'
  s.source_files = 'Sources/**/*.swift'
  s.dependency 'BankCore'

  s.test_spec 'Tests' do |t|
    t.source_files = 'Tests/**/*.swift'
  end
end
