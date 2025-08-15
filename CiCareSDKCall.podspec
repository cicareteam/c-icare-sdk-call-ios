


Pod::Spec.new do |spec|
  spec.name         = "CiCareSDKCall"
  spec.version      = "1.0.1"
  spec.summary      = "SDK for calling app to app webrtc."
  spec.description  = <<-DESC
    CiCareSDKCall is a SDK for calling app to app or app to phone via webrtc.
  DESC
  spec.homepage     = "https://github.com/cicareteam/c-icare-sdk-call-ios.git"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "C-icare Team" => "dev@c-icare.cc" }
  spec.platform     = :ios, "12.0"
  spec.swift_version = "6.0"

  # Source code SDK
  spec.source       = { :git => "https://github.com/cicareteam/c-icare-sdk-call-ios.git", :tag => spec.version.to_s }

  # Jika menggunakan source code
  spec.source_files = "Sources/**/*.{swift,h,m}"

  # If use Framework binary
  # spec.vendored_frameworks = "Frameworks/MySDK.xcframework"

  # Dependencies (optional)
  spec.dependency "WebRTC"
  spec.dependency "Socket.IO-Client-Swift", "~> 16.1.1"
  spec.dependency 'Starscream', '4.0.8'
  spec.dependency 'CryptoSwift', '1.8.4'
  
  # Build setting for module stability
  spec.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end
