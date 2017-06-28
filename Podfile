platform :ios, '8.0'

source 'git@gitlab.wilddog.cn:ios/Specs.git'
source 'https://github.com/WildDogTeam/wilddog-ios-repo.git'
source 'https://github.com/CocoaPods/Specs.git'

target 'Convasation' do
    pod 'WilddogVideo', '1.1.1beta'
#   pod 'WilddogVideo', :path => '../WilddogVideo'
#   pod 'WebRTC', :path => '../video-client-ios-webrtc-binary'
#   pod 'WebRTC', '58.0.3'

#pod 'WilddogVideo','0.6.0pre'
  # Pods for Convasation
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end




