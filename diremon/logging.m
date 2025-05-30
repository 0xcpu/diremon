//
//  logging.m
//  diremon
//
//  Created by cpu on 28.05.2025.
//

#import "logging.h"

os_log_t DiremonLog;

void LoggingInit(void)
{
    DiremonLog = os_log_create("com.cpu.diremon", "monitor");
}
