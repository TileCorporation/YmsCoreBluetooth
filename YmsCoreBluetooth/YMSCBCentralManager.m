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
#import "YMSCBStoredPeripherals.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const YMSCBVersion = @"" kYMSCBVersion;

@interface YMSCBCentralManager () {
    NSMutableArray *_ymsPeripherals;
}


// TODO: Change to use NSSet with GCD
@property (atomic, strong) NSMutableArray *ymsPeripherals;

@end


@implementation YMSCBCentralManager

- (NSString *)version {
    return YMSCBVersion;
}


#pragma mark - Constructors

- (nullable instancetype)initWithKnownPeripheralNames:(nullable NSArray *)nameList queue:(nullable dispatch_queue_t)queue delegate:(nullable id<CBCentralManagerDelegate>) delegate {

    self = [super init];
    
    if (self) {
        // TODO: Use NSSet with GCD
        // TODO: Persist `queue`
        _ymsPeripherals = [NSMutableArray new];
        _delegate = delegate;
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
        _knownPeripheralNames = nameList;
        _discoveredCallback = nil;
        _retrievedCallback = nil;
        _useStoredPeripherals = NO;
    }
    
    return self;
}

- (nullable instancetype)initWithKnownPeripheralNames:(nullable NSArray *)nameList queue:(nullable dispatch_queue_t)queue useStoredPeripherals:(BOOL)useStore delegate:(nullable id<CBCentralManagerDelegate>) delegate {

    self = [super init];
    
    if (self) {
        // TODO: Use NSSet with GCD
        // TODO: Persist `queue`
        _ymsPeripherals = [NSMutableArray new];
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

#pragma mark - Peripheral Management

// TODO: Use NSSet with GCD
- (NSUInteger)count {
    return  [self countOfYmsPeripherals];
}

// TODO: OBSOLETE
- (nullable YMSCBPeripheral *)peripheralAtIndex:(NSUInteger)index {
    return [self objectInYmsPeripheralsAtIndex:index];
}

// TODO: Use NSSet with GCD
- (void)addPeripheral:(YMSCBPeripheral *)yperipheral {
    [self insertObject:yperipheral inYmsPeripheralsAtIndex:self.countOfYmsPeripherals];
}

// TODO: Use NSSet with GCD
- (void)removePeripheral:(YMSCBPeripheral *)yperipheral {
    [self removeObjectFromYmsPeripheralsAtIndex:[self.ymsPeripherals indexOfObject:yperipheral]];
}

// TODO: OBSOLETE
- (void)removePeripheralAtIndex:(NSUInteger)index {
    [self removeObjectFromYmsPeripheralsAtIndex:index];
}

// TODO: Use NSSet with GCD
- (void)removeAllPeripherals {
    while ([self countOfYmsPeripherals] > 0) {
        [self removePeripheralAtIndex:0];
    }
}

// TODO: Use NSSet with GCD
- (NSUInteger)countOfYmsPeripherals {
    return _ymsPeripherals.count;
}


// TODO: Use NSSet with GCD
- (id)objectInYmsPeripheralsAtIndex:(NSUInteger)index {
    return [_ymsPeripherals objectAtIndex:index];
}


// TODO: Use NSSet with GCD
- (void)insertObject:(YMSCBPeripheral *)object inYmsPeripheralsAtIndex:(NSUInteger)index {
    [_ymsPeripherals insertObject:object atIndex:index];
}


// TODO: Use NSSet with GCD
- (void)removeObjectFromYmsPeripheralsAtIndex:(NSUInteger)index {
    if (self.useStoredPeripherals) {
        YMSCBPeripheral *yperipheral = [self.ymsPeripherals objectAtIndex:index];
        if (yperipheral.cbPeripheral.identifier != nil) {
            [YMSCBStoredPeripherals deleteUUID:yperipheral.cbPeripheral.identifier];
        }
    }
    [_ymsPeripherals removeObjectAtIndex:index];
}

// TODO: OBSOLETE
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
    
    BOOL result = NO;
    return result;
}

- (BOOL)scanForPeripheralsWithServices:(nullable NSArray *)serviceUUIDs options:(nullable NSDictionary *)options {
    BOOL result = NO;
    
    // TODO: test isScanning?
    if (self.manager.state == CBCentralManagerStatePoweredOn) {
        [self.manager scanForPeripheralsWithServices:serviceUUIDs options:options];
        self.isScanning = YES;
        result = YES;
    }
    
    return result;
}


- (BOOL)scanForPeripheralsWithServices:(nullable NSArray *)serviceUUIDs
                               options:(nullable NSDictionary *)options
                             withBlock:(nullable void (^)(CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI, NSError * _Nullable error))discoverCallback
                            withFilter:(nullable BOOL (^)(CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI))filterCallback{
    BOOL result = NO;
    
    if (self.manager.state == CBCentralManagerStatePoweredOn) {
        self.discoveredCallback = discoverCallback;
        self.filteredCallback = filterCallback;
        [self scanForPeripheralsWithServices:serviceUUIDs options:options];
        self.isScanning = YES;
        result = YES;
    }
    return result;
}


- (void)stopScan {
    [self.manager stopScan];
    self.discoveredCallback = nil;
    self.isScanning = NO;
}

- (nullable YMSCBPeripheral *)findPeripheral:(nonnull CBPeripheral *)peripheral {
    // TODO: Use NSSet with GCD
    
    YMSCBPeripheral *result = nil;
    NSArray *peripheralsCopy = [NSArray arrayWithArray:self.ymsPeripherals];
    
    for (YMSCBPeripheral *yPeripheral in peripheralsCopy) {
        if (yPeripheral.cbPeripheral == peripheral) {
            result = yPeripheral;
            break;
        }
    }
    
    return result;
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
        __weak YMSCBCentralManager *this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof (this) strongThis = this;
            [strongThis.delegate centralManagerDidUpdateState:central];
        });
    }
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (self.useStoredPeripherals) {
        if (peripheral.identifier) {
            [YMSCBStoredPeripherals saveUUID:peripheral.identifier];
        }
    }
    
    BOOL shouldProcess = YES;
    if (self.filteredCallback) {
        shouldProcess = self.filteredCallback(peripheral, advertisementData, RSSI);
    }
    
    if (shouldProcess && self.discoveredCallback) {
        self.discoveredCallback(peripheral, advertisementData, RSSI, nil);
    }
    
    __weak YMSCBCentralManager *this = self;
    
    [self handleFoundPeripheral:peripheral];

    if ([self.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
        if (shouldProcess) {
            _YMS_PERFORM_ON_MAIN_THREAD(^{
                __strong typeof (this) strongThis = this;
                [strongThis.delegate centralManager:central
                              didDiscoverPeripheral:peripheral
                                  advertisementData:advertisementData
                                               RSSI:RSSI];
            });
        }
    }
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    YMSCBPeripheral *yp = [self findPeripheral:peripheral];
    [yp handleConnectionResponse:nil];
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
        __weak YMSCBCentralManager *this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof (this) strongThis = this;
            [strongThis.delegate centralManager:central didConnectPeripheral:peripheral];
        });
    }
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    YMSCBPeripheral *yp = [self findPeripheral:peripheral];
    yp.connectCallback = nil;
    
    for (id key in yp.serviceDict) {
        YMSCBService *service = yp.serviceDict[key];
        [service reset];
    }
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
        __weak YMSCBCentralManager *this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof(this) strongThis = this;
            [strongThis.delegate centralManager:central didDisconnectPeripheral:peripheral error:error];
        });
    }
    
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
    YMSCBPeripheral *yp = [self findPeripheral:peripheral];
    yp.connectCallback = nil;
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)]) {
        __weak YMSCBCentralManager *this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            __strong typeof(this) strongThis = this;
            [strongThis.delegate centralManager:central didFailToConnectPeripheral:peripheral error:error];
        });
    }
}

@end

NS_ASSUME_NONNULL_END

