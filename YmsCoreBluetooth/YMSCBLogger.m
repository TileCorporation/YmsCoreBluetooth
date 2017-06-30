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

- (NSString *)objectsString:(NSArray<id> *)objects {
    NSString *result = nil;
    
    if (objects && objects.count) {
        NSMutableArray *tempArray = [NSMutableArray new];
        
        for (id object in objects) {
            [tempArray addObject:[NSString stringWithFormat:@"%@", object]];
        }
        
        result = [tempArray componentsJoinedByString:@", "];
    }
    return result;
}

- (NSString *)phaseString:(YMSCBLoggerPhaseType)phase {
    NSString *result = nil;
    switch (phase) {
        case YMSCBLoggerPhaseTypeRequest:
            result = @">>";
            break;
            
        case YMSCBLoggerPhaseTypeResponse:
            result = @"<<";
            break;
            
        default:
            result = @"|";
            break;
    }
    
    return result;
}


// MARK: - logError

- (void)logError:(NSString *)message object:(id)object error:(NSError *)error {
    NSString *tempMessage = [NSString stringWithFormat:@"%@: %@", message, object];
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerErrorPrefix message:tempMessage object:error];
    NSLog(@"%@", buf);
}


- (void)logError:(NSString *)message objects:(NSArray<id> *)objects error:(NSError *)error {
    NSString *objectsString = [self objectsString:objects];
    NSString *tempMessage = [NSString stringWithFormat:@"%@: %@", message, objectsString];
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerErrorPrefix message:tempMessage object:error];
    NSLog(@"%@", buf);
}

- (void)logError:(NSString *)message phase:(uint8_t)phase object:(id)object error:(NSError *)error {
    NSString *tempMessage = nil;
    [NSString stringWithFormat:@"%@ %@, %@", [self phaseString:(YMSCBLoggerPhaseType)phase], message, object];
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerErrorPrefix message:tempMessage object:error];
    NSLog(@"%@", buf);
}

- (void)logError:(NSString *)message phase:(uint8_t)phase objects:(NSArray<id> *)objects error:(NSError *)error {
    NSString *objectsString = [self objectsString:objects];
    NSString *tempMessage = nil;
    [NSString stringWithFormat:@"%@ %@, %@", [self phaseString:(YMSCBLoggerPhaseType)phase], message, objectsString];
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerInfoPrefix message:tempMessage object:error];
    NSLog(@"%@", buf);
}

// MARK: - logWarn
- (void)logWarn:(NSString *)message object:(id)object {
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerWarnPrefix message:message object:object];
    NSLog(@"%@", buf);
}


- (void)logWarn:(NSString *)message objects:(NSArray<id> *)objects {
    NSString *objectsString = [self objectsString:objects];
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerWarnPrefix message:message object:objectsString];
    NSLog(@"%@", buf);
}


// MARK: - logInfo
- (void)logInfo:(NSString *)message object:(id)object {
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerInfoPrefix message:message object:object];
    NSLog(@"%@", buf);
}

- (void)logInfo:(NSString *)message objects:(NSArray<id> *)objects {
    NSString *objectsString = [self objectsString:objects];
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerInfoPrefix message:message object:objectsString];
    NSLog(@"%@", buf);
}


- (void)logInfo:(NSString *)message phase:(uint8_t)phase object:(id)object {
    NSString *tempMessage = nil;
    [NSString stringWithFormat:@"%@ %@", [self phaseString:(YMSCBLoggerPhaseType)phase], message];
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerInfoPrefix message:tempMessage object:object];
    NSLog(@"%@", buf);
}

- (void)logInfo:(NSString *)message phase:(uint8_t)phase objects:(NSArray<id> *)objects {
    NSString *objectsString = [self objectsString:objects];
    NSString *tempMessage = nil;
    [NSString stringWithFormat:@"%@ %@", [self phaseString:(YMSCBLoggerPhaseType)phase], message];
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerInfoPrefix message:tempMessage object:objectsString];
    NSLog(@"%@", buf);
}


// MARK: - logDebug
- (void)logDebug:(NSString *)message object:(id)object {
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerDebugPrefix message:message object:object];
    NSLog(@"%@", buf);
}

- (void)logDebug:(NSString *)message objects:(NSArray<id> *)objects {
    NSString *objectsString = [self objectsString:objects];
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerDebugPrefix message:message object:objectsString];
    NSLog(@"%@", buf);
}


// MARK: - logVerbose
- (void)logVerbose:(NSString *)message object:(id)object {
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerVerbosePrefix message:message object:object];
    NSLog(@"%@", buf);
}

- (void)logVerbose:(NSString *)message objects:(NSArray<id> *)objects {
    NSString *objectsString = [self objectsString:objects];
    NSString *buf = [self genLogStringWithPrefix:kYMSCBLoggerVerbosePrefix message:message object:objectsString];
    NSLog(@"%@", buf);
}


// MARK: -

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
