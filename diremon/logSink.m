//
//  logSink.m
//  diremon
//
//  Created by cpu on 17.05.2025.
//

#import "logSink.h"

static bool (*logSend)(NSData *) = NULL;

void LogSinkInit(bool (*logSendFunc)(NSData *))
{
    logSend = logSendFunc;
}

bool LogSinkSendEvent(FSEventStreamEventId eventId,
                      FSEventStreamEventFlags flags,
                      CFStringRef path)
{
    CFNumberRef eventIdNum = CFNumberCreate(NULL, kCFNumberSInt64Type, &eventId);
    CFNumberRef eventFlags = CFNumberCreate(NULL, kCFNumberSInt64Type, &flags);
    CFStringRef keys[] = {CFSTR("eventId"), CFSTR("flags"), CFSTR("path")};
    CFTypeRef   values[] = {eventIdNum, eventFlags, path};
    CFDictionaryRef eventDict = CFDictionaryCreate(NULL,
                                                   (const void **)keys,
                                                   (const void **)values,
                                                   3,
                                                   &kCFTypeDictionaryKeyCallBacks,
                                                   &kCFTypeDictionaryValueCallBacks);
    if (eventDict == NULL) {
        CFRelease(eventIdNum);
        CFRelease(eventFlags);

        return false;
    }
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:(__bridge id _Nonnull)(eventDict)
                        options:NSJSONWritingWithoutEscapingSlashes
                        error:&jsonError];
    if (jsonData == nil) {
        CFRelease(eventIdNum);
        CFRelease(eventFlags);
        CFRelease(eventDict);

        return false;
    }
    
    bool retStatus = false;
    if (logSend) {
        NSMutableData *logData = [jsonData mutableCopy];
        [logData appendData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding]];

        retStatus = logSend(logData);
    }

    CFRelease(eventIdNum);
    CFRelease(eventFlags);
    CFRelease(eventDict);

    return retStatus;
}
