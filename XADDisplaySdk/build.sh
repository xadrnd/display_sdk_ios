# TODO Build
# TODO Add License file
# TODO Compress
aws s3 cp 1.1.0.zip s3://xad-cdn/sdk/downloads/display/ios/1.1.0.zip
launchctl remove com.apple.CoreSimulator.CoreSimulatorService || true
# TODO Pod spec lint
# TODO Push pod