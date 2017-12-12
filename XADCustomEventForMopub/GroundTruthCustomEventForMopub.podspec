
    Pod::Spec.new do |s|
      s.name         = "GroundTruthCustomEventForMopub"
      s.version      = "1.1.10"
      s.summary      = "GroundTruth Display SDK iOS Custom Event for Mopub"
      s.homepage     = "https://docs.groundtruth.com"
      s.documentation_url = "https://docs.groundtruth.com"
      s.license      = { :type => "BSD", :file => "LICENSE.md" }
      s.author       = { "GroundTruth" => "sdk@groundtruth.com" }
      s.platform     = :ios
      s.ios.deployment_target = '9.0'
      s.source = {
        :git => 'https://github.com/xadrnd/display_sdk_ios.git', :tag => 'v1.1.10' 
      }
      s.source_files = 'XADCustomEventForMopub/XADCustomEventForMopub/**/*.{h,m,swift}'
      
        s.dependency 'mopub-ios-sdk', '~> 4.18'
        s.dependency 'GroundTruthDisplaySDK'
        s.frameworks = 'AdSupport', 'SafariServices'
        
    end
    