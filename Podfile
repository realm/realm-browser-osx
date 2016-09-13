source 'git@github.com:realm/cocoapods-specs-private.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'

use_frameworks!
workspace 'RealmBrowser.xcworkspace'

target 'RealmBrowser' do
    pod 'AppSandboxFileAccess'
    pod 'Realm', '1.0.2-17-sync-1.0.0-beta-33.0'
    pod 'RealmConverter'

    target 'RealmBrowserTests' do
      # It looks like that inheritance via search paths is still broken with frameworks, see https://github.com/CocoaPods/CocoaPods/issues/4944
      # inherit! :search_paths
    end
end
