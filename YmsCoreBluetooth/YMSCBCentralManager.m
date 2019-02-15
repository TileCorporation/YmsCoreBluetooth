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
#import "YMSCBStoredPeripherals.h"
#import "YMSLogManager.h"
#import "YMSSafeMutableSet.h"

NSString *const YMSCBVersion = @"" kYMSCBVersion;

@interface YMSCBCentralManager ()
@property (nonatomic, strong) NSMutableDictionary *ymsPeripherals;
@end


@implementation YMSCBCentralManager

- (NSString *)version {
    return YMSCBVersion;
}


#pragma mark - Constructors

- (instancetype)initWithKnownPeripheralNames:(NSArray *)nameList queue:(dispatch_queue_t)queue delegate:(id<CBCentralManagerDelegate>) delegate; {
    self = [super init];
    
    if (self) {
        _ymsPeripherals = [NSMutableDictionary new];
        _delegate = delegate;
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
        _knownPeripheralNames = nameList;
        _discoveredCallback = nil;
        _retrievedCallback = nil;
        _useStoredPeripherals = NO;
    }
    
    return self;
}

- (instancetype)initWithKnownPeripheralNames:(NSArray *)nameList queue:(dispatch_queue_t)queue useStoredPeripherals:(BOOL)useStore delegate:(id<CBCentralManagerDelegate>)delegate {

    self = [super init];
    
    if (self) {
        _ymsPeripherals = [NSMutableDictionary new];
        _delegate = delegate;
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
        _knownPeripheralNames = nameList;
        _discoveredCallback = nil;
        _retrievedCallback = nil;
        _useStoredPeripherals = useStore;
    }
    
    if (useStore) {
        [YMSCBStoredPeripherals initializeStorage];
    }
    
    return self;
}

- (instancetype)initWithKnownPeripheralNames:(NSArray *)nameList queue:(dispatch_queue_t)queue options:(NSDictionary *)options useStoredPeripherals:(BOOL)useStore delegate:(id<CBCentralManagerDelegate>)delegate {
    
    self = [super init];
    
    if (self) {
        _ymsPeripherals = [NSMutableDictionary new];
        _delegate = delegate;
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:options];
        _knownPeripheralNames = nameList;
        _discoveredCallback = nil;
        _retrievedCallback = nil;
        _useStoredPeripherals = useStore;
    }
    
    if (useStore) {
        [YMSCBStoredPeripherals initializeStorage];
    }
    
    return self;
}


#pragma mark - Peripheral Management

- (NSUInteger)count {
    @synchronized (self) {
        return _ymsPeripherals.count;
    }
}

- (void)addPeripheral:(YMSCBPeripheral *)yperipheral {
    @synchronized (self) {
        _ymsPeripherals[yperipheral.cbPeripheral.identifier] = yperipheral;
    }
}

- (void)removePeripheral:(YMSCBPeripheral *)yperipheral {
    @synchronized (self) {
        _ymsPeripherals[yperipheral.cbPeripheral.identifier] = nil;
    }
}

- (void)removeAllPeripherals {
    [_ymsPeripherals removeAllObjects];
}

- (NSUInteger)countOfYmsPeripherals {
    @synchronized (self) {
        return _ymsPeripherals.count;
    }
}

- (BOOL)isKnownPeripheral:(CBPeripheral *)peripheral {
    BOOL result = NO;
    
    for (NSString *key in self.knownPeripheralNames) {
        result = result || [peripheral.name isEqualToString:key];
        if (result) {
            break;
        }
    }
    
    return result;
}

#pragma mark - Scan Methods

- (BOOL)startScan {
    /*
     * THIS METHOD IS TO BE OVERRIDDEN
     */
    
    NSAssert(NO, @"[YMSCBCentralManager startScan] must be be overridden and include call to [self scanForPeripherals:options:]");
    
    //[self scanForPeripheralsWithServices:nil options:nil];
    return YES;
}


- (BOOL)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs options:(NSDictionary *)options {
    BOOL result = NO;
    NSString *message = [NSString stringWithFormat:@"BLE OPERATION: START SCAN serviceUUIDs: %@ options: %@", serviceUUIDs, options];
    [[YMSLogManager sharedManager] log:message];
    
    if (self.manager.state == CBCentralManagerStatePoweredOn) {
        [self.manager scanForPeripheralsWithServices:serviceUUIDs options:options];
        self.isScanning = YES;
        result = YES;
    } else {
        self.isScanning = NO;
    }
    return result;
}


- (BOOL)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs options:(NSDictionary *)options withBlock:(void (^)(CBPeripheral *, NSDictionary *, NSNumber *, NSError *))discoverCallback {
    self.discoveredCallback = discoverCallback;
    BOOL result = [self scanForPeripheralsWithServices:serviceUUIDs options:options];
    return result;
}

- (void)stopScan {
    NSString *message = [NSString stringWithFormat:@"BLE OPERATION: STOP SCAN"];
    [[YMSLogManager sharedManager] log:message];
    [self.manager stopScan];
    self.isScanning = NO;
}


- (YMSCBPeripheral *)findPeripheral:(CBPeripheral *)peripheral {
    @synchronized (self) {
        return _ymsPeripherals[peripheral.identifier];
    }
}



- (void)handleFoundPeripheral:(CBPeripheral *)peripheral {
    /*
     * THIS METHOD IS TO BE OVERRIDDEN
     */
    
    NSAssert(NO, @"[YMSCBCentralManager handleFoundPeripheral:] must be be overridden.");

}


#pragma mark - Retrieve Methods

- (NSArray *)retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDs {
    NSArray *result = [self.manager retrieveConnectedPeripheralsWithServices:serviceUUIDs];
    return result;
}


- (NSArray *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers {
    NSArray *result = [self.manager retrievePeripheralsWithIdentifiers:identifiers];
    return result;
}


#pragma mark - CBCentralManger state handler methods.

- (void)managerPoweredOnHandler {
    // THIS METHOD IS TO BE OVERRIDDEN
}

- (void)managerUnknownHandler {
    // THIS METHOD IS TO BE OVERRIDDEN
}

- (void)managerPoweredOffHandler {
    // THIS METHOD IS TO BE OVERRIDDEN
}

- (void)managerResettingHandler {
    // CALL SUPER METHOD
    // THIS METHOD MUST BE INVOKED BY SUBCLASSES THAT OVERRIDE THIS METHOD
    [_ymsPeripherals removeAllObjects];
}

- (void)managerUnauthorizedHandler {
    // THIS METHOD IS TO BE OVERRIDDEN
}

- (void)managerUnsupportedHandler {
    // THIS METHOD IS TO BE OVERRIDDEN
}

#pragma mark - CBCentralManagerDelegate Protocol Methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self managerPoweredOnHandler];
            break;
            
        case CBCentralManagerStateUnknown:
            [self managerUnknownHandler];
            break;
            
        case CBCentralManagerStatePoweredOff:
            [self managerPoweredOffHandler];
            break;
            
        case CBCentralManagerStateResetting:
            [self managerResettingHandler];
            break;
            
        case CBCentralManagerStateUnauthorized:
            [self managerUnauthorizedHandler];
            break;
            
        case CBCentralManagerStateUnsupported: {
            [self managerUnsupportedHandler];
            break;
        }
    }
    

    if ([self.delegate respondsToSelector:@selector(centralManagerDidUpdateState:)]) {
        __weak YMSCBCentralManager *weakSelf = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.delegate centralManagerDidUpdateState:central];
        });
    }
}



- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    if (self.useStoredPeripherals) {
        if (peripheral.identifier) {
            [YMSCBStoredPeripherals saveUUID:peripheral.identifier];
        }
    }
    
    if (self.discoveredCallback) {
        self.discoveredCallback(peripheral, advertisementData, RSSI, nil);
    } else {
        [self handleFoundPeripheral:peripheral];
    }
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
        __weak YMSCBCentralManager *weakSelf = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.delegate centralManager:central
                          didDiscoverPeripheral:peripheral
                              advertisementData:advertisementData
                                           RSSI:RSSI];
        });
    }
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    YMSCBPeripheral *yp = [self findPeripheral:peripheral];
    [yp handleConnectionResponse:nil];
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
        __weak YMSCBCentralManager *weakSelf = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.delegate centralManager:central didConnectPeripheral:peripheral];
        });
    }
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    YMSCBPeripheral *yp = [self findPeripheral:peripheral];
    yp.connectCallback = nil;
    
    for (id key in yp.serviceDict) {
        YMSCBService *service = yp.serviceDict[key];
        [service reset];
    }
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
        __weak YMSCBCentralManager *weakSelf = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.delegate centralManager:central didDisconnectPeripheral:peripheral error:error];
        });
    }

}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    YMSCBPeripheral *yp = [self findPeripheral:peripheral];
    yp.connectCallback = nil;
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)]) {
        __weak YMSCBCentralManager *weakSelf = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.delegate centralManager:central didFailToConnectPeripheral:peripheral error:error];
        });
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {

    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    
    for (CBPeripheral *peripheral in peripherals) {
        [self handleFoundPeripheral:peripheral];
    }
    
    if ([self.delegate respondsToSelector:@selector(centralManager:willRestoreState:)]) {
        __weak YMSCBCentralManager *weakSelf = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.delegate centralManager:central willRestoreState:dict];
        });
    }
    
}

@end
