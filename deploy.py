import re
import sys
import shutil
from boto.s3.connection import S3Connection
from boto.s3.key import Key
import subprocess
from boto.cloudfront import CloudFrontConnection

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
        download_folder = "display"
        deps = """
        s.frameworks = 'SafariServices', 'WebKit', 'UIKit', 'CoreLocation', 'SystemConfiguration', 'Foundation'
        s.libraries = 'xml2'
        """
    elif framework == "XADCustomEventForGoogleMobileAd":
        name = "GroundTruthCustomEventForGoogleMobileAd"
        summary = "GroundTruth Display SDK iOS Custom Event for Google Mobile Ad"
        download_folder = "customeventgooglemobilead"
        deps = """
        s.dependency 'Google-Mobile-Ads-SDK', '~> 7.26'
        s.dependency 'GroundTruthDisplaySDK'
        s.frameworks = 'AdSupport', 'SafariServices'
        """
    elif framework == "XADCustomEventForMopub":
        name = "GroundTruthCustomEventForMopub"
        summary = "GroundTruth Display SDK iOS Custom Event for Mopub"
        download_folder = "customeventmopub"
        deps = """
        s.dependency 'mopub-ios-sdk', '~> 4.18'
        s.dependency 'GroundTruthDisplaySDK'
        s.frameworks = 'AdSupport', 'SafariServices'
        """

    podspec_filename = "%s/%s.podspec" % (framework, name)

    s3_conn = S3Connection()
    bucket = s3_conn.get_bucket("xad-cdn")

    # Pod update
    try:
        print(subprocess.check_output([
            "pod",
            "update",
            "--project-directory=./%s" % framework
        ], stderr=subprocess.STDOUT))
    except:
        pass

    if framework != "XADDisplaySdk":
        # Build archive
        subprocess.check_output(
            [
                "xcodebuild",
                "-workspace",
                "{framework}/{framework}.xcworkspace".format(framework=framework),
                "-scheme",
                framework,
                "archive"
            ],
            stderr=subprocess.STDOUT
        )
    else:
        subprocess.check_output(
            [
                "xcodebuild",
                "-project",
                "{framework}/{framework}.xcodeproj".format(framework=framework),
                "-scheme",
                framework,
                "archive"
            ],
            stderr=subprocess.STDOUT
        )

    print("Framework built")

    # Zip framework
    shutil.make_archive(
        "{framework}/{framework}.framework".format(framework=framework),
        "zip",
        "{framework}/".format(framework=framework),
        "{framework}.framework".format(framework=framework)
    )

    print("Framework zipped")

    target_location = "sdk/downloads/%s/ios/%s/%s.framework.zip" % (download_folder, version, framework)

    # Upload to cloudfront
    key = bucket.get_key(target_location)
    if not key:
        key = Key(bucket)
        key.key = target_location

    key.set_contents_from_filename("{framework}/{framework}.framework.zip".format(framework=framework))

    print("Framework uploaded to CloudFront")

    cf_conn = CloudFrontConnection(AWS_KEY, AWS_SECRET)
    cf_conn.create_invalidation_request("E1W31HOTQX0RGC", "/sdk*")

    print("CloudFront invalidation requested")

    # Edit podspec file
    podspec = """
    Pod::Spec.new do |s|
      s.name         = "%s"
      s.version      = "%s"
      s.summary      = "%s"
      s.homepage     = "https://docs.groundtruth.com"
      s.documentation_url = "https://docs.groundtruth.com"
      s.license      = { :type => "%s", :file => "LICENSE" }
      s.author       = { "GroundTruth" => "sdk@groundtruth.com" }
      s.platform     = :ios
      s.ios.deployment_target = '8.0'
      s.source = {
        :http => 'https://cf.xad.com/%s'
      }
      s.vendored_frameworks = '%s.framework'
      %s
    end
    """ % (
        name,
        version,
        summary,
        license,
        target_location,
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
