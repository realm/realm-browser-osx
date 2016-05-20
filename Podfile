source 'https://github.com/realm/Specs.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'
use_frameworks!

target 'RealmBrowser' do
  pod 'AppSandboxFileAccess'
  pod 'Realm', '0.102.0-1'
  pod 'RealmConverter'

  post_install do |installer|
    installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
      configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    end
  end
end
