import re
import sys
import shutil
import subprocess

# TODO Get version from plist


if __name__ == "__main__":
    push_to_pod = False

    if len(sys.argv) < 3:
        print("Usage: %s <product> <version> [push]" % sys.argv[0])
        sys.exit(1)

    if len(sys.argv) == 4:
        push_to_pod = True

    # Get version number
    framework = sys.argv[1]
    version = sys.argv[2]

    if not re.match("\d+\.\d+.\d+", version):
        print("Version number not valid")
        sys.exit(1)

    summary = ""
    name = ""
    license = "BSD"
    download_folder = ""
    deps = ""

    if framework == "XADDisplaySdk":
        name = "GroundTruthDisplaySDK"
        summary = "GroundTruth Display SDK iOS"
        deps = """
        s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
        s.frameworks = 'SafariServices', 'WebKit', 'UIKit', 'CoreLocation', 'SystemConfiguration', 'Foundation'
        s.libraries = 'xml2'
        s.resources = '%s/**/**/Resources/*.{png,js,xsd}'
        """ % framework
    elif framework == "XADCustomEventForGoogleMobileAd":
        name = "GroundTruthCustomEventForGoogleMobileAd"
        summary = "GroundTruth Display SDK iOS Custom Event for Google Mobile Ad"
        deps = """
        s.dependency 'Google-Mobile-Ads-SDK', '~> 7.26'
        s.dependency 'GroundTruthDisplaySDK'
        s.frameworks = 'AdSupport', 'SafariServices'
        """
    elif framework == "XADCustomEventForMopub":
        name = "GroundTruthCustomEventForMopub"
        summary = "GroundTruth Display SDK iOS Custom Event for Mopub"
        deps = """
        s.dependency 'mopub-ios-sdk', '~> 4.18'
        s.dependency 'GroundTruthDisplaySDK'
        s.frameworks = 'AdSupport', 'SafariServices'
        """
    else:
        print("No framework named: %s" % framework)
        sys.exit(1)

    podspec_filename = "%s/%s.podspec" % (framework, name)

    # Pod update
    try:
        print(subprocess.check_output([
            "pod",
            "update",
            "--project-directory=./%s" % framework
        ], stderr=subprocess.STDOUT))
    except:
        pass

    # Edit podspec file
    podspec = """
    Pod::Spec.new do |s|
      s.name         = "%s"
      s.version      = "%s"
      s.summary      = "%s"
      s.homepage     = "https://docs.groundtruth.com"
      s.documentation_url = "https://docs.groundtruth.com"
      s.license      = { :type => "%s", :file => "LICENSE.md" }
      s.author       = { "GroundTruth" => "sdk@groundtruth.com" }
      s.platform     = :ios
      s.ios.deployment_target = '9.0'
      s.source = {
        :git => 'https://github.com/xadrnd/display_sdk_ios.git', :tag => 'v%s' 
      }
      s.source_files = '%s/%s/**/*.{h,m,swift}'
      %s
    end
    """ % (
        name,
        version,
        summary,
        license,
        version,
        framework,
        framework,
        deps
    )

    open(podspec_filename, "w+").write(podspec)

    print("Podspec generated")

    subprocess.check_output([
        "pod",
        "cache",
        "clean",
        "--all"
    ])

    print("Pod spec cache cleared")

    # pod spec lint
    print(subprocess.check_output([
        "pod",
        "spec",
        "lint",
        podspec_filename,
        "--allow-warnings"
    ], stderr=subprocess.STDOUT))

    print("Podspec linted")

    # pod trunk push
    if push_to_pod:
        print(subprocess.check_output([
            "pod",
            "trunk",
            "push",
            podspec_filename,
            "--allow-warnings"
        ], stderr=subprocess.STDOUT))

        print("Podspec uploaded")
