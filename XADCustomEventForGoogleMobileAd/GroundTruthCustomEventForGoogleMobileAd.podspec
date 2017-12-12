
    Pod::Spec.new do |s|
      s.name         = "GroundTruthCustomEventForGoogleMobileAd"
      s.version      = "1.1.10"
      s.summary      = "GroundTruth Display SDK iOS Custom Event for Google Mobile Ad"
      s.homepage     = "https://docs.groundtruth.com"
      s.documentation_url = "https://docs.groundtruth.com"
      s.license      = { :type => "BSD", :file => "LICENSE.md" }
      s.author       = { "GroundTruth" => "sdk@groundtruth.com" }
      s.platform     = :ios
      s.ios.deployment_target = '9.0'
      s.source = {
        :git => 'https://github.com/xadrnd/display_sdk_ios.git'
      }
      s.source_files = 'XADCustomEventForGoogleMobileAd/XADCustomEventForGoogleMobileAd/**/*.{h,m,swift}'
      
        s.dependency 'GroundTruthDisplaySDK'
        s.frameworks = 'AdSupport', 'SafariServices'
        
        s.subspec 'Google-Mobile-Ads-SDK' do |default|
          #This will get bundled unless a subspec is specified
          default.dependency 'Google-Mobile-Ads-SDK', '~> 7.26'
        end

        s.pod_target_xcconfig = {
          'OTHER_LDFLAGS'          => '$(inherited) -undefined dynamic_lookup -ObjC',
          'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/Google-Mobile-Ads-SDK'
        }

    end
    