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

NS_ASSUME_NONNULL_BEGIN

@interface YMSCBPeripheral ()
@property (atomic, copy, nullable) NSData *lastValue;
@property (atomic, assign) BOOL valueValid;
@end

@implementation YMSCBPeripheral

- (nullable instancetype)initWithPeripheral:(CBPeripheral *)peripheral
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

- (nullable NSString *)name {
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


- (nullable id)objectForKeyedSubscript:(id)key {
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
            NSLog(@"WARNING: service key '%@' is not found in peripheral '%@' for servicesSubset:", key, [self.cbPeripheral.identifier UUIDString]);
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
    if (self.cbPeripheral.state != CBPeripheralStateConnected) {
        self.watchdogRaised = YES;
        [self disconnect];
    }
    self.watchdogTimer = nil;
}

- (void)connectWithOptions:(nullable NSDictionary *)options withBlock:(nullable void (^)(YMSCBPeripheral * _Nonnull yp, NSError * _Nullable error))connectCallback {
    self.connectCallback = connectCallback;
    [self.central.manager connectPeripheral:self.cbPeripheral options:options];
}


- (void)cancelConnection {
    if (self.connectCallback) {
        self.connectCallback = nil;
    }
    [self.central.manager cancelPeripheralConnection:self.cbPeripheral];
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

- (void)discoverServices:(nullable NSArray *)serviceUUIDs withBlock:(nullable void (^)(NSArray * _Nullable services, NSError * _Nullable error))callback {
    self.discoverServicesCallback = callback;
    
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
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    __weak YMSCBPeripheral *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        
        if (this.discoverServicesCallback) {
            NSMutableArray *services = [NSMutableArray new];
            
            // TODO: add method syncServices
            
            @synchronized(self) {
                for (CBService *service in peripheral.services) {
                    YMSCBService *btService = [this findService:service];
                    if (btService) {
                        btService.cbService = service;
                        [services addObject:btService];
                    }
                }
            }
            
            this.discoverServicesCallback(services, error);
            this.discoverServicesCallback = nil;
        }
        
        if ([this.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)]) {
            [this.delegate peripheral:peripheral didDiscoverServices:error];
        }
    });
}

/**
 CBPeripheralDelegate implementation.  Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param service The CBService object containing the included service.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error {
    // TBD
    __weak YMSCBPeripheral *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        if ([this.delegate respondsToSelector:@selector(peripheral:didDiscoverIncludedServicesForService:error:)]) {
            [this.delegate peripheral:peripheral didDiscoverIncludedServicesForService:service error:error];
        }
    });
}

/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param service The service that the characteristics belong to.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    //NSString *message = [NSString stringWithFormat:@"< didDiscoverCharacteristicsForService: %@ error:%@", service, error.description];
    
    YMSCBService *btService = [self findService:service];
    
    [btService syncCharacteristics:service.characteristics];
    [btService handleDiscoveredCharacteristicsResponse:btService.characteristicDict withError:error];
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(this) strongThis = this;
        __strong typeof(weakError) strongError = weakError;
        if ([strongThis.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
            [strongThis.delegate peripheral:strongThis.cbPeripheral didDiscoverCharacteristicsForService:btService.cbService error:strongError];
        }
    });
}


/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic that the characteristic descriptors belong to.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    YMSCBService *btService = [self findService:characteristic.service];
    YMSCBCharacteristic *ct = [btService findCharacteristic:characteristic];
    
    [ct syncDescriptors:characteristic.descriptors];
    [ct handleDiscoveredDescriptorsResponse:ct.descriptors withError:error];
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(this) strongThis = this;
        typeof(weakError) strongError = weakError;
        if ([strongThis.delegate respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)]) {
            [strongThis.delegate peripheral:strongThis.cbPeripheral didDiscoverDescriptorsForCharacteristic:ct.cbCharacteristic error:strongError];
        }
    });
}


/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    //TILLocalFileManager *localFileManager = [TILLocalFileManager sharedManager];
    //NSString *message = [NSString stringWithFormat:@"< didUpdateValueForCharacteristic:%@ error:%@", characteristic, error];
    //[localFileManager log:message peripheral:peripheral];
    
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
            //message = [NSString stringWithFormat:@"WARNING: Read callback called for notifying characteristic %@", characteristic];
            //[localFileManager log:message peripheral:peripheral];
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
                //message = [NSString stringWithFormat:@"WARNING: No notification callback defined for %@", characteristic];
                //[localFileManager log:message peripheral:peripheral];
            }

        }
    }

    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(this) strongThis = this;
        typeof(weakError) strongError = weakError;
        if ([strongThis.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]) {
            [strongThis.delegate peripheral:strongThis.cbPeripheral didUpdateValueForCharacteristic:ct.cbCharacteristic error:strongError];
        }
    });

}


/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param descriptor The characteristic descriptor whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
    //NSString *message = [NSString stringWithFormat:@"< didUpdateValueForDescriptor:%@ error:%@", descriptor, error.description];
    //[[TILLocalFileManager sharedManager] log:message peripheral:peripheral];
    
    // TBD
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(this) strongThis = this;
        typeof(weakError) strongError = weakError;
        if ([strongThis.delegate respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)]) {
            [strongThis.delegate peripheral:strongThis.cbPeripheral didUpdateValueForDescriptor:descriptor error:strongError];
        }
    });
}

/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
   // NSString *message = [NSString stringWithFormat:@"< didUpdateNotificationStateForCharacteristic: %@ error:%@", characteristic, error.description];
   // [[TILLocalFileManager sharedManager] log:message peripheral:peripheral];
    
    YMSCBService *btService = [self findService:characteristic.service];
    YMSCBCharacteristic *ct = [btService findCharacteristic:characteristic];
    
    [ct executeNotificationStateCallback:error];
    
    if (!characteristic.isNotifying) {
        ct.notificationCallback = nil;
    }
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(this) strongThis = this;
        typeof(weakError) strongError = weakError;
        if ([strongThis.delegate respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]) {
            [strongThis.delegate peripheral:strongThis.cbPeripheral didUpdateNotificationStateForCharacteristic:ct.cbCharacteristic error:strongError];
        }
    });

}


/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param characteristic The characteristic whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    //NSString *message = [NSString stringWithFormat:@"< didWriteValueForCharacteristic: %@ error:%@", characteristic, error.description];
    //[[TILLocalFileManager sharedManager] log:message peripheral:peripheral];
    
    YMSCBService *btService = [self findService:characteristic.service];
    YMSCBCharacteristic *ct = [btService findCharacteristic:characteristic];
    
    if (ct.writeCallbacks && (ct.writeCallbacks.count > 0)) {
        [ct executeWriteCallback:error];
    } else {
        //message = [NSString stringWithFormat:@"No write callback in didWriteValueForCharacteristic:%@ for peripheral %@", characteristic, peripheral];
        //TILAssert(NO, message);
    }
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(this) strongThis = this;
        typeof(weakError) strongError = weakError;
        if ([strongThis.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
            [strongThis.delegate peripheral:strongThis.cbPeripheral didWriteValueForCharacteristic:ct.cbCharacteristic error:strongError];
        }
    });
}


/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 @param peripheral The peripheral providing this information.
 @param descriptor The characteristic descriptor whose value has been retrieved.
 @param error If an error occured, the cause of the failure.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
    //NSString *message = [NSString stringWithFormat:@"< didWriteValueForDescriptor: %@ error:%@", descriptor, error.description];
    //[[TILLocalFileManager sharedManager] log:message peripheral:peripheral];
    
    __weak NSError *weakError = error;
    __weak YMSCBPeripheral *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(this) strongThis = this;
        typeof(weakError) strongError = weakError;
        if ([strongThis.delegate respondsToSelector:@selector(peripheral:didWriteValueForDescriptor:error:)]) {
            [strongThis.delegate peripheral:strongThis.cbPeripheral didWriteValueForDescriptor:descriptor error:strongError];
        }
    });

}

/**
 CBPeripheralDelegate implementation.
 
 @param peripheral The peripheral providing this information.
 @param error If an error occured, the cause of the failure.
 */


- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error {
    if ([self.delegate respondsToSelector:@selector(peripheral:didReadRSSI:error:)]) {
        __weak YMSCBPeripheral *this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof(this) strongThis = this;
            [strongThis.delegate peripheral:peripheral didReadRSSI:RSSI error:error];
        });
    }
}



/**
 CBPeripheralDelegate implementation. Not yet supported.
 
 iOS only.
 
 @param peripheral The peripheral providing this information.
 */
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
//    [[TILLocalFileManager sharedManager] log:@"< peripheralDidUpdateName" peripheral:peripheral];
    
#if TARGET_OS_IPHONE
    // TBD
    __weak YMSCBPeripheral *this = self;
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(this) strongThis = this;
        if ([strongThis.delegate respondsToSelector:@selector(peripheralDidUpdateName:)]) {
            [strongThis.delegate peripheralDidUpdateName:strongThis.cbPeripheral];
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
//    NSString *message = [NSString stringWithFormat:@"< didModifyServices: %@", invalidatedServices];
//    [[TILLocalFileManager sharedManager] log:message peripheral:peripheral];
    __weak typeof(self) this = self;
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        __strong typeof(this) strongThis = this;
        if ([strongThis.delegate respondsToSelector:@selector(peripheral:didModifyServices:)]) {
            [strongThis.delegate peripheral:strongThis.cbPeripheral didModifyServices:invalidatedServices];
        }
    });
}


@end

NS_ASSUME_NONNULL_END
