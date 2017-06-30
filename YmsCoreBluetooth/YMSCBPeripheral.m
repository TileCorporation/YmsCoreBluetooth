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
#import "YMSCBNativeInterfaces.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSCBPeripheral ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, YMSCBService*> *serviceDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, YMSCBService*> *servicesByUUIDs;

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
        
        _serviceDict = [NSMutableDictionary new];
        _servicesByUUIDs = [NSMutableDictionary new];
    }

    return self;
}

- (nullable instancetype)initWithPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface
                                    central:(YMSCBCentralManager *)owner {
    
    self = [super init];
    
    if (self) {
        _central = owner;
        
        _peripheralInterface = peripheralInterface;
        _peripheralInterface.delegate = self;
        
        _rssiPingPeriod = 2.0;
        _watchdogTimerInterval = 5.0;
        _logger = _central.logger;
        
        _serviceDict = [NSMutableDictionary new];
        _servicesByUUIDs = [NSMutableDictionary new];
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

- (nullable YMSCBService *)objectForKeyedSubscript:(NSString *)key {
    YMSCBService *result = nil;
    result = self.serviceDict[key];
    return result;
}

- (void)setObject:(YMSCBService *)obj forKeyedSubscript:(NSString *)key {
    self.serviceDict[key] = obj;
    self.servicesByUUIDs[obj.UUID.UUIDString] = obj;
}

- (nullable YMSCBService *)serviceForUUID:(CBUUID *)uuid {
    YMSCBService *result = nil;
    result = self.servicesByUUIDs[uuid.UUIDString];
    return result;
}


- (nullable YMSCBCharacteristic *)characteristicForInterface:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    
    YMSCBCharacteristic *result = nil;
    id<YMSCBServiceInterface> serviceInterface = characteristicInterface.service;
    
    YMSCBService *service = [self serviceForUUID:serviceInterface.UUID];
    result = [service characteristicForUUID:characteristicInterface.UUID];
    
    return result;
}


- (NSArray<CBUUID *> *)serviceUUIDs {
    NSArray<CBUUID *> *result;

    NSArray<YMSCBService *> *services = [_serviceDict allValues];
    result = [services valueForKeyPath:@"UUID"];

    return result;
}

- (NSArray<CBUUID *> *)servicesSubset:(NSArray<NSString *> *)keys {

    NSArray<CBUUID *> *result = nil;
    NSMutableArray<CBUUID *> *tempArray = [[NSMutableArray alloc] initWithCapacity:keys.count];
    
    for (NSString *key in keys) {
        YMSCBService *btService = self[key];
        
        if (btService) {
            [tempArray addObject:btService.UUID];
        } else {
            NSString *message = [NSString stringWithFormat:@"service key %@ not found in servicesSubset", key];
            [self.logger logWarn:message object:_peripheralInterface];
        }
    }
    
    result = [NSArray arrayWithArray:tempArray];
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
                
                [service discoverCharacteristics:[service characteristicUUIDs] withBlock:^(NSDictionary *chDict, NSError *error) {
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

- (void)connectWithOptions:(nullable NSDictionary *)options withBlock:(void (^)(YMSCBPeripheral * _Nullable yp, NSError * _Nullable error))connectCallback {
    if (!self.connectCallback) {
        NSString *message = @"connectPeripheral";
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeRequest object:_peripheralInterface];
        
        self.connectCallback = connectCallback;
        [self.central connectPeripheral:self options:options];
    } else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Connection request conflict", nil),
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"A connection request to this peripheral is already underway.", nil),
                                   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Wait for previous connection request to complete or cancel connection and retry.", nil)
                                   };
        NSError *error = [NSError errorWithDomain:kYMSCBErrorDomain
                                             code:409
                                         userInfo:userInfo];
        
        connectCallback(nil, error);
    }
}


- (void)cancelConnection {
    if (self.connectCallback) {
        self.connectCallback = nil;
    }
    NSString *message = @"cancelPeripheralConnection";
    [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeRequest object:_peripheralInterface];
    [self.central cancelPeripheralConnection:self];
}

- (void)didConnectPeripheral {
    [self invalidateWatchdog];
    
    if (self.connectCallback) {
        self.connectCallback(self, nil);
        self.connectCallback = nil;
    }
}

- (void)didDisconnectPeripheral:(nullable NSError *)error {
    [self reset];
    
}

- (void)didFailToConnectPeripheral:(nullable NSError *)error {
    [self reset];
}

- (void)didDiscoverPeripheralWithAdvertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    // !!!: `advertisementData` and RSSI are not persisted at this level. It is up to the subclass implementation to determine whether to persist this information.
}

- (void)readRSSI {
    NSString *message = @"readRSSI";
    [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeRequest object:_peripheralInterface];
    [_peripheralInterface readRSSI];
}

- (void)reset {
    self.connectCallback = nil;
    self.discoverServicesCallback = nil;
    
    [self invalidateWatchdog];
    
    //self.watchdogTimerInterval = 5.0;
    self.watchdogRaised = NO;
    

    NSArray<YMSCBService *> *services = [self.serviceDict allValues];
    
    for (YMSCBService *service in services) {
        [service reset];
    }
    
}


- (nullable NSArray<YMSCBService *> *)services {
    NSArray<YMSCBService *> *result = nil;
    result = [self.serviceDict allValues];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"serviceInterface != NULL"];
    result = [result filteredArrayUsingPredicate:predicate];

    return result;
}


#pragma mark - Services Discovery

- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs withBlock:(nullable void (^)(NSArray * _Nullable services, NSError * _Nullable error))callback {
    self.discoverServicesCallback = callback;

    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:_peripheralInterface];
    [objects addObjectsFromArray:serviceUUIDs];
    NSString *message = @"discoverServices";
    [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeRequest objects:objects];
    
    [_peripheralInterface discoverServices:serviceUUIDs];
}

- (void)syncServices:(NSArray<id<YMSCBServiceInterface>> *)services {
    for (id<YMSCBServiceInterface> cbService in services) {
        YMSCBService *service = [self serviceForUUID:cbService.UUID];
        if (service) {
            service.serviceInterface = cbService;
            [service syncWithCharacteristics:cbService.characteristics];
        }
    }
}

#pragma mark - YMSCBPeripheralInterfaceDelegate Methods

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverServices:(nullable NSError *)error {
    NSString *message = @"didDiscoverServices";
    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:_peripheralInterface];
    [objects addObjectsFromArray:peripheralInterface.services];

    if (error) {
        [self.logger logError:message phase:YMSCBLoggerPhaseTypeResponse objects:objects error:error];
    } else {
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeResponse objects:objects];
    }
    
    if (self.discoverServicesCallback) {
        // User defined services
        NSArray<NSString *> *expectedServiceUUIDs = [self.servicesByUUIDs allKeys];
        // Actual services on the CBPeripheral
        NSArray<NSString *> *actualServiceUUIDs = [[peripheralInterface services] valueForKeyPath:@"UUID.UUIDString"];
        
        NSSet<NSString *> *expectedUUIDs = [NSMutableSet setWithArray:expectedServiceUUIDs];
        NSSet<NSString *> *actualUUIDs = [NSMutableSet setWithArray:actualServiceUUIDs];
        
        NSMutableSet<NSString *> *missingUUIDs = [expectedUUIDs mutableCopy];
        NSMutableSet<NSString *> *addedUUIDs = [actualUUIDs mutableCopy];
        
        // Find missing UUIDs
        [missingUUIDs minusSet:actualUUIDs];
        // Find added UUIDs
        [addedUUIDs minusSet:expectedUUIDs];
        
        // Remove missing keys from self.serviceDict and self.servicesByUUIDs
        [self.servicesByUUIDs removeObjectsForKeys:[missingUUIDs allObjects]];

        NSMutableArray<NSString *> *servicesToRemove = [NSMutableArray new];
        for (NSString *key in missingUUIDs) {
            [self.serviceDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull serviceKey, YMSCBService * _Nonnull service, BOOL * _Nonnull stop) {
                if ([key isEqualToString:service.UUID.UUIDString]) {
                    [servicesToRemove addObject:serviceKey];
                }
            }];
        }
        [self.serviceDict removeObjectsForKeys:servicesToRemove];
        
        // Add added keys to self.serviceDict and self.servicesByUUIDs
        for (NSString *UUID in addedUUIDs) {
            YMSCBService *service = [[YMSCBService alloc] initWithUUID:UUID parent:self];
            self[UUID] = service;
        }

        // Set the serviceInterface
        for (id<YMSCBServiceInterface> serviceInterface in peripheralInterface.services) {
            YMSCBService *service = self.servicesByUUIDs[serviceInterface.UUID.UUIDString];
            service.serviceInterface = serviceInterface;
        }
        
        NSArray<YMSCBService *> *services = [self.serviceDict allValues];
        self.discoverServicesCallback(services, error);
        self.discoverServicesCallback = nil;
    }

    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)]) {
        [self.delegate peripheral:self didDiscoverServices:error];
    }
}

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverCharacteristicsForService:(id<YMSCBServiceInterface>)serviceInterface error:(nullable NSError *)error {
    NSString *message = @"didDiscoverCharacteristicsForService";
    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:_peripheralInterface];
    [objects addObject:serviceInterface];
    [objects addObjectsFromArray:serviceInterface.characteristics];

    if (error) {
        [self.logger logError:message phase:YMSCBLoggerPhaseTypeResponse objects:objects error:error];
    } else {
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeResponse objects:objects];
    }

    YMSCBService *yService = [self serviceForUUID:serviceInterface.UUID];

    [yService syncWithCharacteristics:[serviceInterface characteristics]];
    [yService handleDiscoveredCharacteristicsResponse:yService.characteristicDict withError:error];
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
        [self.delegate peripheral:self didDiscoverCharacteristicsForService:yService error:error];
    }
}


//- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error {
//    // TBD
//    NSString *message = [NSString stringWithFormat:@"< didDiscoverIncludedServicesForService: %@ error:%@", service, error.description];
//    [self.logger logInfo:message object:_peripheralInterface];
//    
//    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverIncludedServicesForService:error:)]) {
//        //[self.delegate peripheral:peripheral didDiscoverIncludedServicesForService:service error:error];
//    }
//}



- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverDescriptorsForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error {
    NSString *message = @"didDiscoverDescriptorsForCharacteristic";
    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:_peripheralInterface];
    [objects addObject:characteristicInterface];
    [objects addObjectsFromArray:characteristicInterface.descriptors];
    
    if (error) {
        [self.logger logError:message phase:YMSCBLoggerPhaseTypeResponse objects:objects error:error];
    } else {
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeResponse objects:objects];
    }
    
    YMSCBCharacteristic *yCharacteristic = [self characteristicForInterface:characteristicInterface];

    [yCharacteristic syncDescriptors];
    [yCharacteristic handleDiscoveredDescriptorsResponse:yCharacteristic.descriptors withError:error];
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)]) {
        [self.delegate peripheral:self didDiscoverDescriptorsForCharacteristic:yCharacteristic error:error];
    }
}



- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didUpdateValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error {
    NSString *message = @"didUpdateValueForCharacteristic";
    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:_peripheralInterface];
    [objects addObject:characteristicInterface];
    
    if (error) {
        [self.logger logError:message phase:YMSCBLoggerPhaseTypeResponse objects:objects error:error];
    } else {
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeResponse objects:objects];
    }

    YMSCBCharacteristic *ct = [self characteristicForInterface:characteristicInterface];
    NSData *value = [characteristicInterface.value copy];

    if (ct.readCallbacks && (ct.readCallbacks.count > 0)) {
        [ct executeReadCallback:value error:error];
        
        if (characteristicInterface.isNotifying) {
            message = @"Read callback called for notifying characteristic";
            [self.logger logWarn:message objects:objects];
             
        }
    } else {
        if (characteristicInterface.isNotifying) {
            if (ct.notificationCallback) {
                ct.notificationCallback(value, error);
            } else {
                message = @"No notification callback defined";
                [self.logger logWarn:message objects:objects];
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



- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didUpdateNotificationStateForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error {
    NSString *message = @"didUpdateNotificationStateForCharacteristic";
    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:_peripheralInterface];
    [objects addObject:characteristicInterface];
    
    if (error) {
        [self.logger logError:message phase:YMSCBLoggerPhaseTypeResponse objects:objects error:error];
    } else {
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeResponse objects:objects];
    }
    
    YMSCBCharacteristic *ct = [self characteristicForInterface:characteristicInterface];
    
    [ct executeNotificationStateCallback:error];
    if (!characteristicInterface.isNotifying) {
        ct.notificationCallback = nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]) {
        [self.delegate peripheral:self didUpdateNotificationStateForCharacteristic:ct error:error];
    }
}



- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didWriteValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error {
    NSString *message = @"didWriteValueForCharacteristic";
    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:_peripheralInterface];
    [objects addObject:characteristicInterface];
    
    if (error) {
        [self.logger logError:message phase:YMSCBLoggerPhaseTypeResponse objects:objects error:error];
    } else {
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeResponse objects:objects];
    }

    YMSCBCharacteristic *ct = [self characteristicForInterface:characteristicInterface];
    
    if (ct.writeCallbacks && (ct.writeCallbacks.count > 0)) {
        [ct executeWriteCallback:error];
    } else {
        
    }
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
        [self.delegate peripheral:self didWriteValueForCharacteristic:ct error:error];
    }

}


/**
 CBPeripheralDelegate implementation. Not yet supported.

 @param peripheralInterface The peripheral providing this information.
 @param descriptorInterface The characteristic descriptor whose value has been retrieved.
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
    NSString *message = @"didReadRSSI";
    NSMutableArray<id> *objects = [NSMutableArray new];
    [objects addObject:_peripheralInterface];
    [objects addObject:RSSI];
    
    if (error) {
        [self.logger logError:message phase:YMSCBLoggerPhaseTypeResponse objects:objects error:error];
    } else {
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeResponse objects:objects];
    }

    
    if ([self.delegate respondsToSelector:@selector(peripheral:didReadRSSI:error:)]) {
        [self.delegate peripheral:self didReadRSSI:RSSI error:error];
    }
}

#else

- (void)peripheralDidUpdateRSSI:(id<YMSCBPeripheralInterface>)peripheralInterface error:(nullable NSError *)error {
    NSString *message = @"peripheralDidUpdateRSSI";
    
    if (error) {
        [self.logger logError:message phase:YMSCBLoggerPhaseTypeResponse object:peripheralInterface error:error];
    } else {
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeResponse object:peripheralInterface];
    }
    
    if ([self.delegate respondsToSelector:@selector(peripheralDidUpdateRSSI:error:)]) {
        [self.delegate peripheralDidUpdateRSSI:self error:error];
    }
}

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

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    NSString *message = [NSString stringWithFormat:@"< peripheralDidUpdateName: %@", _peripheralInterface];
    [self.logger logInfo:message object:nil];
    
    if ([self.delegate respondsToSelector:@selector(peripheralDidUpdateName:)]) {
        [self.delegate peripheralDidUpdateName:self];
    }
}

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didModifyServices:(NSArray<id<YMSCBServiceInterface>> *)invalidatedServices {
    NSString *message = [NSString stringWithFormat:@"< didModifyServices: %@", invalidatedServices];
    [self.logger logInfo:message object:_peripheralInterface];
    
    NSMutableArray<YMSCBService *> *tempArray = [NSMutableArray new];
    
    for (id<YMSCBServiceInterface> serviceInterface in invalidatedServices) {
        YMSCBService *service = [self serviceForUUID:serviceInterface.UUID];
        [tempArray addObject:service];
    }
    
    NSArray<YMSCBService *> *invalidateYMSCBServices = [NSArray arrayWithArray:tempArray];

    if ([self.delegate respondsToSelector:@selector(peripheral:didModifyServices:)]) {
        [self.delegate peripheral:self didModifyServices:invalidateYMSCBServices];
    }
}


@end

NS_ASSUME_NONNULL_END
