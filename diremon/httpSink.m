//
//  httpSink.m
//  diremon
//
//  Created by cpu on 13.06.2025.
//

#import "logSink.h"

static NSString *HttpEndpoint = nil;

static bool httpSend(NSData *msg) {
    if (!HttpEndpoint) {
        os_log_error(DiremonLog, "HTTP endpoint not configured");
        return false;
    }
    
    NSURL *url = [NSURL URLWithString:HttpEndpoint];
    if (!url) {
        os_log_error(DiremonLog, "Invalid HTTP endpoint URL: %@", HttpEndpoint);
        return false;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:msg];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block bool success = false;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            os_log_error(DiremonLog, "HTTP request failed: %@", error.localizedDescription);
        } else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                success = true;
                os_log_debug(DiremonLog, "HTTP request successful: %ld", (long)httpResponse.statusCode);
            } else {
                os_log_error(DiremonLog, "HTTP request failed with status: %ld", (long)httpResponse.statusCode);
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return success;
}

static void loadHttpConfiguration(void) {
    const char *endpoint = getenv("HTTP_LOG_ENDPOINT");
    if (endpoint) {
        HttpEndpoint = [NSString stringWithUTF8String:endpoint];
        os_log_info(DiremonLog, "HTTP log endpoint configured: %@", HttpEndpoint);
    } else {
        os_log_info(DiremonLog, "HTTP_LOG_ENDPOINT environment variable not set, HTTP sink disabled");
    }
}

void HttpSinkInit(void) {
    loadHttpConfiguration();
    if (HttpEndpoint) {
        LogSinkInit(httpSend);
        os_log_info(DiremonLog, "HTTP sink initialized");
    }
}
