
    Pod::Spec.new do |s|
      s.name         = "GroundTruthDisplaySDK"
      s.version      = "1.1.7"
      s.summary      = "GroundTruth Display SDK iOS"
      s.homepage     = "https://docs.groundtruth.com"
      s.documentation_url = "https://docs.groundtruth.com"
      s.license      = { :type => "BSD", :file => "LICENSE" }
      s.author       = { "GroundTruth" => "sdk@groundtruth.com" }
      s.platform     = :ios
      s.ios.deployment_target = '8.0'
      s.source = {
        :http => 'https://cf.xad.com/sdk/downloads/display/ios/1.1.7/XADDisplaySdk.framework.zip'
      }
      s.vendored_frameworks = 'XADDisplaySdk.framework'
      
        s.frameworks = 'SafariServices', 'WebKit', 'UIKit', 'CoreLocation', 'SystemConfiguration', 'Foundation'
        s.libraries = 'xml2'
        
    end
    