source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'

use_frameworks!
workspace 'RealmBrowser.xcworkspace'

target 'RealmBrowser' do
    pod 'AppSandboxFileAccess'
    pod 'Realm', git: 'https://github.com/realm/realm-cocoa.git', tag: 'v2.0.0', submodules: true
    pod 'RealmConverter'

    target 'RealmBrowserTests' do
      # It looks like that inheritance via search paths is still broken with frameworks, see https://github.com/CocoaPods/CocoaPods/issues/4944
      # inherit! :search_paths
    end
end
