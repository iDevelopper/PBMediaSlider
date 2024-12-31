#
# Be sure to run `pod lib lint PBMediaSlider.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PBMediaSlider'
  s.version          = '0.1.3'
  s.summary          = 'A Swift Package aiming to recreate volume and track sliders found in Apple Music on iOS 16 and later.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
PBMediaSlider is a small Swift Package aiming to recreate volume and track sliders found in Apple Music on iOS 16 and later.
                       DESC

  s.homepage         = 'https://github.com/iDevelopper/PBMediaSlider'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'iDevelopper' => 'patrick.bodet4@wanadoo.fr' }
  s.source           = { :git => 'https://github.com/iDevelopper/PBMediaSlider.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'PBMediaSlider/Classes/**/*'

  s.swift_version = '5.9'

  # s.resource_bundles = {
  #   'PBMediaSlider' => ['PBMediaSlider/Assets/*.png']
  # }
end
