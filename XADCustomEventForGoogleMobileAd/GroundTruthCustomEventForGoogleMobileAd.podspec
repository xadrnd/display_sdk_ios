
    Pod::Spec.new do |s|
      s.name         = "GroundTruthCustomEventForGoogleMobileAd"
      s.version      = "1.1.5"
      s.summary      = "GroundTruth Display SDK iOS Custom Event for Google Mobile Ad"
      s.homepage     = "https://docs.groundtruth.com"
      s.documentation_url = "https://docs.groundtruth.com"
      s.license      = { :type => "BSD", :file => "LICENSE" }
      s.author       = { "GroundTruth" => "sdk@groundtruth.com" }
      s.platform     = :ios
      s.ios.deployment_target = '8.0'
      s.source = {
        :http => 'https://cf.xad.com/sdk/downloads/customeventgooglemobilead/ios/1.1.5/XADCustomEventForGoogleMobileAd.framework.zip'
      }
      s.vendored_frameworks = 'XADCustomEventForGoogleMobileAd.framework'
      
        s.dependency 'Google-Mobile-Ads-SDK', '~> 7.23'
        s.dependency 'GroundTruthDisplaySDK'
        s.frameworks = 'AdSupport', 'SafariServices'
        
    end
    