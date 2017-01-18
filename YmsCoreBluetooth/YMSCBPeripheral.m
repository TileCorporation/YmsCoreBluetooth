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

#import "YMSCBCentralManager.h"
#import "YMSCBPeripheral.h"
#import "YMSCBService.h"
#import "YMSCBCharacteristic.h"
#import "YMSCBDescriptor.h"
#import "NSMutableArray+fifoQueue.h"
#import "YMSCBNativePeripheral.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSCBPeripheral ()
@property (atomic, copy, nullable) NSData *lastValue;
@property (atomic, assign) BOOL valueValid;

@end

@implementation YMSCBPeripheral

- (nullable instancetype)initWithPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface
                                    central:(YMSCBCentralManager *)owner
                                     baseHi:(int64_t)hi
                                     baseLo:(int64_t)lo {
    
    self = [super init];
    
    if (self) {
        _central = owner;
        _base.hi = hi;
        _base.lo = lo;

        _peripheralInterface = peripheralInterface;
        _peripheralInterface.delegate = self;

        _rssiPingPeriod = 2.0;
        _watchdogTimerInterval = 5.0;
        _logger = _central.logger;
    }

    return self;
}


#pragma mark - Peripheral Methods

- (nullable NSString *)name {
    NSString *result = nil;
    if (_peripheralInterface) {
        result = _peripheralInterface.name;
    }
    
    return result;
}

- (CBPeripheralState)state {
    CBPeripheralState state;
    state = _peripheralInterface.state;
    return state;
}

- (nullable NSUUID *)identifier {
    NSUUID *result = nil;
    if (_peripheralInterface) {
        result = _peripheralInterface.identifier;
    }
    return result;
}


- (BOOL)isConnected {
    BOOL result = NO;
    
    if (self.state == CBPeripheralStateConnected) {
        result = YES;
    }
    
    return result;
}

//// TODO: is this needed?
//- (void)replaceCBPeripheral:(CBPeripheral *)peripheral {
//    /*
//    for (NSString *key in self.serviceDict) {
//        YMSCBService *service = self.serviceDict[key];
//        service.cbService = nil;
//        
//        for (NSString *chKey in service.characteristicDict) {
//            YMSCBCharacteristic *ct = service.characteristicDict[chKey];
//            ct.cbCharacteristic = nil;
//        }
//    }
//    
//    _peripheralInterface = peripheral;
//    peripheral.delegate = self;
//     */
//}


- (nullable id)objectForKeyedSubscript:(id)key {
    return self.serviceDict[key];
}


- (NSArray<CBUUID *> *)serviceUUIDs {
    NSArray<CBUUID *> *result;
    
    NSMutableArray<CBUUID *> *tempArray = [NSMutableArray new];

    for (NSString *key in self.serviceDict) {
        YMSCBService *service = self.serviceDict[key];
        [tempArray addObject:service.uuid];
    }

    result = [NSArray arrayWithArray:tempArray];
    return result;
}

- (NSArray<CBUUID *> *)servicesSubset:(NSArray<NSString *> *)keys {

    NSArray<CBUUID *> *result = nil;
    NSMutableArray<CBUUID *> *tempArray = [[NSMutableArray alloc] initWithCapacity:keys.count];
    
    for (NSString *key in keys) {
        YMSCBService *btService = self[key];
        
        if (btService) {
            [tempArray addObject:btService.uuid];
        } else {
            NSString *message = [NSString stringWithFormat:@"WARNING: service key %@ not found in servicesSubset", key];
            [self.logger logWarn:message object:_peripheralInterface];
        }
    }
    
    result = [NSArray arrayWithArray:tempArray];
    return result;
}

- (nullable YMSCBService *)findService:(CBService *)service {
    YMSCBService *result;
    
    for (NSString *key in self.serviceDict) {
        YMSCBService *btService = self.serviceDict[key];
        
        if ([service.UUID isEqual:btService.uuid]) {
            result = btService;
            break;
        }
        
    }
    return result;
}

#pragma mark - Connection Methods

- (void)connect {
    // Watchdog aware method
    [self resetWatchdog];

    [self connectWithOptions:nil withBlock:^(YMSCBPeripheral *yp, NSError *error) {
        if (error) {
            return;
        }

        [yp discoverServices:[yp serviceUUIDs] withBlock:^(NSArray *yservices, NSError *error) {
            if (error) {
                return;
            }
            
            for (YMSCBService *service in yservices) {
                __weak YMSCBService *thisService = (YMSCBService *)service;
                
                [service discoverCharacteristics:[service characteristics] withBlock:^(NSDictionary *chDict, NSError *error) {
                    if (error) {
                        return;
                    }

                    for (NSString *key in chDict) {
                        YMSCBCharacteristic *ct = chDict[key];
                        //NSLog(@"%@ %@ %@", ct, ct.cbCharacteristic, ct.uuid);
                        
                        [ct discoverDescriptorsWithBlock:^(NSArray *ydescriptors, NSError *error) {
                            if (error) {
                                return;
                            }
                            for (YMSCBDescriptor *yd in ydescriptors) {
                                NSLog(@"Descriptor: %@ %@ %@", thisService.name, yd.UUID, yd.descriptorInterface);
                            }
                        }];
                    }
                }];
            }
        }];
    }];
}


- (void)disconnect {
    // Watchdog aware method
    if (self.watchdogTimer) {
        [self.watchdogTimer invalidate];
        self.watchdogTimer = nil;
    }

    [self cancelConnection];
}

- (void)resetWatchdog {
    [self invalidateWatchdog];

    NSTimer *timer = [NSTimer timerWithTimeInterval:self.watchdogTimerInterval
                                             target:self
                                           selector:@selector(watchdogDisconnect)
                                           userInfo:nil
                                            repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
    self.watchdogTimer = timer;
}

- (void)invalidateWatchdog {
    if (self.watchdogTimer) {
        [self.watchdogTimer invalidate];
        self.watchdogTimer = nil;
        self.watchdogRaised = NO;
    }
}

- (void)watchdogDisconnect {
    // Watchdog aware method
    if (self.state != CBPeripheralStateConnected) {
        self.watchdogRaised = YES;
        [self disconnect];
    }
    self.watchdogTimer = nil;
}

- (void)connectWithOptions:(nullable NSDictionary *)options withBlock:(nullable void (^)(YMSCBPeripheral * _Nonnull yp, NSError * _Nullable error))connectCallback {
    NSString *message = [NSString stringWithFormat:@"> connectPeripheral: %@", _peripheralInterface];
    [self.logger logInfo:message object:self.central];
    
    self.connectCallback = connectCallback;
    
    [self.central connectPeripheral:self options:options];
}


- (void)cancelConnection {
    if (self.connectCallback) {
        self.connectCallback = nil;
    }
    
    NSString *message = [NSString stringWithFormat:@"> cancelPeripheralConnection: %@", _peripheralInterface];
    [self.logger logInfo:message object:self.central];
    
    [self.logger logInfo:message object:_peripheralInterface];
    [self.central cancelPeripheralConnection:self];
}


- (void)handleConnectionResponse:(nullable NSError *)error {
    YMSCBPeripheralConnectCallbackBlockType callback = [self.connectCallback copy];
    
    [self invalidateWatchdog];
    
    if (callback) {
        callback(self, error);
        self.connectCallback = nil;
        
    } else {
        [self defaultConnectionHandler];
    }
}

- (void)defaultConnectionHandler {
    NSAssert(NO, @"[YMSCBPeripheral defaultConnectionHandler] must be overridden if connectCallback is nil.");
}

- (void)readRSSI {
    NSString *message = [NSString stringWithFormat:@"> readRSSI"];
    [self.logger logInfo:message object:_peripheralInterface];
    
    [_peripheralInterface readRSSI];
}


- (void)reset {
    self.valueValid = NO;
    // TODO: who uses this? lastValue is very dangerous!
    self.lastValue = nil;
    self.connectCallback = nil;
    self.discoverServicesCallback = nil;
    
    [self invalidateWatchdog];
    
    //self.watchdogTimerInterval = 5.0;
    self.watchdogRaised = NO;
    

    NSArray<YMSCBService *> *services = [self.serviceDict allValues];
    
    for (YMSCBService *service in services) {
        [service reset];
    }
    
    [self.peripheralInterface reset];
}


#pragma mark - Services Discovery

- (void)discoverServices:(nullable NSArray *)serviceUUIDs withBlock:(nullable void (^)(NSArray * _Nullable services, NSError * _Nullable error))callback {
    self.discoverServicesCallback = callback;
    
    
    NSMutableArray *bufArray = [NSMutableArray new];
    [serviceUUIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [bufArray addObject:[NSString stringWithFormat:@"%@", obj]];
    }];
    
    NSString *buf = [bufArray componentsJoinedByString:@","];
    NSString *message = [NSString stringWithFormat:@"> discoverServices: [%@]", buf];
    [self.logger logInfo:message object:_peripheralInterface];
    
    [_peripheralInterface discoverServices:serviceUUIDs];
}


#pragma mark - YMSCBPeripheralInterfaceDelegate Methods
/** @name YMSCBPeripheralDelegate Methods */
/**
 YMSCBPeripheralDelegate implementation.
 
 @param peripheral The peripheral that the services belong to.
 @param error If an error occurred, the cause of the failure.
 */



- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverServices:(nullable NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< didDiscoverServices:%@", error.description];
    [self.logger logInfo:message object:_peripheralInterface];
    
    if (self.discoverServicesCallback) {
        NSArray<YMSCBService *> *tempArray = [self.serviceDict allValues];
        NSMutableArray<YMSCBService *> *services = [NSMutableArray new];
        
        for (id<YMSCBServiceInterface> serviceInterface in peripheralInterface.services) {
            for (YMSCBService *yService in tempArray) {
                if ([serviceInterface.UUID isEqual:yService.uuid]) {
                    yService.serviceInterface = serviceInterface;
                    serviceInterface.owner = yService;
                    [services addObject:yService];
                    break;
                }
            }
        }
        
        self.discoverServicesCallback(services, error);
        self.discoverServicesCallback = nil;

    }
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)]) {
        [self.delegate peripheral:self didDiscoverServices:error];
    }
}

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverCharacteristicsForService:(id<YMSCBServiceInterface>)serviceInterface error:(nullable NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< didDiscoverCharacteristicsForService: %@ error:%@", serviceInterface, error.description];
    [self.logger logInfo:message object:_peripheralInterface];
    
    
    YMSCBService *yService = serviceInterface.owner;
    
    [yService syncCharacteristics];
    [yService handleDiscoveredCharacteristicsResponse:yService.characteristicDict withError:error];

    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
        [self.delegate peripheral:self didDiscoverCharacteristicsForService:yService error:error];
    }
}


/**
 CBPeripheralDelegate implementation.  Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param service The CBService object containing the included service.
 @param error If an error occured, the cause of the failure.
 */
//- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error {
//    // TBD
//    NSString *message = [NSString stringWithFormat:@"< didDiscoverIncludedServicesForService: %@ error:%@", service, error.description];
//    [self.logger logInfo:message object:_peripheralInterface];
//    
//    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverIncludedServicesForService:error:)]) {
//        //[self.delegate peripheral:peripheral didDiscoverIncludedServicesForService:service error:error];
//    }
//}



/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic that the characteristic descriptors belong to.
 @param error If an error occured, the cause of the failure.
 */
//- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
//     NSString *message = [NSString stringWithFormat:@"< didDiscoverDescriptorsForCharacteristic: %@ error:%@", characteristic, error.description];
//    [self.logger logInfo:message object:_peripheralInterface];
//    
//    YMSCBService *btService = [self findService:characteristic.service];
//    YMSCBCharacteristic *ct = [btService findCharacteristic:characteristic];
//    
//    [ct syncDescriptors:characteristic.descriptors];
//    [ct handleDiscoveredDescriptorsResponse:ct.descriptors withError:error];
//    
//    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)]) {
////        [self.delegate peripheral:_peripheralInterface didDiscoverDescriptorsForCharacteristic:ct.cbCharacteristic error:error];
//    }
//}


/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didUpdateValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error {
    
    NSString *message = [NSString stringWithFormat:@"< didUpdateValueForCharacteristic:%@ error:%@", characteristicInterface, error];
    [self.logger logInfo:message object:_peripheralInterface];
    
    if (!self.valueValid) {
        self.valueValid = YES;
    }
    
    YMSCBCharacteristic *ct = characteristicInterface.owner;

    if (ct.readCallbacks && (ct.readCallbacks.count > 0)) {
        self.lastValue = [characteristicInterface.value copy];;
        [ct executeReadCallback:self.lastValue error:error];
        
        if (characteristicInterface.isNotifying) {
            message = [NSString stringWithFormat:@"Read callback called for notifying characteristic %@", characteristicInterface];
            [self.logger logWarn:message object:_peripheralInterface];
             
        }
    } else {
        if (characteristicInterface.isNotifying) {
            BOOL runNotificationCallback = NO;
            
            if (self.valueValid && (!self.lastValue || ![self.lastValue isEqualToData:characteristicInterface.value])) {
                runNotificationCallback = YES;
            }
            
            if (runNotificationCallback && ct.notificationCallback) {
                ct.notificationCallback(characteristicInterface.value, error);
            } else {
                message = [NSString stringWithFormat:@"No notification callback defined for %@", characteristicInterface];
                [self.logger logWarn:message object:_peripheralInterface];
            }
            
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]) {
        [self.delegate peripheral:self didUpdateValueForCharacteristic:ct error:error];
    }
    
}


/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param descriptor The characteristic descriptor whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
//- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
//    NSString *message = [NSString stringWithFormat:@"< didUpdateValueForDescriptor:%@ error:%@", descriptor, error.description];
//    [self.logger logInfo:message object:_peripheralInterface];
//    
//    // TBD
//    
//    if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)]) {
////        [self.delegate peripheral:_peripheralInterface didUpdateValueForDescriptor:descriptor error:error];
//    }
//}

/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didUpdateNotificationStateForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error {
    
    NSString *message = [NSString stringWithFormat:@"< didUpdateNotificationStateForCharacteristic: %@ error:%@", characteristicInterface, error.description];
    [self.logger logInfo:message object:_peripheralInterface];
    
    YMSCBCharacteristic *ct = characteristicInterface.owner;
    
    [ct executeNotificationStateCallback:error];
    if (!characteristicInterface.isNotifying) {
        ct.notificationCallback = nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]) {
        [self.delegate peripheral:self didUpdateNotificationStateForCharacteristic:characteristicInterface.owner error:error];
    }
}


/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didWriteValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error {
    
    NSString *message = [NSString stringWithFormat:@"< didWriteValueForCharacteristic: %@ error:%@", characteristicInterface, error.description];
    [self.logger logInfo:message object:_peripheralInterface];
    
    YMSCBCharacteristic *ct = characteristicInterface.owner;
    
    if (ct.writeCallbacks && (ct.writeCallbacks.count > 0)) {
        [ct executeWriteCallback:error];
    } else {
        
    }
    
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
        [self.delegate peripheral:self didWriteValueForCharacteristic:ct error:error];
    }

}


//- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
//    NSString *message = [NSString stringWithFormat:@"< didWriteValueForCharacteristic: %@ error:%@", characteristic, error.description];
//    [self.logger logInfo:message object:_peripheralInterface];
//
//    YMSCBService *btService = [self findService:characteristic.service];
//    YMSCBCharacteristic *ct = [btService findCharacteristic:characteristic];
//    
//    if (ct.writeCallbacks && (ct.writeCallbacks.count > 0)) {
//        [ct executeWriteCallback:error];
//    } else {
//        //message = [NSString stringWithFormat:@"No write callback in didWriteValueForCharacteristic:%@ for peripheral %@", characteristic, peripheral];
//        //TILAssert(NO, message);
//    }
//    
//    if ([self.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
//       // [self.delegate peripheral:_peripheralInterface didWriteValueForCharacteristic:ct.cbCharacteristic error:error];
//    }
//}


/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param descriptor The characteristic descriptor whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didWriteValueForDescriptor:(id<YMSCBDescriptorInterface>)descriptorInterface error:(nullable NSError *)error {
    
}

//- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
//    NSString *message = [NSString stringWithFormat:@"< didWriteValueForDescriptor: %@ error:%@", descriptor, error.description];
//    [self.logger logInfo:message object:_peripheralInterface];
//    
//    if ([self.delegate respondsToSelector:@selector(peripheral:didWriteValueForDescriptor:error:)]) {
//       // [self.delegate peripheral:_peripheralInterface didWriteValueForDescriptor:descriptor error:error];
//    }
//}



#if TARGET_OS_IPHONE

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< peripheral: %@ didReadRSSI: %@ error:%@", _peripheralInterface, RSSI, error];
    [self.logger logInfo:message object:nil];
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didReadRSSI:error:)]) {
        [self.delegate peripheral:self didReadRSSI:RSSI error:error];
    }
}

#else

/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param error If an error occured, the cause of the failure.
 */
//- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(nullable NSError *)error {
//    
//    NSString *message = [NSString stringWithFormat:@"< peripheralDidUpdateRSSI: %@ error:%@", _peripheralInterface, error.description];
//    [self.logger logInfo:message object:nil];
//    
//    if ([self.delegate respondsToSelector:@selector(peripheralDidUpdateRSSI:error:)]) {
//      //  [self.delegate peripheralDidUpdateRSSI:peripheral error:error];
//    }
//}


#endif



/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 iOS only.
 
 @param peripheral The peripheral providing this information.
 */
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    NSString *message = [NSString stringWithFormat:@"< peripheralDidUpdateName: %@", _peripheralInterface];
    [self.logger logInfo:message object:nil];
    
    if ([self.delegate respondsToSelector:@selector(peripheralDidUpdateName:)]) {
        //[self.delegate peripheralDidUpdateName:_peripheralInterface];
    }
}


/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 iOS only.
 
 @param peripheral The peripheral providing this information.
 */
// debug
//- (void)peripheralDidInvalidateServices:(CBPeripheral *)peripheral {
//    [[TILLocalFileManager sharedManager] log:@"< peripheralDidInvalidateServices" peripheral:peripheral];
//#if TARGET_OS_IPHONE
//    // TBD
//
//    __weak YMSCBPeripheral *this = self;
//    _YMS_PERFORM_ON_MAIN_THREAD(^{
//        __strong typeof(this) strongThis = this;
//        if ([strongThis.delegate respondsToSelector:@selector(peripheralDidInvalidateServices:)]) {
//            [strongThis.delegate peripheralDidInvalidateServices:strongThis.cbPeripheral];
//        }
//    });
//#endif
//}
// debug


- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices {
    NSString *message = [NSString stringWithFormat:@"< didModifyServices: %@", invalidatedServices];
    [self.logger logInfo:message object:_peripheralInterface];

    if ([self.delegate respondsToSelector:@selector(peripheral:didModifyServices:)]) {
     //   [self.delegate peripheral:_peripheralInterface didModifyServices:invalidatedServices];
    }
}


@end

NS_ASSUME_NONNULL_END
