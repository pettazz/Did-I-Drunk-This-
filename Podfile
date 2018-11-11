# Uncomment the next line to define a global platform for your project
platform :ios, '12.1'

target 'Did I Drunk This' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Did I Drunk This
  pod 'Alamofire', '~> 4.7'
  pod 'AlamofireImage'
  pod 'Alamofire-SwiftyJSON', '~> 3.0.0'
  pod 'Cosmos', '~> 16.0'
  pod 'KeychainAccess'
  pod 'OAuthSwift', '~> 1.2.0'
  pod 'OnboardKit'
  pod 'SwiftyJSON', '~> 4.0'
  pod 'UIImageColors'

  target 'Did I Drunk ThisTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
end
