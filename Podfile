source 'git@github.com:realm/cocoapods-specs-private.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'

use_frameworks!
workspace 'RealmBrowser.xcworkspace'

target 'RealmBrowser' do
    pod 'AppSandboxFileAccess'
    pod 'Realm', '1.0.2-7-sync-0.28.0'
    pod 'RealmConverter'
end

target 'RealmObjectServer' do
    project 'RealmObjectServer/RealmObjectServer.xcodeproj'
    pod 'LibRealmSyncServer', '0.28.0'
end
