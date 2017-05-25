#
# Be sure to run `pod lib lint RealtimeMessaging-iOS-Swift3.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "RealtimeMessaging-iOS-Swift3-Push"
  s.version          = "1.0.14"
  s.summary          = "Swift3 Realtime Cloud Messaging (ORTC) SDK for iOS with push notifications catgory"

  s.description      = <<-DESC
      Part of the The Realtime® Framework, Realtime Cloud Messaging (aka ORTC) is a secure, fast and highly scalable cloud-hosted Pub/Sub real-time message broker for web and mobile apps.

      If your website or mobile app has data that needs to be updated in the user’s interface as it changes (e.g. real-time stock quotes or ever changing social news feed) Realtime Cloud Messaging is the reliable, easy, unbelievably fast, “works everywhere” solution.
  DESC

  s.homepage         = "https://github.com/realtime-framework/RealtimeMessaging-iOS-Swift3-Push"
  s.license          = 'MIT'
  s.author           = { "Realtime.co" => "framework@realtime.co" }
  s.source           = { :git => "https://github.com/realtime-framework/RealtimeMessaging-iOS-Swift3-Push.git", :tag => s.version}
  s.social_media_url = 'https://twitter.com/RTWworld'

  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '9.0'

  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'
  s.dependency 'RealtimeMessaging-iOS-Swift3', '1.0.2'
end
