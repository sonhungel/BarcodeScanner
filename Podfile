# Uncomment the next line to define a global platform for your project
# platform :ios, '10.0'

target 'BarcodeScanner' do
  pod 'SnapKit', '~> 5.0.0'
  pod 'SDWebImage'
  pod 'JGProgressHUD'

  # Pods for BarcodeScanner
  # automatically match the deployment target
  post_install do |pi|
      pi.pods_project.targets.each do |t|
        t.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
      end
  end

end
