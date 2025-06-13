//
//  fileSink.m
//  diremon
//
//  Created by cpu on 21.05.2025.
//

#import "logSink.h"

static NSString *FilePath = @"/var/log/diremon/events.log";
static NSFileHandle *globalFileHandle = nil;

static bool initializeFileHandle(void) {
    if (globalFileHandle != nil) {
        return true;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:FilePath]) {
        os_log_debug(DiremonLog, "creating new %@", FilePath);
        
        NSString *logDir = [FilePath stringByDeletingLastPathComponent];
        NSError *error = nil;
        if (![fileManager createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            os_log_error(DiremonLog, "failed to create log directory: %@", error.localizedDescription);
            return false;
        }
        
        if (![fileManager createFileAtPath:FilePath contents:nil attributes:nil]) {
            os_log_error(DiremonLog, "failed to create log file");
            return false;
        }
    }

    globalFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:FilePath];
    if (globalFileHandle) {
        [globalFileHandle seekToEndOfFile];
        return true;
    }

    os_log_error(DiremonLog, "failed to open file handle");
    return false;
}

static bool fileSend(NSData *msg) {
    if (!initializeFileHandle()) {
        return false;
    }
    
    @try {
        [globalFileHandle writeData:msg];
        [globalFileHandle synchronizeFile];
        return true;
    } @catch (NSException *exception) {
        os_log_error(DiremonLog, "failed to write to log file: %@", exception.reason);
        [globalFileHandle closeFile];
        globalFileHandle = nil;
        return false;
    }
}

void FileSinkInit(void) {
    LogSinkInit(fileSend);
}

void FileSinkCleanup(void) {
    if (globalFileHandle) {
        [globalFileHandle closeFile];
        globalFileHandle = nil;
    }
}
