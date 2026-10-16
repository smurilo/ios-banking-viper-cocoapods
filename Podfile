platform :ios, '15.0'
use_frameworks! :linkage => :static
inhibit_all_warnings!

# Each feature is an independent local pod: it compiles, is tested and versioned on its own,
# and the app target only composes them. Swinject wires the dependencies at runtime.
def local_pods
  pod 'BankCore',         :path => 'LocalPods/BankCore',         :testspecs => ['Tests']
  pod 'BankNetworking',   :path => 'LocalPods/BankNetworking',   :testspecs => ['Tests']
  pod 'BankDesignSystem', :path => 'LocalPods/BankDesignSystem'
  pod 'FeatureStatement', :path => 'LocalPods/FeatureStatement', :testspecs => ['Tests']
  pod 'FeatureTransfer',  :path => 'LocalPods/FeatureTransfer',  :testspecs => ['Tests']
end

target 'BankApp' do
  local_pods
  pod 'Swinject', '~> 2.9'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
