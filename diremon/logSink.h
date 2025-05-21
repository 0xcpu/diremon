//
//  log_sink.h
//  diremon
//
//  Created by cpu on 17.05.2025.
//

#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>


void LogSinkInit(void (*logSendFunc)(const uint8_t *));
void LogSinkSendEvent(FSEventStreamEventId eventId,
                      FSEventStreamEventFlags flags,
                      CFStringRef path);
