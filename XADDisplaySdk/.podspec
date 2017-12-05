
    Pod::Spec.new do |s|
      s.name         = ""
      s.version      = "1.1.8"
      s.summary      = ""
      s.homepage     = "https://docs.groundtruth.com"
      s.documentation_url = "https://docs.groundtruth.com"
      s.license      = { :type => "BSD", :file => "LICENSE" }
      s.author       = { "GroundTruth" => "sdk@groundtruth.com" }
      s.platform     = :ios
      s.ios.deployment_target = '8.0'
      s.source = {
        :git => 'git://github.com/xadrnd/display_sdk_ios.git', :tag => 'v1.1.8' 
      }
      s.source_files = 'XADDisplaySDK/*'
      
    end
    