//
//  fileSink.m
//  diremon
//
//  Created by cpu on 21.05.2025.
//

#import "logSink.h"

static NSString *FilePath = @"/var/log/diremon/events.log";

static bool fileSend(NSData *msg) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:FilePath]) {
        os_log_debug(DiremonLog, "creating new %@", FilePath);

        [fileManager createFileAtPath:FilePath contents:nil attributes:nil];
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:FilePath];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:msg];
        [fileHandle closeFile];

        return true;
    }

    os_log_error(DiremonLog, "no file handle");
    return false;
}

void FileSinkInit(void) {
    LogSinkInit(fileSend);
}
