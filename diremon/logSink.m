//
//  log_sink.m
//  diremon
//
//  Created by cpu on 17.05.2025.
//

#import "logSink.h"

static void (*logSend)(const uint8_t *) = NULL;

void LogSinkInit(void (*logSendFunc)(const uint8_t *))
{
    logSend = logSendFunc;
}

void LogSinkSendEvent(FSEventStreamEventId eventId,
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

        return;
    }
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:(__bridge id _Nonnull)(eventDict) options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (jsonData == nil) {
        CFRelease(eventIdNum);
        CFRelease(eventFlags);
        CFRelease(eventDict);
        
        return;
    }
    
    if (logSend) {
        const uint8_t *bytes = [jsonData bytes];
        NSUInteger len   = [jsonData length];
        uint8_t *utf8  = malloc(len + 1);
        memcpy(utf8, bytes, len);
        utf8[len] = '\0';

        logSend(utf8);
        free(utf8);
    }

    CFRelease(eventIdNum);
    CFRelease(eventFlags);
    CFRelease(eventDict);
}
