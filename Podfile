source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'
use_frameworks!

target 'RealmBrowser' do
    pod 'AppSandboxFileAccess'
    pod 'Realm', git: 'https://github.com/realm/realm-cocoa', branch: 'master-3.0', submodules: true
    pod 'RealmConverter', git: 'https://github.com/realm/realm-cocoa-converter', branch: 'mar/cocoa-3.0.0-beta.4'
    pod 'HockeySDK-Mac'

    target 'RealmBrowserTests' do
      # It looks like that inheritance via search paths is still broken with frameworks, see https://github.com/CocoaPods/CocoaPods/issues/4944
      # inherit! :search_paths
    end
end
