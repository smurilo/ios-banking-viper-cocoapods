Pod::Spec.new do |s|
  s.name         = 'BankCore'
  s.version      = '1.0.0'
  s.summary      = 'Modelos de domínio e regras de negócio (Foundation puro).'
  s.homepage     = 'https://github.com/smurilo/ios-banking-viper-cocoapods'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Sérgio Murilo' => 'smsmurilo@gmail.com' }
  s.source       = { :path => '.' }
  s.platform     = :ios, '15.0'
  s.swift_version = '5.9'
  s.source_files = 'Sources/**/*.swift'


  s.test_spec 'Tests' do |t|
    t.source_files = 'Tests/**/*.swift'
  end
end
