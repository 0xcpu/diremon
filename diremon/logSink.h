//
//  logSink.h
//  diremon
//
//  Created by cpu on 17.05.2025.
//

#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>

#import "logging.h"


void LogSinkInit(bool (*logSendFunc)(NSData *));
bool LogSinkSendEvent(FSEventStreamEventId eventId,
                      FSEventStreamEventFlags flags,
                      CFStringRef path);
