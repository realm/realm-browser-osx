source 'git@github.com:realm/cocoapods-specs-private.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'
use_frameworks!
workspace 'RealmBrowser.xcworkspace'

target 'RealmBrowser' do
  pod 'AppSandboxFileAccess'
  pod 'Realm', '0.102.0-1'
  pod 'RealmConverter'
end

target 'RealmSyncServer' do
  xcodeproj 'RealmSyncServer/RealmSyncServer.xcodeproj'
  pod 'RealmSyncServerBinaries'
end

post_install do |installer|
  `rm -rf Pods/Headers/Public/Realm`
end
