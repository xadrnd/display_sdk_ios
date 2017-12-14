
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
      s.source_files = 'XADCustomEventForGoogleMobileAd/XADCustomEventForGoogleMobileAd/*.{h,swift}'
      s.requires_arc = true
        s.dependency 'GroundTruthDisplaySDK'
        s.dependency 'Google-Mobile-Ads-SDK', '~> 7.26'
        s.frameworks = 'AdSupport', 'SafariServices'

        s.pod_target_xcconfig = {
          'OTHER_LDFLAGS'          => '$(inherited) -undefined dynamic_lookup',
          'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/Google-Mobile-Ads-SDK/Frameworks'
          #'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
        }

    end