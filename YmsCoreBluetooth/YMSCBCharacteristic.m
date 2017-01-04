// 
// Copyright 2013-2015 Yummy Melon Software LLC
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

#import "YMSCBCharacteristic.h"
#import "NSMutableArray+fifoQueue.h"
#import "YMSCBPeripheral.h"
#import "YMSCBDescriptor.h"

@implementation YMSCBCharacteristic


- (instancetype)initWithName:(NSString *)oName parent:(YMSCBPeripheral *)pObj uuid:(CBUUID *)oUUID offset:(int)addrOffset {

    self = [super init];
    
    if (self) {
        _name = oName;
        _parent = pObj;
        _uuid = oUUID;
        _offset = [NSNumber numberWithInt:addrOffset];
        _writeCallbacks = [NSMutableArray new];
        _readCallbacks = [NSMutableArray new];
    }
    
    return self;
}


- (void)setNotifyValue:(BOOL)notifyValue
  withStateChangeBlock:(void (^)(NSError * _Nullable error))notifyStateCallback
 withNotificationBlock:(nullable void (^)(NSData *data, NSError * _Nullable error))notificationCallback {

    if (notifyStateCallback) {
        self.notificationStateCallback = notifyStateCallback;
    }
    
    if (!self.cbCharacteristic && notifyStateCallback) {
        notifyStateCallback([self nilCBCharacteristicError:NSLocalizedString(@"Diagnose in setNotifyValue:withStateChangeBlock:withNotificationBlock:", nil)]);
        return;
    }
    
    if (notificationCallback) {
        if (!notifyValue) {
            //NSString *message = [NSString stringWithFormat:@"WARNING: attempt to unsubscribe from %@ with a notificationCallback defined", self.cbCharacteristic];
            //[[TILLocalFileManager sharedManager] log:message peripheral:self.parent.cbPeripheral];
            self.notificationCallback = nil;
        } else {
            self.notificationCallback = notificationCallback;
        }
    }
    
    //NSString *message = [NSString stringWithFormat:@"> setNotifyValue:%@ forCharacteristic:%@", @(notifyValue), self.cbCharacteristic];
    if (self.logEnabled) {
        //[[TILLocalFileManager sharedManager] log:message peripheral:self.parent.cbPeripheral];
    }
    [self.parent.cbPeripheral setNotifyValue:notifyValue forCharacteristic:self.cbCharacteristic];
}



- (void)executeNotificationStateCallback:(NSError *)error {
    YMSCBWriteCallbackBlockType callback = self.notificationStateCallback;
    
    if (self.notificationStateCallback) {
        if (callback) {
            callback(error);
        } else {
            NSAssert(NO, @"ERROR: notificationStateCallback is nil; please check for multi-threaded access of executeNotificationStateCallback");
        }
        self.notificationStateCallback = nil;
    }
}


- (void)writeValue:(NSData *)data withBlock:(void (^)(NSError *))writeCallback {
    NSString *message = nil;
    
    //TILAssert(data != nil, @"ERROR: call to writeValue with nil data to %@", self.cbCharacteristic);
    
    if (writeCallback) {
        if (!self.cbCharacteristic) {
            writeCallback([self nilCBCharacteristicError:NSLocalizedString(@"Diagnose write with response in writeValue:withBlock:", nil)]);
            return;
        }
        
        if (!data) {
            NSString *description = NSLocalizedString(@"Attempt to write nil to CBCharacteristic", nil);
            NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Illegal to write nil to %@", nil), self.cbCharacteristic];
            NSString *recoverySuggestion = NSLocalizedString(@"Troubleshoot at once.", nil);
            
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: description,
                                        NSLocalizedFailureReasonErrorKey:  failureReason,
                                        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion };
            
            NSError *error = [NSError errorWithDomain:kYMSCBErrorDomain
                                                 code:1
                                             userInfo:userInfo];
            writeCallback(error);
            message = [NSString stringWithFormat:@"ERROR: call to writeValue with nil data to %@", self.cbCharacteristic];
            
        } else {
            [self.writeCallbacks push:[writeCallback copy]];
            message = [NSString stringWithFormat:@"> writeValue:%@ forCharacteristic:%@ type:CBCharacteristicWriteWithResponse", data, self.cbCharacteristic];
            [self.parent.cbPeripheral writeValue:data
                               forCharacteristic:self.cbCharacteristic
                                            type:CBCharacteristicWriteWithResponse];
        }
    } else {
        if (!self.cbCharacteristic) {
            NSString *message = [NSString stringWithFormat:@"ERROR: %@", [self nilCBCharacteristicError:NSLocalizedString(@"Diagnose write without response in writeValue:withBlock:", nil)]];
            //[[TILLocalFileManager sharedManager] log:message peripheral:self.parent.cbPeripheral];
            return;
        }
        
        if (!data) {
            message = [NSString stringWithFormat:@"ERROR: call to writeValue with nil data to %@", self.cbCharacteristic];
        } else {
            message = [NSString stringWithFormat:@"> writeValue:%@ forCharacteristic:%@ type:CBCharacteristicWriteWithoutResponse", data, self.cbCharacteristic];
            [self.parent.cbPeripheral writeValue:data
                               forCharacteristic:self.cbCharacteristic
                                            type:CBCharacteristicWriteWithoutResponse];
        }
    }
    if (self.logEnabled) {
       // [[TILLocalFileManager sharedManager] log:message peripheral:self.parent.cbPeripheral];
    }

    
}

- (void)writeByte:(int8_t)val withBlock:(void (^)(NSError *))writeCallback {
    NSData *data = [NSData dataWithBytes:&val length:1];
    [self writeValue:data withBlock:writeCallback];
}


- (void)readValueWithBlock:(void (^)(NSData *, NSError *))readCallback {
    
    if (!self.cbCharacteristic && readCallback) {
        readCallback(nil, [self nilCBCharacteristicError:NSLocalizedString(@"Diagnose in readValueWithBlock:", nil)]);
        return;
    }
    
    [self.readCallbacks push:[readCallback copy]];
    
    NSString *message = [NSString stringWithFormat:@"> readValueForCharacteristic:%@", self.cbCharacteristic];
    if (self.logEnabled) {
//        [[TILLocalFileManager sharedManager] log:message peripheral:self.parent.cbPeripheral];
    }
    [self.parent.cbPeripheral readValueForCharacteristic:self.cbCharacteristic];
}


- (void)executeReadCallback:(NSData *)data error:(NSError *)error {
    YMSCBReadCallbackBlockType readCB = [self.readCallbacks pop];
    readCB(data, error);
}

- (void)executeWriteCallback:(NSError *)error {
    YMSCBWriteCallbackBlockType writeCB = [self.writeCallbacks pop];
    writeCB(error);
}

- (void)discoverDescriptorsWithBlock:(void (^)(NSArray *, NSError *))callback {
    if (self.cbCharacteristic) {
        self.discoverDescriptorsCallback = callback;
    
        [self.parent.cbPeripheral discoverDescriptorsForCharacteristic:self.cbCharacteristic];
    } else {
        NSLog(@"WARNING: Attempt to discover descriptors with null cbCharacteristic: '%@' for %@", self.name, self.uuid);
    }
}


- (void)handleDiscoveredDescriptorsResponse:(NSArray *)ydescriptors withError:(NSError *)error {
    YMSCBDiscoverDescriptorsCallbackBlockType callback = [self.discoverDescriptorsCallback copy];

    if (callback) {
        callback(ydescriptors, error);
        self.discoverDescriptorsCallback = nil;
    } else {
        NSAssert(NO, @"ERROR: discoverDescriptorsCallback is nil; please check for multi-threaded access of handleDiscoveredDescriptorsResponse");
    }
}

- (void)syncDescriptors:(NSArray *)foundDescriptors {
    
    NSMutableArray *tempList = [[NSMutableArray alloc] initWithCapacity:[foundDescriptors count]];
    
    for (CBDescriptor *cbDescriptor in foundDescriptors) {
        YMSCBDescriptor *yd = [YMSCBDescriptor new];
        yd.cbDescriptor = cbDescriptor;
        yd.parent = self.parent;
        [tempList addObject:yd];
    }
    
    self.descriptors = tempList;
}


- (void)reset {
    [self.writeCallbacks removeAllObjects];
    [self.readCallbacks removeAllObjects];
    self.cbCharacteristic = nil;
    self.notificationCallback = nil;
    self.notificationStateCallback = nil;
    self.discoverDescriptorsCallback = nil;
    self.logEnabled = YES;
}


- (NSError *)nilCBCharacteristicError:(NSString *)recovery {
    NSString *description = [NSString stringWithFormat:NSLocalizedString(@"CBCharacteristic is nil", nil)];
    NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Attempt to invoke operation on nil CBCharacteristic: %@ (%@) on %@", nil), self.name, self.uuid, self.parent.cbPeripheral];
    
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: description,
                               NSLocalizedFailureReasonErrorKey : failureReason,
                               NSLocalizedRecoverySuggestionErrorKey: recovery
                               };
    
    NSError *error = [NSError errorWithDomain:kYMSCBErrorDomain code:kYMSCBErrorCodeNilCharacteristic userInfo:userInfo];
    return error;
}

@end
