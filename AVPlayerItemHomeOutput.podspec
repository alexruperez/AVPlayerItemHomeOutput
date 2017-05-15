Pod::Spec.new do |s|
  s.name             = 'AVPlayerItemHomeOutput'
  s.version          = '0.1.0'
  s.summary          = 'Coordinate the output of content associated with your HomeKit lightbulbs.'

  s.homepage         = 'https://github.com/alexruperez/AVPlayerItemHomeOutput'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { 'Alex Rupérez' => 'contact@alexruperez.com' }
  s.source           = { :git => 'https://github.com/alexruperez/AVPlayerItemHomeOutput.git', :tag => s.version.to_s }
  s.social_media_url = "https://twitter.com/alexruperez"

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '10.0'

  s.source_files     ="Core/*.{h,swift}"
end