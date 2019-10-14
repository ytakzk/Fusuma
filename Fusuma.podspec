Pod::Spec.new do |s|
  s.name             = "Fusuma"
  s.version          = "1.3.3"
  s.summary          = "Instagram-like photo browser with a few line of code written in Swift"
  s.homepage         = "https://github.com/ytakzk/Fusuma"
  s.license          = 'MIT'
  s.author           = { "ytakzk" => "yt@ytakzk.me" }
  s.source           = { :git => "https://github.com/ytakzk/Fusuma.git", :tag => s.version.to_s }
  s.ios.deployment_target  = '8.0'
  s.requires_arc = true
  s.source_files = 'Sources/**/*.swift'
  s.resources    = ['Sources/Assets.xcassets', 'Sources/**/*.xib']
end
