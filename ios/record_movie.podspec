#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint record_movie.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'record_movie'
  s.version          = '1.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  # 加载图片资源
  s.resources = ['Assets/*.png']

  s.dependency 'Flutter'
  s.dependency 'MBProgressHUD'
  s.platform = :ios, '8.0'

  s.frameworks   = "CoreGraphics", "QuartzCore"

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
