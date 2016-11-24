source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'
use_frameworks!

target 'RealmBrowser' do
    pod 'AppSandboxFileAccess'
    pod 'Realm', git: 'https://github.com/realm/realm-cocoa.git', commit: '293e3f3b09b2ed800dab6ee8138eb32de2224d5f', submodules: true
    pod 'RealmConverter'
    pod 'HockeySDK-Mac'

    target 'RealmBrowserTests' do
      # It looks like that inheritance via search paths is still broken with frameworks, see https://github.com/CocoaPods/CocoaPods/issues/4944
      # inherit! :search_paths
    end
end

# FIXME: Xcode 8 support
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '2.3'
        end
    end
end
