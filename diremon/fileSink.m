//
//  fileSink.m
//  diremon
//
//  Created by cpu on 21.05.2025.
//

// FileSink.c
#import "stdio.h"
#import "logSink.h"

static FILE *logFile = NULL;

static void fileSend(const uint8_t *msg) {
    if (!logFile) logFile = fopen("/var/log/diremon/events.log", "a");
    if (logFile) {
        fprintf(logFile, "%s\n", msg);
        fflush(logFile);
    }
}

void FileSinkInit(void) {
    LogSinkInit(fileSend);
}
