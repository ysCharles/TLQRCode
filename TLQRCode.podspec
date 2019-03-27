#
#  Be sure to run `pod spec lint TLQRCode.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "TLQRCode"
  s.version      = "0.5"
  s.summary      = "二维码扫描生成工具"

  s.homepage     = "https://github.com/ysCharles/TLQRCode"


  s.license      = "MIT"


  s.author             = { "Charles" => "ystanglei@gmail.com" }


  s.source       = { :git => "https://github.com/ysCharles/TLQRCode.git", :tag => "#{s.version}" }
  s.platform 	 = :ios, "8.0"

  s.source_files  = "Sources/**/*.swift"

  s.resources = "Sources/*.xcassets"


  s.frameworks = "UIKit", "AVFoundation"


  s.swift_version = '5'
end
