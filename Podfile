source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'
use_frameworks!

target 'RealmBrowser' do
    pod 'AppSandboxFileAccess'
    pod 'Realm'
    pod 'RealmConverter'
    pod 'HockeySDK-Mac'

    target 'RealmBrowserTests' do
      # It looks like that inheritance via search paths is still broken with frameworks, see https://github.com/CocoaPods/CocoaPods/issues/4944
      # inherit! :search_paths
    end
end
