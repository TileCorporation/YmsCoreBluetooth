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
        _logEnabled = YES;
    }
    
    return self;
}


- (void)setNotifyValue:(BOOL)notifyValue
  withStateChangeBlock:(void (^)(NSError * _Nullable error))notifyStateCallback
 withNotificationBlock:(nullable void (^)(NSData *data, NSError * _Nullable error))notificationCallback {
    
    NSString *message = nil;
    NSError *error = nil;
    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:self.parent.peripheralInterface];
    
    if (!_characteristicInterface) {
        [objects addObject:self];
        [objects addObject:@(notifyValue)];
        
        message = @"No characteristicInterface in setNotifyValue:withStateChangeBlock:withNotificationBlock:";
        error = [self nilCBCharacteristicError:message];
    }
    
    if (error && notifyStateCallback) {
        notifyStateCallback(error);
        return;
        
    } else if (notifyStateCallback) {
        self.notificationStateCallback = notifyStateCallback;
    }
    
    if (notificationCallback) {
        [objects addObject:_characteristicInterface];
        [objects addObject:@(notifyValue)];
        
        if (!notifyValue) {
            message = @"Attempt to unsubscribe CBCharacteristic with notificationCallback defined";
            [self.logger logWarn:message objects:objects];
            
            self.notificationCallback = nil;
        } else {
            self.notificationCallback = notificationCallback;
        }
    }
    
    if (self.logEnabled) {
        message = @"setNotifyValue:forCharacteristic:";
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeRequest objects:objects];
    }

    [self.parent.peripheralInterface setNotifyValue:notifyValue forCharacteristic:self.characteristicInterface];
}


- (void)executeNotificationStateCallback:(nullable NSError *)error {
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
    NSError *error = nil;
    
    if (!data) {
        message = @"Attempt to write nil to CBCharacteristic";
        NSString *description = NSLocalizedString(message, nil);
        NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Illegal to write nil to %@", nil), self.characteristicInterface];
        NSString *recoverySuggestion = NSLocalizedString(@"Troubleshoot at once.", nil);
        
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: description,
                                    NSLocalizedFailureReasonErrorKey:  failureReason,
                                    NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion };
        
        error = [NSError errorWithDomain:kYMSCBErrorDomain
                                    code:1
                                userInfo:userInfo];
        
    } else if (!_characteristicInterface) {
        message = @"No characteristicInterface in writeValue:withBlock:";
        error = [self nilCBCharacteristicError:@"No characteristicInterface in writeValue:withBlock:"];

    }
    
    if (error) {
        if (writeCallback) {
            NSMutableArray *objects = [NSMutableArray new];
            [objects addObject:self.parent.peripheralInterface];
            if (_characteristicInterface) {
                [objects addObject:_characteristicInterface];
            } else {
                [objects addObject:self];
            }
            
            [self.logger logError:message phase:YMSCBLoggerPhaseTypeRequest objects:objects error:error];
            writeCallback(error);
        }
        return;
    } else {
        if (writeCallback) {
            message = @"writeValue:forCharacteristic:type:CBCharacteristicWriteWithResponse";
            [self.writeCallbacks push:[writeCallback copy]];
            [self.parent.peripheralInterface writeValue:data
                                      forCharacteristic:self.characteristicInterface
                                                   type:CBCharacteristicWriteWithResponse];
        } else {
            message = @"writeValue:forCharacteristic:type:CBCharacteristicWriteWithoutResponse";
            [self.parent.peripheralInterface writeValue:data
                                      forCharacteristic:self.characteristicInterface
                                                   type:CBCharacteristicWriteWithoutResponse];
        }
    }
    
    if (self.logEnabled) {
        NSMutableArray<id> *objects = [NSMutableArray new];
        [objects addObject:self.parent.peripheralInterface];
        [objects addObject:_characteristicInterface];
        if (data) {
            [objects addObject:data];
        }

        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeRequest objects:objects];
        
    }
}

- (void)writeByte:(int8_t)val withBlock:(void (^)(NSError *))writeCallback {
    NSData *data = [NSData dataWithBytes:&val length:1];
    [self writeValue:data withBlock:writeCallback];
}


- (void)readValueWithBlock:(void (^)(NSData *, NSError *))readCallback {
    
    NSString *message = nil;
    NSError *error = nil;
    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:self.parent.peripheralInterface];
    
    if (!_characteristicInterface) {
        [objects addObject:self];
        
        message = @"No characteristicInterface in readValueWithBlock:";
        error = [self nilCBCharacteristicError:message];
    }
    
    if (error && readCallback) {
        readCallback(nil, error);
        return;
    }

    [self.readCallbacks push:[readCallback copy]];
    
    if (self.logEnabled) {
        [objects addObject:_characteristicInterface];
        message = @"readValueForCharacteristic";
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeRequest objects:objects];
    }
    
    [self.parent.peripheralInterface readValueForCharacteristic:self.characteristicInterface];
}


- (void)executeReadCallback:(NSData *)data error:(nullable NSError *)error {
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

- (void)handleDiscoveredDescriptorsResponse:(NSArray *)ydescriptors withError:(nullable NSError *)error {
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
