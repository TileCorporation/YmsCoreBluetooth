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
#import "YMSCBNativeInterfaces.h"
#import "YMSBFMCentralManager.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const YMSCBVersion = @"" kYMSCBVersion;

@interface YMSCBCentralManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBPeripheralInterface>> *ymsPeripherals;

@end

@implementation YMSCBCentralManager

- (NSString *)version {
    return YMSCBVersion;
}


#pragma mark - Constructors


- (nullable instancetype)initWithCentral:(nullable id<YMSCBCentralManagerInterface>)centralInterface
                                delegate:(nullable id<YMSCBCentralManagerDelegate>)delegate
                                   queue:(nullable dispatch_queue_t)queue
                                 options:(nullable NSDictionary<NSString *, id> *)options
                                  logger:(id<YMSCBLogging>)logger {
    
    self = [super init];
    if (self) {
        _ymsPeripherals = [NSMutableDictionary new];
        _delegate = delegate;
        _queue = queue;
        
        if (centralInterface) {
            // !!!: It is the responsibility of the developer using this call to send this object YMSCBCentralManagerInterfaceDelegate calls
            _centralInterface  = centralInterface;
        } else {
#if TARGET_IPHONE_SIMULATOR
            _centralInterface = [[YMSBFMCentralManager alloc] initWithDelegate:self queue:queue options:options];
#else
            _centralInterface = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:options];
#endif
        }
        
        _ymsPeripheralsQueue = dispatch_queue_create("com.yummymelon.ymsPeripherals", DISPATCH_QUEUE_SERIAL);
        _discoveredCallback = nil;
        _retrievedCallback = nil;
        _logger = logger;
    }
    
    return self;
}


- (CBCentralManagerState)state {
    CBCentralManagerState state;
    state = _centralInterface.state;
    return state;
}


#pragma mark - Peripheral Management

- (NSUInteger)count {
    __block NSUInteger result = 0;
    
    __weak typeof(self) this = self;
    dispatch_sync(self.ymsPeripheralsQueue, ^{
        __strong typeof(this) strongThis = this;
        result = strongThis.ymsPeripherals.count;
    });
    
    return result;
}

- (void)addPeripheral:(id<YMSCBPeripheralInterface>)yp {
    __weak typeof(self) this = self;
    dispatch_async(self.ymsPeripheralsQueue, ^{
        __strong typeof(this) strongThis = this;
        [strongThis.ymsPeripherals setValue:yp forKey:yp.identifier.UUIDString];
    });
}

- (void)removePeripheral:(id<YMSCBPeripheralInterface>)yp {
    __weak typeof(self) this = self;
    dispatch_async(self.ymsPeripheralsQueue, ^{
        __strong typeof(this) strongThis = this;
        [strongThis.ymsPeripherals removeObjectForKey:yp.identifier.UUIDString];
    });
}

- (nullable id<YMSCBPeripheralInterface>)findPeripheral:(id<YMSCBPeripheralInterface>)yPeripheral {
    id<YMSCBPeripheralInterface> result = nil;
    NSString *key = yPeripheral.identifier.UUIDString;
    result = self.ymsPeripherals[key];
    return result;
}

- (nullable id<YMSCBPeripheralInterface>)findPeripheralWithIdentifier:(NSUUID *)identifier {
    id<YMSCBPeripheralInterface> result = nil;
    NSString *key = identifier.UUIDString;
    result = self.ymsPeripherals[key];
    return result;
}



- (nullable YMSCBPeripheral *)ymsPeripheralWithInterface:(id<YMSCBPeripheralInterface>)peripheralInterface advertisementData:(nullable NSDictionary<NSString *,id> *)advertisementData {
    /*
     * THIS METHOD IS TO BE OVERRIDDEN
     */

    YMSCBPeripheral *result = nil;
    NSAssert(NO, @"[YMSCBCentralManager ymsPeripheralWithInterface:] must be be overridden.");
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

- (BOOL)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary *)options {
    BOOL result = NO;
    
    NSString *message = nil;
    if (self.centralInterface.state == CBCentralManagerStatePoweredOn) {
        message = [NSString stringWithFormat:@"BLE OPERATION: START SCAN serviceUUIDs: %@ options: %@", serviceUUIDs, options];
        [self.logger logInfo:message object:self.centralInterface];
        
        [self.centralInterface scanForPeripheralsWithServices:serviceUUIDs options:options];
        self.isScanning = YES;
        result = YES;
    } else {
        message = [NSString stringWithFormat:@"Unable to start scan: CBCentralManagerState is not ON"];
        // TODO: define error object
        [self.logger logError:message object:self error:nil];
    }
    
    return result;
}


- (BOOL)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs
                               options:(nullable NSDictionary *)options
                             withBlock:(nullable YMSCBDiscoverCallbackBlockType)discoverCallback
                            withFilter:(nullable YMSCBFilterCallbackBlockType)filterCallback {

    BOOL result = NO;
    
    if (self.centralInterface.state == CBCentralManagerStatePoweredOn) {
        self.discoveredCallback = discoverCallback;
        self.filteredCallback = filterCallback;
        result = [self scanForPeripheralsWithServices:serviceUUIDs options:options];
    }
    return result;
}



- (void)stopScan {
    NSString *message = [NSString stringWithFormat:@"BLE OPERATION: STOP SCAN"];
    [self.logger logInfo:message object:self];

    [self.centralInterface stopScan];
    self.discoveredCallback = nil;
    self.isScanning = NO;
}



#pragma mark - Retrieve Methods

- (NSArray<YMSCBPeripheral *> *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers {
    
    NSArray<YMSCBPeripheral *> *result = nil;
    NSArray<id<YMSCBPeripheralInterface>> *peripheralInterfaces = [self.centralInterface retrievePeripheralsWithIdentifiers:identifiers];
    
    NSMutableArray *tempArray = [NSMutableArray new];
    
    for (id<YMSCBPeripheralInterface> peripheralInterface in peripheralInterfaces) {
        YMSCBPeripheral *yPeripheral = [self findPeripheralWithIdentifier:peripheralInterface.identifier];
        if (!yPeripheral) {
            yPeripheral = [self ymsPeripheralWithInterface:peripheralInterface advertisementData:nil];
            if (yPeripheral) {
                [self addPeripheral:yPeripheral];
            }
        }
        
        if (yPeripheral) {
            [tempArray addObject:yPeripheral];
        }
    }

    result = [NSArray arrayWithArray:tempArray];
    return result;
}

- (NSArray<YMSCBPeripheral *> *)retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDs {
    
    NSArray<YMSCBPeripheral *> *result = nil;
    NSArray<id<YMSCBPeripheralInterface>> *peripheralInterfaces = [self.centralInterface retrieveConnectedPeripheralsWithServices:serviceUUIDs];
    
    NSMutableArray *tempArray = [NSMutableArray new];
    
    for (id<YMSCBPeripheralInterface> peripheralInterface in peripheralInterfaces) {
        YMSCBPeripheral *yPeripheral = (YMSCBPeripheral *)[self findPeripheralWithIdentifier:peripheralInterface.identifier];
        if (!yPeripheral) {
            yPeripheral = [self ymsPeripheralWithInterface:peripheralInterface advertisementData:nil];
            if (yPeripheral) {
                [self addPeripheral:yPeripheral];
            }
        }
        if (yPeripheral) {
            [tempArray addObject:yPeripheral];
        }
    }
    
    result = [NSArray arrayWithArray:tempArray];

    return result;
}



#pragma mark - Connection Methods

- (void)connectPeripheral:(YMSCBPeripheral *)yPeripheral options:(nullable NSDictionary<NSString *,id> *)options {
    [self.centralInterface connectPeripheral:yPeripheral.peripheralInterface options:options];
}

- (void)cancelPeripheralConnection:(YMSCBPeripheral *)yPeripheral {
    [self.centralInterface cancelPeripheralConnection:yPeripheral.peripheralInterface];
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

#pragma mark - YMSCBCentralManagerInterfaceDelegate Protocol Methods

- (void)centralManagerDidUpdateState:(id<YMSCBCentralManagerInterface>)centralInterface {
    
    if (_centralInterface == centralInterface) {
    
        switch (centralInterface.state) {
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
        
        [self.delegate centralManagerDidUpdateState:self];
    }
}


- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didDiscoverPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    // this could get called by multiple threads at the same time
    dispatch_sync(self.ymsPeripheralsQueue, ^{
        BOOL shouldProcess = YES;
        
        if (self.filteredCallback) {
            shouldProcess = self.filteredCallback(peripheralInterface.name, advertisementData, RSSI);
        }
        
        if (shouldProcess && self.discoveredCallback) {
            YMSCBPeripheral *yPeripheral = (YMSCBPeripheral *)[self findPeripheralWithIdentifier:peripheralInterface.identifier];
            if (!yPeripheral) {
                yPeripheral = [self ymsPeripheralWithInterface:peripheralInterface advertisementData:advertisementData];
                if (yPeripheral) {
                    [self addPeripheral:yPeripheral];
                }
            }
            
            [yPeripheral didDiscoverPeripheralWithAdvertisementData:advertisementData RSSI:RSSI];
            self.discoveredCallback(yPeripheral, advertisementData, RSSI);
            
            if (yPeripheral && [self.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
                [self.delegate centralManager:self didDiscoverPeripheral:yPeripheral advertisementData:advertisementData RSSI:RSSI];
            }
        }   
    });
}


- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didConnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface {

    [self.logger logInfo:@"didConnectPeripheral" phase:YMSCBLoggerPhaseTypeResponse object:self.centralInterface];
    YMSCBPeripheral *yPeripheral = (YMSCBPeripheral *)[self findPeripheralWithIdentifier:peripheralInterface.identifier];
    [yPeripheral didConnectPeripheral];
    
    if (yPeripheral && [self.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
        [self.delegate centralManager:self didConnectPeripheral:yPeripheral];
    }
}


- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didDisconnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface error:(nullable NSError *)error {
    
    NSString *message = @"didDisconnectPeripheral";
    if (error) {
        [self.logger logError:message phase:YMSCBLoggerPhaseTypeResponse object:self.centralInterface error:error];
    } else {
        [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeResponse object:self.centralInterface];
    }
    
    YMSCBPeripheral *yPeripheral = (YMSCBPeripheral *)[self findPeripheralWithIdentifier:peripheralInterface.identifier];
    [yPeripheral didDisconnectPeripheral:error];
    
    if (yPeripheral && [self.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
        [self.delegate centralManager:self didDisconnectPeripheral:yPeripheral error:error];
    }
}


- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didFailToConnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface error:(nullable NSError *)error {
    NSString *message = @"didFailToConnectPeripheral";
    [self.logger logError:message phase:YMSCBLoggerPhaseTypeResponse object:self.centralInterface error:error];
    
    YMSCBPeripheral *yPeripheral = (YMSCBPeripheral *)[self findPeripheralWithIdentifier:peripheralInterface.identifier];
    [yPeripheral didFailToConnectPeripheral:error];
    
    if (yPeripheral && [self.delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)]) {
        [self.delegate centralManager:self didFailToConnectPeripheral:yPeripheral error:error];
    }
}



- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface willRestoreState:(NSDictionary<NSString *,id> *)dict {
    NSString *message = @"willRestoreState";
    [self.logger logInfo:message phase:YMSCBLoggerPhaseTypeResponse objects:@[self.centralInterface, dict]];

    if ([self.delegate respondsToSelector:@selector(centralManager:willRestoreState:)]) {
        [self.delegate centralManager:self willRestoreState:dict];
    }
}

#pragma mark - YMSCBLogger Protocol Methods

- (void)logError:(NSString *)message object:(id)object error:(NSError *)error {
    if (self.logger) {
        [self.logger logError:message object:object error:error];
    }
}

- (void)logError:(NSString *)message objects:(NSArray<id> *)objects error:(NSError *)error {
    if (self.logger) {
        [self.logger logError:message objects:objects error:error];
    }
}

- (void)logError:(NSString *)message phase:(uint8_t)phase object:(id)object error:(NSError *)error {
    if (self.logger) {
        [self.logger logError:message phase:phase object:object error:error];
    }
}

- (void)logError:(NSString *)message phase:(uint8_t)phase objects:(NSArray<id> *)objects error:(NSError *)error {
    if (self.logger) {
        [self.logger logError:message phase:phase objects:objects error:error];
    }
}

- (void)logWarn:(NSString *)message object:(id)object {
    if (self.logger) {
        [self.logger logWarn:message object:object];
    }
}

- (void)logWarn:(NSString *)message objects:(NSArray<id> *)objects {
    if (self.logger) {
        [self.logger logWarn:message objects:objects];
    }
}

- (void)logInfo:(NSString *)message object:(id)object {
    if (self.logger) {
        [self.logger logInfo:message object:object];
    }
}

- (void)logInfo:(NSString *)message objects:(NSArray<id> *)objects {
    if (self.logger) {
        [self.logger logInfo:message objects:objects];
    }
}

- (void)logInfo:(NSString *)message phase:(uint8_t)phase object:(id)object {
    if (self.logger) {
        [self.logger logInfo:message phase:phase object:object];
    }
}

- (void)logInfo:(NSString *)message phase:(uint8_t)phase objects:(NSArray<id> *)objects {
    if (self.logger) {
        [self.logger logInfo:message phase:phase objects:objects];
    }
}

- (void)logDebug:(NSString *)message object:(id)object {
    if (self.logger) {
        [self.logger logDebug:message object:object];
    }
}

- (void)logDebug:(NSString *)message objects:(NSArray<id> *)objects {
    if (self.logger) {
        [self.logger logDebug:message objects:objects];
    }
}

- (void)logVerbose:(NSString *)message object:(id)object {
    if (self.logger) {
        [self.logger logVerbose:message object:object];
    }
}

- (void)logVerbose:(NSString *)message objects:(NSArray<id> *)objects {
    if (self.logger) {
        [self.logger logVerbose:message objects:objects];
    }
}

@end

NS_ASSUME_NONNULL_END

