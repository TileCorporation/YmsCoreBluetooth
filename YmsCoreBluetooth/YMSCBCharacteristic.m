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

@interface YMSCBCharacteristic()
@property (nonatomic, strong) NSMutableDictionary *descriptorDict;


@end

@implementation YMSCBCharacteristic


- (instancetype)initWithName:(NSString *)oName parent:(YMSCBPeripheral *)pObj uuid:(CBUUID *)oUUID {

    self = [super init];
    
    if (self) {
        _name = oName;
        _parent = pObj;
        _UUID = oUUID;
        _writeCallbacks = [NSMutableArray new];
        _readCallbacks = [NSMutableArray new];
        _logger = _parent.logger;
        _descriptorDict = [NSMutableDictionary new];
    }
    
    return self;
}


- (void)setNotifyValue:(BOOL)notifyValue
  withStateChangeBlock:(void (^)(NSError * _Nullable error))notifyStateCallback
 withNotificationBlock:(nullable void (^)(NSData *data, NSError * _Nullable error))notificationCallback {

    if (notifyStateCallback) {
        self.notificationStateCallback = notifyStateCallback;
    }
    
    if (!self.characteristicInterface && notifyStateCallback) {
        notifyStateCallback([self nilCBCharacteristicError:NSLocalizedString(@"Diagnose in setNotifyValue:withStateChangeBlock:withNotificationBlock:", nil)]);
        return;
    }
    
    if (notificationCallback) {
        if (!notifyValue) {
            NSString *message = [NSString stringWithFormat:@"Attempt to unsubscribe from %@ with a notificationCallback defined", self.characteristicInterface];
            [self.logger logWarn:message object:self.parent];
            self.notificationCallback = nil;
        } else {
            self.notificationCallback = notificationCallback;
        }
    }
    
    NSString *message = [NSString stringWithFormat:@"> setNotifyValue:%@ forCharacteristic:%@", @(notifyValue), self.characteristicInterface];
    if (self.logEnabled) {
        [self.logger logInfo:message object:self.parent];
    }
    
    [self.parent.peripheralInterface setNotifyValue:notifyValue forCharacteristic:self.characteristicInterface];
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


- (void)writeValue:(NSData *)data withBlock:(nullable void (^)(NSError * _Nullable))writeCallback {
    NSString *message = nil;
    
    //TILAssert(data != nil, @"ERROR: call to writeValue with nil data to %@", self.characteristicInterface);
    
    if (writeCallback) {
        if (!self.characteristicInterface) {
            writeCallback([self nilCBCharacteristicError:NSLocalizedString(@"Diagnose write with response in writeValue:withBlock:", nil)]);
            return;
        }
        
        if (!data) {
            NSString *description = NSLocalizedString(@"Attempt to write nil to CBCharacteristic", nil);
            NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Illegal to write nil to %@", nil), self.characteristicInterface];
            NSString *recoverySuggestion = NSLocalizedString(@"Troubleshoot at once.", nil);
            
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: description,
                                        NSLocalizedFailureReasonErrorKey:  failureReason,
                                        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion };
            
            NSError *error = [NSError errorWithDomain:kYMSCBErrorDomain
                                                 code:1
                                             userInfo:userInfo];
            writeCallback(error);
            message = [NSString stringWithFormat:@"ERROR: call to writeValue with nil data to %@", self.characteristicInterface];
            
        } else {
            [self.writeCallbacks push:[writeCallback copy]];
            message = [NSString stringWithFormat:@"> writeValue:%@ forCharacteristic:%@ type:CBCharacteristicWriteWithResponse", data, self.characteristicInterface];
            [self.parent.peripheralInterface writeValue:data
                                      forCharacteristic:self.characteristicInterface
                                                   type:CBCharacteristicWriteWithResponse];
            
        }
    } else {
        if (!self.characteristicInterface) {
            NSString *message = [NSString stringWithFormat:@"ERROR: %@", [self nilCBCharacteristicError:NSLocalizedString(@"Diagnose write without response in writeValue:withBlock:", nil)]];
            [self.logger logError:message object:self.parent];
            return;
        }
        
        if (!data) {
            message = [NSString stringWithFormat:@"ERROR: call to writeValue with nil data to %@", self.characteristicInterface];
        } else {
            message = [NSString stringWithFormat:@"> writeValue:%@ forCharacteristic:%@ type:CBCharacteristicWriteWithoutResponse", data, self.characteristicInterface];
            [self.parent.peripheralInterface writeValue:data
                                      forCharacteristic:self.characteristicInterface
                                                   type:CBCharacteristicWriteWithoutResponse];
        }
    }
    if (self.logEnabled) {
        [self.logger logInfo:message object:self.parent];
    }
}

- (void)writeByte:(int8_t)val withBlock:(void (^)(NSError *))writeCallback {
    NSData *data = [NSData dataWithBytes:&val length:1];
    [self writeValue:data withBlock:writeCallback];
}


- (void)readValueWithBlock:(void (^)(NSData *, NSError *))readCallback {
    
    if (!self.characteristicInterface && readCallback) {
        readCallback(nil, [self nilCBCharacteristicError:NSLocalizedString(@"Diagnose in readValueWithBlock:", nil)]);
        return;
    }
    
    [self.readCallbacks push:[readCallback copy]];
    
    NSString *message = [NSString stringWithFormat:@"> readValueForCharacteristic:%@", self.characteristicInterface];
    if (self.logEnabled) {
        [self.logger logInfo:message object:self.parent];
    }
    
    [self.parent.peripheralInterface readValueForCharacteristic:self.characteristicInterface];
}


- (void)executeReadCallback:(NSData *)data error:(NSError *)error {
    YMSCBReadCallbackBlockType readCB = [self.readCallbacks pop];
    readCB(data, error);
}

- (void)executeWriteCallback:(nullable NSError *)error {
    YMSCBWriteCallbackBlockType writeCB = [self.writeCallbacks pop];
    writeCB(error);
}

- (void)discoverDescriptorsWithBlock:(void (^)(NSArray *, NSError *))callback {
    if (self.characteristicInterface) {
        self.discoverDescriptorsCallback = callback;
        [self.parent.peripheralInterface discoverDescriptorsForCharacteristic:self.characteristicInterface];

    } else {
        NSString *message = [NSString stringWithFormat:@"Attempt to discover descriptors with null characteristicInterface: '%@' for %@", self.name, self.UUID];
        [self.logger logWarn:message object:self];
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

- (void)syncDescriptors {
    NSArray<id<YMSCBDescriptorInterface>> *descriptorInterfaces = [self.characteristicInterface descriptors];
    
    for (id<YMSCBDescriptorInterface> descriptorInterface in descriptorInterfaces) {
        NSString *key = descriptorInterface.UUID.UUIDString;
        YMSCBDescriptor *yDescriptor = self.descriptorDict[key];
        if (!yDescriptor) {
            yDescriptor = [[YMSCBDescriptor alloc] init];
            self.descriptorDict[key] = yDescriptor;
        }
        
        yDescriptor.descriptorInterface = descriptorInterface;
    }
}


- (NSArray<YMSCBDescriptor *> *)descriptors {
    NSArray<YMSCBDescriptor *> *result = nil;
    result = [self.descriptorDict allValues];
    return result;
}

- (void)reset {
    [self.writeCallbacks removeAllObjects];
    [self.readCallbacks removeAllObjects];
    self.notificationCallback = nil;
    self.notificationStateCallback = nil;
    self.discoverDescriptorsCallback = nil;
    self.logEnabled = YES;
    
    // reset descriptors
    
    //[self.characteristicInterface reset];
}


// TODO: refactor
- (NSError *)nilCBCharacteristicError:(NSString *)recovery {
    NSString *description = [NSString stringWithFormat:NSLocalizedString(@"CBCharacteristic is nil", nil)];
    NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Attempt to invoke operation on nil CBCharacteristic: %@ (%@) on %@", nil), self.name, self.UUID, self.parent];
    
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: description,
                               NSLocalizedFailureReasonErrorKey : failureReason,
                               NSLocalizedRecoverySuggestionErrorKey: recovery
                               };
    
    NSError *error = [NSError errorWithDomain:kYMSCBErrorDomain code:kYMSCBErrorCodeNilCharacteristic userInfo:userInfo];
    return error;
}

@end
