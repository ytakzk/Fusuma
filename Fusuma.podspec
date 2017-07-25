Pod::Spec.new do |s|
  s.name             = "Fusuma"
  s.version          = "2.0.2"
  s.summary          = "Instagram-like photo browser with a few line of code written in Swift"
  s.homepage         = "https://github.com/shu-ua/Fusuma"
  s.license          = 'MIT'
  s.author           = { "ytakzk" => "shyss.ak@gmail.com" }
  s.source           = { :git => "https://github.com/ytakzk/Fusuma.git", :tag => s.version.to_s }
  s.platform     = :ios, '10.0'
  s.requires_arc = true
  s.source_files = 'Sources/**/*.swift'
  s.resources    = ['Sources/Assets.xcassets', 'Sources/**/*.xib']
  s.dependency "NextLevel", "~> 0.3.5"
end

