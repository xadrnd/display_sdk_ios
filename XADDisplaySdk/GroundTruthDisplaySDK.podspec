
    Pod::Spec.new do |s|
      s.name         = "GroundTruthDisplaySDK"
      s.version      = "1.1.8"
      s.summary      = "GroundTruth Display SDK iOS"
      s.homepage     = "https://docs.groundtruth.com"
      s.documentation_url = "https://docs.groundtruth.com"
      s.license      = { :type => "BSD", :file => "LICENSE" }
      s.author       = { "GroundTruth" => "sdk@groundtruth.com" }
      s.platform     = :ios
      s.ios.deployment_target = '8.0'
      s.source = {
        :git => 'git://github.com/xadrnd/display_sdk_ios.git', :tag => 'v1.1.8' 
      }
      s.source_files = 'XADDisplaySdk/*'
      
        s.frameworks = 'SafariServices', 'WebKit', 'UIKit', 'CoreLocation', 'SystemConfiguration', 'Foundation'
        s.libraries = 'xml2'
        
    end
    