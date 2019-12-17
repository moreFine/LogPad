//
//  LogRedirectController.h
//  WW
//
//  Created by wangwei on 2019/11/14.
//  Copyright © 2019 WW. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,LOG_TYPE){
    LG_STDOUT_FILENO  =  0, //使用printf自定义的log输出
    LG_STDERR_FILENO  =  1  //使用fprintf自定义的log输出或者系统封装的的NSLog
};

NS_ASSUME_NONNULL_BEGIN
@interface LogRedirectController : NSObject
@property (nonatomic, assign) LOG_TYPE logType; //日志输出类型，默认值：LG_STDERR_FILENO
@property (nonatomic, copy, readonly) NSString *logFilePath;
@property (nonatomic, copy, readonly) NSString *logDirectoryPath;
@property (nonatomic, copy, readonly) NSArray<NSString *> *LogFileList;
@property (nonatomic, assign) NSInteger ageLimit;
@property (nonatomic, copy) NSData*(^customWriteHandler)(NSData *logData);      //用于自定义写入的日志data数据，eg.加密
@property (nonatomic, copy) NSData*(^customReadHandler)(NSData *logData);       //用于自定义读取的日志data数据，eg.解密
+(instancetype)shareInstance;
-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(void)startMonitorSystemLog;
-(void)removeMonitor;
-(void)trimLogFile;
-(NSString *)readLogFromFile:(NSData*(^_Nullable)(NSData *LogData))customHandler;
-(void)writeLogToFile:(NSString *)log customHandler:(NSData*(^_Nullable)(NSData *LogData))customHandler;
-(NSArray<NSString *> *)matchLogFileList:(NSString *)startTimestamp endTime:(NSString *)endTimestamp;
-(NSString *)timestampConvert:(NSString *)timestamp Format:(NSString *)format;
-(NSDate *)dateConvert:(NSString *)dateString Format:(NSString *)format;
@end

NS_ASSUME_NONNULL_END
