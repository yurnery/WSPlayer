
Pod::Spec.new do |s|

  s.name         = "WSPlayer"
  s.version      = "0.0.2"
  s.summary      = "A simple AVplayer."

  s.description  = "a simple videoPlayer base on Avplayer, use swift4.0, also can play audio"
  s.homepage     = "https://github.com/yurnery/WSPlayer"

  s.license      = "MIT"
  s.author       = { "wws" => "weiwenshe@yeah.net" }

  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/yurnery/WSPlayer.git", :tag => "#{s.version}" }

  s.source_files  = "Sources/*.swift"
  s.requires_arc = true
  s.dependency = "SnapKit"
end
