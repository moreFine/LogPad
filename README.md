# LogPad

介绍：这是一个支持项目中Log显示的调试控件。
需求：项目在真机上脱离Xcode运行，测试人员需要看到一些实时日志以定位某些问题。

功能：

a.脱离Xcode可显示实时日志；

b.显示日志页面可以隐藏显示，全屏幕拖动；

c.显示日志支持每次打印日志设置不同的颜色，便于区分；

d.debug模式下载真机未连接Xcode的情况下显示日志显示入口，release和连接xcode的情况下不显示；

e.CPU使用率，FPS，内存使用显示。

f.支持异常捕捉，支持日志本地存储，支持读取本地日志文件。
使用：
cocoaPod:  pod 'LogPad'
#
![image](https://github.com/moreFine/LogPad/blob/master/LogPad.gif)
