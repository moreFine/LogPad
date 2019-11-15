//
//  LogRedirectController.h
//  XJKHealth
//
//  Created by wangwei on 2019/11/14.
//  Copyright © 2019 WW. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,LOG_TYPE){
    LG_STDOUT_FILENO  =  0, ///标准输出，stdout (eg:printf)
    LG_STDERR_FILENO  =  1  ///标准错误输出，stderr (eg:NSLog)
};

NS_ASSUME_NONNULL_BEGIN
@interface LogRedirectController : NSObject
@property (nonatomic, assign) LOG_TYPE logType;     ///日志输出类型，默认值：LG_STDERR_FILENO
@property (nonatomic, assign) BOOL enableDebugger;  ///true:连上Xcode输出日志到文件及不输出到控制台 false:连上Xcode不输出日志到文件及输出到控制台
@property (nonatomic, copy, readonly) NSString *logFilePath;
+(instancetype)shareInstance;
-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(void)startMonitorSystemLog;
-(void)removeMonitor;
@end

NS_ASSUME_NONNULL_END
