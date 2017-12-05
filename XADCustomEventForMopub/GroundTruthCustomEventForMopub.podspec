
    Pod::Spec.new do |s|
      s.name         = "GroundTruthCustomEventForMopub"
      s.version      = "1.1.8"
      s.summary      = "GroundTruth Display SDK iOS Custom Event for Mopub"
      s.homepage     = "https://docs.groundtruth.com"
      s.documentation_url = "https://docs.groundtruth.com"
      s.license      = { :type => "BSD", :file => "LICENSE" }
      s.author       = { "GroundTruth" => "sdk@groundtruth.com" }
      s.platform     = :ios
      s.ios.deployment_target = '8.0'
      s.source = {
        :http => 'https://cf.xad.com/sdk/downloads/customeventmopub/ios/1.1.8/XADCustomEventForMopub.framework.zip'
      }
      s.vendored_frameworks = 'XADCustomEventForMopub.framework'
      
        s.dependency 'mopub-ios-sdk', '~> 4.18'
        s.dependency 'GroundTruthDisplaySDK'
        s.frameworks = 'AdSupport', 'SafariServices'
        
    end
    