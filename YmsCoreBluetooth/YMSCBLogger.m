//
// Copyright 2016 Yummy Melon Software LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Author: Charles Y. Choi <charles.choi@yummymelon.com>
//

#import "YMSCBLogger.h"

NSString *const kYMSCBLoggerErrorPrefix = @"BLE: ERROR";
NSString *const kYMSCBLoggerWarnPrefix = @"BLE: WARN";
NSString *const kYMSCBLoggerInfoPrefix = @"BLE";
NSString *const kYMSCBLoggerDebugPrefix = @"BLE: DEBUG";
NSString *const kYMSCBLoggerVerbosePrefix = @"BLE VERBOSE";

@implementation YMSCBLogger

- (void)logError:(NSString *)message object:(id)object {
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerErrorPrefix message:message object:object];
    NSLog(@"%@", buf);
}

- (void)logWarn:(NSString *)message object:(id)object {
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerWarnPrefix message:message object:object];
    NSLog(@"%@", buf);
}

- (void)logInfo:(NSString *)message object:(id)object {
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerInfoPrefix message:message object:object];
    NSLog(@"%@", buf);
}

- (void)logDebug:(NSString *)message object:(id)object {
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerDebugPrefix message:message object:object];
    NSLog(@"%@", buf);
}

- (void)logVerbose:(NSString *)message object:(id)object {
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerVerbosePrefix message:message object:object];
    NSLog(@"%@", buf);
}

- (NSString *)genLogStringWithPrefix:(NSString *)prefix message:(NSString *)message object:(id)object {
    NSString *buf = @"";
    NSString *tempBuf = nil;
    
    NSMutableArray *tempList = [NSMutableArray new];
    
    if (prefix && message) {
        tempBuf = [NSString stringWithFormat:@"%@: %@", prefix, message];
    } else if (!prefix && message) {
        tempBuf = [NSString stringWithFormat:@"%@", message];
    } else if (prefix && !message) {
        tempBuf = [NSString stringWithFormat:@"%@", prefix];
    } else {
        // nop
    }
    
    if (tempBuf) {
        [tempList addObject:tempBuf];
    }
    
    if (object) {
        tempBuf = [NSString stringWithFormat:@"%@", object];
        [tempList addObject:tempBuf];
    }
    
    buf = [tempList componentsJoinedByString:@", "];
    
    return buf;
}


@end
