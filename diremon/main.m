//
//  main.m
//  diremon
//
//  Created by cpu on 03.05.2025.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import <signal.h>

#import "logging.h"
#import "logSink.h"
#import "fileSink.h"


static CFStringRef DiremonAppID = CFSTR("com.cpu.diremon");


void fsEventsCallback(ConstFSEventStreamRef streamRef,
                      void *clientCallBackInfo,
                      size_t numEvents,
                      void *eventPaths,
                      const FSEventStreamEventFlags *eventFlags,
                      const FSEventStreamEventId *eventIds)
{
    os_log_debug(DiremonLog, "start processing new event");
    
    os_log_info(DiremonLog, "reporting %zu events", numEvents);
    CFArrayRef cfEventPaths = (CFArrayRef)eventPaths;
    for (size_t i = 0; i < numEvents; i++) {
        CFStringRef path = CFArrayGetValueAtIndex(cfEventPaths, i);
        os_log_info(DiremonLog, "path: %{public}@", path);
        LogSinkSendEvent(eventIds[i], eventFlags[i], path);
    }
    
    os_log_debug(DiremonLog, "end processing new event");
}

// load latest event ID that was process or fallback to kFSEventStreamEventIdSinceNow
FSEventStreamEventId prefLoadDiremonState(void)
{
    os_log_debug(DiremonLog, "loading state");

    CFNumberRef eventIDNum = CFPreferencesCopyValue(CFSTR("LastEventID"),
                                                    DiremonAppID,
                                                    kCFPreferencesCurrentUser,
                                                    kCFPreferencesAnyHost);
    // Convert CFNumberRef to FSEventStreamEventId safely
    FSEventStreamEventId latestEventId = kFSEventStreamEventIdSinceNow;
    if (eventIDNum != NULL) {
        // from CFNumberGetValue docs:
        // "If the argument type differs from the return type, and the conversion is lossy or the return value is out of range,
        // then this function passes back an approximate value in valuePtr and returns false."
        // when that happens, we log the fallback and start monitoring from now on.
        if (!CFNumberGetValue(eventIDNum, kCFNumberSInt64Type, &latestEventId)) {
            os_log_debug(DiremonLog, "fallback to kFSEventStreamEventIdSinceNow");
            // Fallback if conversion fails
            latestEventId = kFSEventStreamEventIdSinceNow;
        } else {
            os_log_debug(DiremonLog, "loaded event id: %llu", latestEventId);
        }
        CFRelease(eventIDNum);
    } else {
        os_log_debug(DiremonLog, "found no event id");
    }
    
    return latestEventId;
}

// save latest event ID along with volume UUID
void prefSaveDiremonState(FSEventStreamRef streamRef)
{
    os_log_debug(DiremonLog, "saving state");
    // Grab the latest event ID from the stream
    FSEventStreamEventId latestEventId = FSEventStreamGetLatestEventId(streamRef);
    
    os_log_debug(DiremonLog, "saving latest event id: %llu", latestEventId);

    // Persist the event ID and stream UUID using CFPreferences
    CFNumberRef eventIDNum = CFNumberCreate(NULL, kCFNumberSInt64Type, &latestEventId);
    CFPreferencesSetValue(CFSTR("LastEventID"),
                          eventIDNum,
                          DiremonAppID,
                          kCFPreferencesCurrentUser,
                          kCFPreferencesAnyHost);
    CFRelease(eventIDNum);
    
    os_log_debug(DiremonLog, "saved state");
}

int main(int argc, const char * argv[])
{
    int exitStatus = EXIT_SUCCESS;

    LoggingInit();
    @autoreleasepool {
        if (argc != 2) {
            os_log_error(DiremonLog, "%{public}s <path to monitor>", argv[0]);
            
            return EXIT_FAILURE;
        }

        signal(SIGTERM, SIG_IGN);
        signal(SIGINT, SIG_IGN);
        dispatch_source_t sigTermSrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL,
                                                              SIGTERM,
                                                              0,
                                                              dispatch_get_main_queue());
        dispatch_source_set_event_handler(sigTermSrc, ^{
            CFRunLoopStop(CFRunLoopGetMain());
        });
        dispatch_source_t sigIntSrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL,
                                                             SIGINT,
                                                             0,
                                                             dispatch_get_main_queue());
        dispatch_source_set_event_handler(sigIntSrc, ^{
            CFRunLoopStop(CFRunLoopGetMain());
        });
        dispatch_resume(sigTermSrc);
        dispatch_resume(sigIntSrc);
        
        CFStringRef pathToMonitor = CFStringCreateWithCString(NULL, argv[1], kCFStringEncodingASCII);
        os_log_info(DiremonLog, "directory to monitor: %{public}@", pathToMonitor);
        CFArrayRef pathsToMonitor = CFArrayCreate(NULL, (const void **)&pathToMonitor, 1, &kCFTypeArrayCallBacks);
        void *callbackInfo = NULL;
        CFAbsoluteTime latency = 3.0; // seconds
        FSEventStreamEventId latestEventId = prefLoadDiremonState();
        
        FSEventStreamRef fsEventStream = FSEventStreamCreate(NULL,
                                                             &fsEventsCallback,
                                                             callbackInfo,
                                                             pathsToMonitor,
                                                             latestEventId,
                                                             latency,
                                                             kFSEventStreamCreateFlagWatchRoot | kFSEventStreamCreateFlagFileEvents \
                                                             | kFSEventStreamCreateFlagUseCFTypes);
        
        dispatch_queue_t dispatchQueue = dispatch_queue_create("com.cpu.diremon.queue", NULL);
        FSEventStreamSetDispatchQueue(fsEventStream, dispatchQueue);
        os_log_info(DiremonLog, "event stream and dispatch queue are ready, starting the stream");
        Boolean didEventStreamStart = FSEventStreamStart(fsEventStream);
        if (!didEventStreamStart) {
            os_log_error(DiremonLog, "failed to start the stream");
            
            exitStatus = EXIT_FAILURE;
            goto cleanup;
        }
        
        FileSinkInit();
        os_log_info(DiremonLog, "entering run loop");
        CFRunLoopRun();
        os_log_info(DiremonLog, "exited run loop, cleanup\n");
        os_log_debug(DiremonLog, "flushing the stream");
        // Perform a synchronous flush to ensure all pending events are processed
        // before stopping the stream. Note: This call may block the thread.
        FSEventStreamFlushSync(fsEventStream);
        prefSaveDiremonState(fsEventStream);
        FSEventStreamStop(fsEventStream);
        FSEventStreamInvalidate(fsEventStream);
    cleanup:
        FSEventStreamRelease(fsEventStream);
        CFRelease(pathsToMonitor);
    }
    
    return exitStatus;
}
