source ‘git@github.com:realm/cocoapods-specs-private.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'
use_frameworks!

target 'RealmBrowser' do
  pod 'AppSandboxFileAccess'
  pod 'Realm', '0.102.0-1'
  pod 'RealmConverter'
  pod 'RealmSyncServerBinaries'
end

post_install do |installer|
  `rm -rf Pods/Headers/Public/Realm`
end
