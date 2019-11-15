//
//  LogRedirectController.m
//  XJKHealth
//
//  Created by wangwei on 2019/11/14.
//  Copyright © 2019 WW. All rights reserved.
//

#import "LogRedirectController.h"
#import "DeviceDataMonitor.h"

@interface LogRedirectController ()
@property (nonatomic, assign) int originalCharacter;
@property (nonatomic, assign) int currentCharacter;
@property (nonatomic, strong) NSFileHandle *pipeReadHandle;
@property (nonatomic, strong) NSData *lastData;
@end
static LogRedirectController *_logRedirect = nil;
@implementation LogRedirectController
+(instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _logRedirect = [[LogRedirectController alloc] init];
    });
    return _logRedirect;
}
-(instancetype)init{
    if (self = [super init]){
        _logType = LG_STDERR_FILENO;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Log"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:logDirectory]) {
            [fileManager createDirectoryAtPath:logDirectory  withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
        [formatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *dateStr = [formatter stringFromDate:[NSDate date]];
        _logFilePath = [logDirectory stringByAppendingFormat:@"/%@.txt",dateStr];
    }
    return self;
}
-(void)setLogType:(LOG_TYPE)logType{
    _logType = logType;
    [self startMonitorSystemLog];
}
-(void)startMonitorSystemLog{
    if (!self.enableDebugger&&[[DeviceDataMonitor shareInstance] debugger]){
        return;
    }
    UIDevice *device = [UIDevice currentDevice];
    if([[device model] hasSuffix:@"Simulator"]){
        return;
    }
    //保存重定向前的文件描述符
    NSPipe * pipe = [NSPipe pipe];
    self.pipeReadHandle = [pipe fileHandleForReading] ;
    int pipeFileHandle = [[pipe fileHandleForWriting] fileDescriptor];
    if (self.logType == LG_STDERR_FILENO){
        self.originalCharacter = dup(STDERR_FILENO);
        self.currentCharacter = dup2(pipeFileHandle, STDERR_FILENO);
    } else {
        self.originalCharacter = dup(STDOUT_FILENO);
        self.currentCharacter = dup2(pipeFileHandle, STDOUT_FILENO);
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(monitorAction:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:self.pipeReadHandle] ;
    [self.pipeReadHandle readInBackgroundAndNotify];
}
//若某一次打印的数据量过大的话，系统可能会分几次输出
-(void)monitorAction:(NSNotification *)notification{
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSMutableData *parseData = nil;
    if (self.lastData){
        parseData = [NSMutableData dataWithData:self.lastData];
        [parseData appendData:data];
    } else {
        parseData =  [NSMutableData dataWithData:data];
    }
    NSString *content = nil;
    if (parseData){
        content = [[NSString alloc] initWithData:parseData encoding:NSUTF8StringEncoding];
    }
    if (!content && parseData.length > 0){
        //本次发送的data不完整无法解析,需要保存本次并与下次读的数据一起解析
        self.lastData = [parseData copy];
        content = @"";
    } else if (!content && parseData.length == 0) {
        content = @"";
        self.lastData = nil;
    } else {
        self.lastData = nil;
    }
    if (content.length > 0){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0 ), ^{
            [self writeLogToFile:content];
        });
    }
    [[notification object] readInBackgroundAndNotify];
}
-(void)removeMonitor{
    dup2(self.originalCharacter, self.currentCharacter);
    //恢复重定向后需要移除通知监听否则会导致CPU使用率激增，造成程序卡顿
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)writeLogToFile:(NSString *)log{
    NSString *logContent = [NSString stringWithFormat:@"%@\r\n",log];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.logFilePath]) {
        NSError *error = nil;
        [logContent writeToFile:self.logFilePath atomically:true encoding:NSUTF8StringEncoding error:&error];
        if (error){
            NSLog(@"写入日志文件失败：%@",error);
        }
    }else{
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
        [fileHandle seekToEndOfFile];
        NSData * logData= [logContent dataUsingEncoding:NSUTF8StringEncoding];
        if (@available(iOS 13.0, *)) {
            NSError *error = nil;
            [fileHandle writeData:logData error:&error];
            if (error){
                NSLog(@"写入日志文件失败：%@",error);
            }
        } else {
            [fileHandle writeData:logData];
        }
        [fileHandle closeFile];
    }
}
@end
