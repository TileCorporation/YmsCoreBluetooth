// 
// Copyright 2013-2014 Yummy Melon Software LLC
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
#import "YMSLogManager.h"

@interface YMSCBPeripheral ()
@property (atomic, copy) NSData *lastValue;
@property (atomic, assign) BOOL valueValid;
@end

@implementation YMSCBPeripheral

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                           central:(YMSCBCentralManager *)owner
                            baseHi:(int64_t)hi
                            baseLo:(int64_t)lo {
    
    self = [super init];
    
    if (self) {
        _central = owner;
        _base.hi = hi;
        _base.lo = lo;
        
        _cbPeripheral = peripheral;
        peripheral.delegate = self;
        
        _rssiPingPeriod = 2.0;

        //_peripheralConnectionState = YMSCBPeripheralConnectionStateUnknown;
        _watchdogTimerInterval = 5.0;
    }

    return self;
}


#pragma mark - Peripheral Methods

- (NSString *)name {
    NSString *result = nil;
    if (self.cbPeripheral) {
        result = self.cbPeripheral.name;
    }
    
    return result;
}

- (BOOL)isConnected {
    
    BOOL result = NO;
    
    if (self.cbPeripheral.state == CBPeripheralStateConnected) {
        result = YES;
    }
    
    return result;
}


- (void)replaceCBPeripheral:(CBPeripheral *)peripheral {
    for (NSString *key in self.serviceDict) {
        YMSCBService *service = self.serviceDict[key];
        service.cbService = nil;
        
        for (NSString *chKey in service.characteristicDict) {
            YMSCBCharacteristic *ct = service.characteristicDict[chKey];
            ct.cbCharacteristic = nil;
        }
    }
    
    self.cbPeripheral = peripheral;
    peripheral.delegate = self;
}


- (id)objectForKeyedSubscript:(id)key {
    return self.serviceDict[key];
}


- (NSArray *)services {
    NSArray *result;
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    for (NSString *key in self.serviceDict) {
        YMSCBService *service = self.serviceDict[key];
        [tempArray addObject:service.uuid];
    }
    
    result = [NSArray arrayWithArray:tempArray];
    return result;
}

- (NSArray *)servicesSubset:(NSArray *)keys {
    NSArray *result = nil;
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:keys.count];
    
    for (NSString *key in keys) {
        YMSCBService *btService = (YMSCBService *)self[key];
        
        if (btService) {
            [tempArray addObject:btService.uuid];
        } else {
            NSString *message = [NSString stringWithFormat:@"WARNING: service key %@ not found in servicesSubset", key];
            [[YMSLogManager sharedManager] log:message peripheral:self.cbPeripheral];
        }
    }
    
    result = [NSArray arrayWithArray:tempArray];
    return result;

    
}

- (YMSCBService *)findService:(CBService *)service {
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

        [yp discoverServices:[yp services] withBlock:^(NSArray *yservices, NSError *error) {
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
                                NSLog(@"Descriptor: %@ %@ %@", thisService.name, yd.UUID, yd.cbDescriptor);
                            }
                        }];
                    }
                }];
            }
        }];
    }];
}

- (void)disconnect {
    YMSLogManager *localFileManager = [YMSLogManager sharedManager];
    [localFileManager log:@"FIRING DISCONNECT" peripheral:self.cbPeripheral];
    // Watchdog aware method
    if (self.watchdogTimer) {
        [localFileManager log:@"FIRING WATCHDOG DISCONNECT" peripheral:self.cbPeripheral];
        [self.watchdogTimer invalidate];
        self.watchdogTimer = nil;
    }
    [self cancelConnection];
}

- (void)resetWatchdog {
    [[YMSLogManager sharedManager] log:@"RESET WATCHDOG" peripheral:self.cbPeripheral];
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
    if (self.cbPeripheral.state == CBPeripheralStateConnecting) {
        self.watchdogRaised = YES;
        [self disconnect];
    }
    self.watchdogTimer = nil;
}

- (void)connectWithOptions:(NSDictionary *)options withBlock:(void (^)(YMSCBPeripheral *, NSError *))connectCallback {
    NSString *message = @"> connectPeripheral:";
    YMSLogManager *localFileManager = [YMSLogManager sharedManager];
    [localFileManager log:message peripheral:self.cbPeripheral];
    [localFileManager testLog:message peripheral:self.cbPeripheral];
    self.connectCallback = connectCallback;
    [self.central.manager connectPeripheral:self.cbPeripheral options:options];
}


- (void)cancelConnection {
    if (self.connectCallback) {
        self.connectCallback = nil;
    }
    
    YMSLogManager *localFileManager = [YMSLogManager sharedManager];
    NSString *message = @"> cancelPeripheralConnection:";
    [localFileManager log:message peripheral:self.cbPeripheral];
    [localFileManager testLog:message peripheral:self.cbPeripheral];
    [self.central.manager cancelPeripheralConnection:self.cbPeripheral];
}


- (void)handleConnectionResponse:(NSError *)error {
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
    [[YMSLogManager sharedManager] log:@"> readRSSI:" peripheral:self.cbPeripheral];
    [self.cbPeripheral readRSSI];
}


- (void)reset {
    self.valueValid = NO;
    self.lastValue = nil;
    self.connectCallback = nil;
    self.discoverServicesCallback = nil;
    self.watchdogTimer = nil;
    self.watchdogTimerInterval = 0;
    self.watchdogRaised = NO;
}

#pragma mark - Services Discovery

- (void)discoverServices:(NSArray *)serviceUUIDs withBlock:(void (^)(NSArray *, NSError *))callback {
    self.discoverServicesCallback = callback;
    
    NSMutableArray *bufArray = [NSMutableArray new];
    [serviceUUIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [bufArray addObject:[NSString stringWithFormat:@"%@", obj]];
    }];
    
    NSString *buf = [bufArray componentsJoinedByString:@","];
    NSString *message = [NSString stringWithFormat:@"> discoverServices: [%@]", buf];
    
    [[YMSLogManager sharedManager] log:message peripheral:self.cbPeripheral];
    [self.cbPeripheral discoverServices:serviceUUIDs];
}


- (void)syncServices:(NSArray *)services {
    for (CBService *service in services) {
        YMSCBService *btService = [self findService:service];
        if (btService) {
            btService.cbService = service;
            [btService syncCharacteristics:service.characteristics];
        }
    }
}


#pragma mark - CBPeripheralDelegate Methods
/** @name CBPeripheralDelegate Methods */
/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral that the services belong to.
 @param error If an error occurred, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< didDiscoverServices:%@", error.description];
    [[YMSLogManager sharedManager] log:message peripheral:peripheral];
    
    if (self.discoverServicesCallback) {
        NSMutableArray *services = [NSMutableArray new];
        
        @synchronized(self) {
            for (CBService *service in peripheral.services) {
                YMSCBService *btService = [self findService:service];
                if (btService) {
                    btService.cbService = service;
                    [services addObject:btService];
                }
            }
        }
        
        self.discoverServicesCallback(services, error);
        self.discoverServicesCallback = nil;
    }
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *weakSelf = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        typeof(weakError) strongError = weakError;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)]) {
            [strongSelf.delegate peripheral:strongSelf.cbPeripheral didDiscoverServices:strongError];
        }
    });

}

/**
 CBPeripheralDelegate implementation.  Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param service The CBService object containing the included service.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< didDiscoverIncludedServicesForService: %@ error:%@", service, error.description];
    [[YMSLogManager sharedManager] log:message peripheral:peripheral];
    // TBD
    
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *weakSelf = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        typeof(weakError) strongError = weakError;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheral:didDiscoverIncludedServicesForService:error:)]) {
            [strongSelf.delegate peripheral:strongSelf.cbPeripheral didDiscoverIncludedServicesForService:service error:strongError];
        }
    });
}

/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param service The service that the characteristics belong to.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< didDiscoverCharacteristicsForService: %@ error:%@", service, error.description];
    [[YMSLogManager sharedManager] log:message peripheral:peripheral];
    
    YMSCBService *btService = [self findService:service];

    [btService syncCharacteristics:service.characteristics];
    [btService handleDiscoveredCharacteristicsResponse:btService.characteristicDict withError:error];
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *weakSelf = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        typeof(weakError) strongError = weakError;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
            [strongSelf.delegate peripheral:strongSelf.cbPeripheral didDiscoverCharacteristicsForService:btService.cbService error:strongError];
        }
    });
}


/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic that the characteristic descriptors belong to.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< didDiscoverDescriptorsForCharacteristic: %@ error:%@", characteristic, error.description];
    [[YMSLogManager sharedManager] log:message peripheral:peripheral];
    
    
    YMSCBService *btService = [self findService:characteristic.service];
    YMSCBCharacteristic *ct = [btService findCharacteristic:characteristic];
    
    [ct syncDescriptors:characteristic.descriptors];
    [ct handleDiscoveredDescriptorsResponse:ct.descriptors withError:error];
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *weakSelf = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        typeof(weakError) strongError = weakError;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)]) {
            [strongSelf.delegate peripheral:strongSelf.cbPeripheral didDiscoverDescriptorsForCharacteristic:ct.cbCharacteristic error:strongError];
        }
    });
}


/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    YMSLogManager *localFileManager = [YMSLogManager sharedManager];
    NSString *message = [NSString stringWithFormat:@"< didUpdateValueForCharacteristic:%@ error:%@", characteristic, error];
    [localFileManager log:message peripheral:peripheral];
    
    if (!self.valueValid) {
        self.valueValid = YES;
    }
    
    YMSCBService *btService = [self findService:characteristic.service];
    YMSCBCharacteristic *ct = [btService findCharacteristic:characteristic];
    
    if (ct.readCallbacks && (ct.readCallbacks.count > 0)) {
        self.lastValue = characteristic.value;
        NSArray *readCallbacksCopy = [ct.readCallbacks copy];
        [ct.readCallbacks removeAllObjects];
        
        for (YMSCBReadCallbackBlockType readCB in readCallbacksCopy) {
            readCB(characteristic.value, error);
        }
        
        if (ct.cbCharacteristic.isNotifying) {
            message = [NSString stringWithFormat:@"WARNING: Read callback called for notifying characteristic %@", characteristic];
            [localFileManager log:message peripheral:peripheral];
        }
    } else {
        if (ct.cbCharacteristic.isNotifying) {
            BOOL runNotificationCallback = NO;
            
            if (self.valueValid && (!self.lastValue || ![self.lastValue isEqualToData:characteristic.value])) {
                runNotificationCallback = YES;
            }
            
            if (runNotificationCallback && ct.notificationCallback) {
                ct.notificationCallback(characteristic.value, error);
            } else {
                message = [NSString stringWithFormat:@"WARNING: No notification callback defined for %@", characteristic];
                [localFileManager log:message peripheral:peripheral];
            }
        }
    }

    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *weakSelf = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        typeof(weakError) strongError = weakError;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]) {
            [strongSelf.delegate peripheral:strongSelf.cbPeripheral didUpdateValueForCharacteristic:ct.cbCharacteristic error:strongError];
        }
    });
}


/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param descriptor The characteristic descriptor whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< didUpdateValueForDescriptor:%@ error:%@", descriptor, error.description];
    [[YMSLogManager sharedManager] log:message peripheral:peripheral];

    // TBD
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *weakSelf = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        typeof(weakError) strongError = weakError;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)]) {
            [strongSelf.delegate peripheral:strongSelf.cbPeripheral didUpdateValueForDescriptor:descriptor error:strongError];
        }
    });
}

/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< didUpdateNotificationStateForCharacteristic: %@ error:%@", characteristic, error.description];
    [[YMSLogManager sharedManager] log:message peripheral:peripheral];
    
    YMSCBService *btService = [self findService:characteristic.service];
    YMSCBCharacteristic *ct = [btService findCharacteristic:characteristic];
    
    [ct executeNotificationStateCallback:error];
    
    if (!characteristic.isNotifying) {
        ct.notificationCallback = nil;
    }
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *weakSelf = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        typeof(weakError) strongError = weakError;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]) {
            [strongSelf.delegate peripheral:strongSelf.cbPeripheral didUpdateNotificationStateForCharacteristic:ct.cbCharacteristic error:strongError];
        }
    });
}


/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< didWriteValueForCharacteristic: %@ error:%@", characteristic, error.description];
    [[YMSLogManager sharedManager] log:message peripheral:peripheral];
    
    YMSCBService *btService = [self findService:characteristic.service];
    YMSCBCharacteristic *ct = [btService findCharacteristic:characteristic];
    
    if (ct.writeCallbacks && (ct.writeCallbacks.count > 0)) {
        [ct executeWriteCallback:error];
    } else {
        message = [NSString stringWithFormat:@"No write callback in didWriteValueForCharacteristic:%@ for peripheral %@", characteristic, peripheral];
        NSAssert(NO, message);
    }

    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *weakSelf = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        typeof(weakError) strongError = weakError;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
            [strongSelf.delegate peripheral:strongSelf.cbPeripheral didWriteValueForCharacteristic:ct.cbCharacteristic error:strongError];
        }
    });
}


/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param descriptor The characteristic descriptor whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"< didWriteValueForDescriptor: %@ error:%@", descriptor, error.description];
    [[YMSLogManager sharedManager] log:message peripheral:peripheral];

    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *weakSelf = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        typeof(weakError) strongError = weakError;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheral:didWriteValueForDescriptor:error:)]) {
            [strongSelf.delegate peripheral:strongSelf.cbPeripheral didWriteValueForDescriptor:descriptor error:strongError];
        }
    });
}

/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param RSSI RSSI value
 @param error If an error occured, the cause of the failure.
 */

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        if ([weakSelf.delegate respondsToSelector:@selector(peripheral:didReadRSSI:error:)]) {
            [weakSelf.delegate peripheral:peripheral didReadRSSI:RSSI error:error];
        }
    });
}


/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 iOS only.
 
 @param peripheral The peripheral providing this information.
 */
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {

    [[YMSLogManager sharedManager] log:@"< peripheralDidUpdateName" peripheral:peripheral];

#if TARGET_OS_IPHONE
    // TBD
    __weak YMSCBPeripheral *weakSelf = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheralDidUpdateName:)]) {
            [strongSelf.delegate peripheralDidUpdateName:strongSelf.cbPeripheral];
        }
    });
#endif
}



/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 iOS only.
 
 @param peripheral The peripheral providing this information.
 */
// debug
//- (void)peripheralDidInvalidateServices:(CBPeripheral *)peripheral {
//    [[YMSLogManager sharedManager] log:@"< peripheralDidInvalidateServices" peripheral:peripheral];
//#if TARGET_OS_IPHONE
//    // TBD
//    
//    __weak YMSCBPeripheral *weakSelf = self;
//    _YMS_PERFORM_ON_MAIN_THREAD(^{
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//        if ([strongSelf.delegate respondsToSelector:@selector(peripheralDidInvalidateServices:)]) {
//            [strongSelf.delegate peripheralDidInvalidateServices:strongSelf.cbPeripheral];
//        }
//    });
//#endif
//}
// debug


- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices {
    NSString *message = [NSString stringWithFormat:@"< didModifyServices: %@", invalidatedServices];
    [[YMSLogManager sharedManager] log:message peripheral:peripheral];
    __weak typeof(self) weakSelf = self;
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(peripheral:didModifyServices:)]) {
            [strongSelf.delegate peripheral:strongSelf.cbPeripheral didModifyServices:invalidatedServices];
        }
    });
}


@end
