Pod::Spec.new do |s|
  s.name             = "Fusuma"
  s.version          = "0.1.0"
  s.summary          = "Instagram-like photo browser"

  s.homepage         = "https://github.com/ytakzk/Fusuma"
  s.screenshots     = "https://raw.githubusercontent.com/wiki/ytakzk/Fusuma/images/main.jpg"
  s.license          = 'MIT'
  s.author           = { "ytakzk" => "shyss.ak@gmail.com" }
  s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/Fusuma.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'Fusuma' => ['Pod/Assets/*.png']
  }

end
