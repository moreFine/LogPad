Pod::Spec.new do |s|
s.name         = "LogPad" # 项目名称
s.version      = "0.0.1"        # 版本号 与 你仓库的 标签号 对应
s.license      = "MIT"          # 开源证书
s.summary      = "显示日志及手机CPU使用率、内存使用情况、FPS"

s.homepage     = "https://github.com/moreFine/LogPad"
s.source       = { :git => "https://github.com/moreFine/LogPad.git", :tag => "#{s.version}" }
s.source_files = "LogPadDemo/LogPad/*.{h,m}"
s.requires_arc = true # 是否启用ARC
s.platform     = :ios, "9.0" #平台及支持的最低版本
s.frameworks   = "UIKit", "Foundation" #支持的框架

# User
s.author             = { "BY" => "990802260@qq.com" }
s.social_media_url   = "https://github.com/moreFine"

end
