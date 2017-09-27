Pod::Spec.new do |s|
  s.name         = "FMInAppPurchase"
  s.version      = "0.0.1"
  s.summary      = "In app purchase lib."

  s.description  = "an iap lib for virtual product."

  s.homepage     = "https://github.com/acekiller/FMInAppPurchase"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "acekiller" => "fengxijun51020@hotmail.com" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/acekiller/FMInAppPurchase.git", :tag => "#{s.version}" }

  s.source_files  = "Classes", "FMInAppPurchase/FMInAppPurchase/**/*.{swift}"
  # s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"

  s.framework  = "StoreKit"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
