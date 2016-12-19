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

# FIXME: Xcode 8 support
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '2.3'
        end
    end
    
    # FIXME: remove after https://github.com/CocoaPods/CocoaPods/pull/6146 is released
    realm_target = installer.pods_project.targets.find { |target| target.name == "Realm" }
    
    create_symlinks_phase = realm_target.build_phases.find { |phase| phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && phase.name == "Create Symlinks to Header Folders" }
    create_symlinks_phase.shell_script = <<-eos.strip_heredoc
        base="$CONFIGURATION_BUILD_DIR/$WRAPPER_NAME"
        ln -fs "$base/${PUBLIC_HEADERS_FOLDER_PATH\#$WRAPPER_NAME/}" "$base/${PUBLIC_HEADERS_FOLDER_PATH\#\$CONTENTS_FOLDER_PATH/}"
        ln -fs "$base/${PRIVATE_HEADERS_FOLDER_PATH\#\$WRAPPER_NAME/}" "$base/${PRIVATE_HEADERS_FOLDER_PATH\#\$CONTENTS_FOLDER_PATH/}"
      eos
end
