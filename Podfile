source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!

$project_name = 'Chanify'
$ios_version = '14.0'
$osx_version = '11.0'
$watchos_version = '7.0'

platform :ios, $ios_version

target 'iOS' do
	platform :ios, $ios_version

	pod 'FMDB'
	pod 'JLRoutes'
	pod 'Masonry'
	pod 'M80AttributedLabel'
	pod 'Protobuf'
end

target 'OSX' do
	platform :osx, $osx_version

	pod 'FMDB'
	pod 'JLRoutes'
	pod 'Masonry'
	pod 'Protobuf'
end

target 'NotificationServiceIOS' do
	platform :ios, $ios_version

	pod 'FMDB'
	pod 'Protobuf'
end

target 'WidgetsExtension' do
	platform :ios, $ios_version

	pod 'FMDB'
end

target 'Watch Extension' do 
	platform :watchos, $watchos_version

	pod 'FMDB'
	pod 'Protobuf'
end

target 'WatchNotificationService' do 
	platform :watchos, $watchos_version

	pod 'FMDB'
	pod 'Protobuf'
end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			config.build_settings['CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED'] = 'YES'
			if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < $ios_version.to_f
				config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $ios_version
			end
			if config.build_settings['MACOSX_DEPLOYMENT_TARGET'].to_f < $osx_version.to_f
				config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = $osx_version
			end
			if config.build_settings['WATCHOS_DEPLOYMENT_TARGET'].to_f < $watchos_version.to_f
				config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = $watchos_version
			end
		end
	end
	# Install acknowledgements
	$src = 'Pods/Target Support Files/Pods-iOS/Pods-iOS-acknowledgements.plist'
	$dst = 'iOS/Resources/Settings.bundle/Acknowledgements.plist'
	FileUtils.cp_r($src, $dst, :remove_destination => true)
end
