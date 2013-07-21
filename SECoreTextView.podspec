Pod::Spec.new do |s|
  s.name         = "SECoreTextView"
  s.version      = "1.0.0"
  s.summary      = "Multi-line rich text view library with clickable links, selectable text and embeding images."
  s.homepage     = "https://github.com/kishikawakatsumi/SECoreTextView"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "kishikawakatsumi" => "kishikawakatsumi@mac.com" }
  s.authors      = { "kishikawakatsumi" => "kishikawakatsumi@mac.com" }
  s.source       = { :git => "https://github.com/kishikawakatsumi/SECoreTextView.git", :tag => "v1.0.0" }
  s.ios.deployment_target = '5.0'
  s.source_files = 'Lib/*'
  s.resources = "Resources/SECoreTextView.bundle"
  s.framework  = 'CoreText'
  s.requires_arc = true
end
