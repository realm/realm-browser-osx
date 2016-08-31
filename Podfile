source 'git@github.com:realm/cocoapods-specs-private.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'

use_frameworks!
workspace 'RealmBrowser.xcworkspace'

target 'RealmBrowser' do
    pod 'AppSandboxFileAccess'
    pod 'Realm', '1.0.2-9-sync-1.0.0-beta-29.0'
    pod 'RealmConverter'
end

target 'RealmBrowserTests' do
  pod 'Realm', '1.0.2-9-sync-1.0.0-beta-29.0'
end

target 'RealmObjectServer' do
    project 'RealmObjectServer/RealmObjectServer.xcodeproj'
    pod 'LibRealmSyncServer', '1.0.0-beta-29.0'
end
