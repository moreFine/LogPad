//
//  LogRedirectController.m
//  WW
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
@property (nonatomic, strong) dispatch_semaphore_t writeLogLock;
@property (nonatomic, assign) BOOL bkFlag;
@end
static LogRedirectController *_logRedirect = nil;
static UIApplication *_LogPadSharedApplication() {
    static BOOL isAppExtension = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"UIApplication");
        if(!cls || ![cls respondsToSelector:@selector(sharedApplication)]) isAppExtension = YES;
        if ([[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"]) isAppExtension = YES;
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    return isAppExtension ? nil : [UIApplication performSelector:@selector(sharedApplication)];
#pragma clang diagnostic pop
}
@implementation LogRedirectController
-(dispatch_semaphore_t)writeLogLock{
    if (!_writeLogLock){
        _writeLogLock = dispatch_semaphore_create(1);
    }
    return _writeLogLock;
}
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
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appDidBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}
-(void)appDidBackground{
    self.bkFlag = true;
}
-(void)appWillEnterForeground{
    self.bkFlag = false;
}
-(NSString *)logFilePath{
    NSString *logDirectory = self.logDirectoryPath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:logDirectory]) {
        [fileManager createDirectoryAtPath:logDirectory  withIntermediateDirectories:true attributes:nil error:nil];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    return [logDirectory stringByAppendingFormat:@"/%@.txt",dateStr];
}
-(NSString *)logDirectoryPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Log"];
    return logDirectory;
}
-(NSArray<NSString *> *)LogFileList{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray<NSString *> *lists = [fileManager contentsOfDirectoryAtPath:self.logDirectoryPath error:&error];
    if (error){
        return nil;
    } else {
        return lists;
    }
}
-(void)setLogType:(LOG_TYPE)logType{
    _logType = logType;
    [self startMonitorSystemLog];
}
-(void)startMonitorSystemLog{
    if ([[DeviceDataMonitor shareInstance] debugger]){
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
    RegisterExceptionHandler();
}
//若某一次打印的数据量过大的话，系统会分几次输出
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
        if (self.bkFlag){
            __block UIBackgroundTaskIdentifier taskID = [_LogPadSharedApplication() beginBackgroundTaskWithExpirationHandler:^{
                [_LogPadSharedApplication() endBackgroundTask:taskID];
                taskID = UIBackgroundTaskInvalid;
            }];
            if (taskID != UIBackgroundTaskInvalid) {
                [self writeLogToFile:content customHandler:nil];
                [_LogPadSharedApplication() endBackgroundTask:taskID];
                taskID = UIBackgroundTaskInvalid;
            }else{
                taskID = UIBackgroundTaskInvalid;
            }
        } else {
            [self writeLogToFile:content customHandler:nil];
        }
    }
    [[notification object] readInBackgroundAndNotify];
}
-(void)removeMonitor{
    dup2(self.originalCharacter, self.currentCharacter);
    //恢复重定向后需要移除通知监听否则会导致CPU使用率激增，造成程序卡顿
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(NSString *)readLogFromFile:(NSData * _Nonnull (^)(NSData * _Nonnull))customHandler{
    NSData *data = [NSData dataWithContentsOfFile:[LogRedirectController shareInstance].logFilePath];
    if (customHandler){
        data = customHandler(data);
    }
    if (self.customReadHandler){
        data = self.customReadHandler(data);
    }
    if(data){
        NSString *log = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (log){
            return log;
        } else {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:[LogRedirectController shareInstance].logFilePath error:nil];
            return @"日志数据出错，解析失败；\n自动删除并重建日志文件";
        }
    } else {
        return @"本地暂无日志";
    }
}
-(void)writeLogToFile:(NSString *)log customHandler:(NSData * _Nonnull (^)(NSData * _Nonnull))customHandler{
    dispatch_semaphore_wait(self.writeLogLock, DISPATCH_TIME_FOREVER);
    NSData *logData = [log dataUsingEncoding:NSUTF8StringEncoding];
    if (customHandler){
        logData = customHandler(logData);
    }
    if (self.customWriteHandler){
        logData = self.customWriteHandler(logData);
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.logFilePath]) {
        [logData writeToFile:self.logFilePath atomically:true];
    }else{
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
        [fileHandle seekToEndOfFile];
        if (@available(iOS 13.0, *)) {
            [fileHandle writeData:logData error:nil];
        } else {
            [fileHandle writeData:logData];
        }
        [fileHandle closeFile];
    }
    dispatch_semaphore_signal(self.writeLogLock);
}
-(NSArray<NSString *> *)matchLogFileList:(NSString *)startTimestamp endTime:(NSString *)endTimestamp{
    NSString *startDate = [self timestampConvert:startTimestamp  Format:@"yyyyMMdd"];
    NSString *endDate = [self timestampConvert:endTimestamp Format:@"yyyyMMdd"];
    NSMutableArray<NSString *>* matchingList = [[NSMutableArray<NSString *> alloc] init];
    [self.LogFileList enumerateObjectsUsingBlock:^(NSString * _Nonnull fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        if (([[fileName componentsSeparatedByString:@"."].firstObject compare:startDate] == NSOrderedDescending) &&( [[fileName componentsSeparatedByString:@"."].firstObject compare:endDate] == NSOrderedAscending)){
            [matchingList addObject:fileName];
        }
        if ([[fileName componentsSeparatedByString:@"."].firstObject isEqualToString:startDate] || [[fileName componentsSeparatedByString:@"."].firstObject isEqualToString:endDate]){
            [matchingList addObject:fileName];
        }
    }];
    if (matchingList.count > 0){
        return matchingList;
    } else {
        return nil;
    }
}
-(NSString *)timestampConvert:(NSString *)timestamp Format:(NSString *)format{
    NSTimeInterval convertTimestamp ;
    if (timestamp.length == 10){
        convertTimestamp = [timestamp longLongValue];
    } else if (timestamp.length == 13){
        convertTimestamp = [timestamp longLongValue]/1000;
    } else {
        return nil;
    }
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:convertTimestamp];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    if (format) {
        [formatter setDateFormat:format];
    }else{
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    return [formatter stringFromDate:date];
}

-(NSDate *)dateConvert:(NSString *)dateString Format:(NSString *)format{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    if (format) {
        [formatter setDateFormat:format];
    }else{
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    return [formatter dateFromString:dateString];
}
-(void)trimLogFile{
    if (self.ageLimit > 0){
        [self trimToAge:self.ageLimit];
    } else {
        [self trimToAge:1];
    }
}
- (void)trimToAge:(NSInteger)ageLimit;{
    NSArray<NSString *> *list = [NSArray<NSString *> arrayWithArray:self.LogFileList];
    //升序
    list = [list sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    [list enumerateObjectsUsingBlock:^(NSString * _Nonnull fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSCalendarUnit type =  NSCalendarUnitDay;
        NSDateComponents *cmps = [calendar components:type fromDate:[self dateConvert:[fileName componentsSeparatedByString:@"."].firstObject Format:@"yyyyMMdd"] toDate:[NSDate date] options:0];
        if (cmps.day >= ageLimit){
            [self removeLogFile:fileName];
        } else {
            *stop = true;
        }
    }];
}
-(BOOL)removeLogFile:(NSString *)fileName{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@",self.logDirectoryPath,fileName] error:&error];
    if (error){
        return false;
    } else {
        return true;
    }
}
@end
