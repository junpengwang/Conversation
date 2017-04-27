# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
source 'git@gitlab.wilddog.cn:ios/Specs.git'
source 'https://github.com/CocoaPods/Specs.git'
target 'Convasation' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  use_frameworks!
  pod 'WilddogVideo', :path => '../'
  pod 'WilddogSync'

  # Pods for Convasation

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end
