//
//  YMSCBNativeCentralManager.m
//  Deanna
//
//  Created by Charles Choi on 1/10/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSCBNativeCentralManager.h"
#import "YMSCBNativePeripheral.h"
#import "YMSCBCentralManager.h"
#import "YMSCBPeripheral.h"

@interface YMSCBNativeCentralManager ()
@property (nonatomic, nonnull, strong) CBCentralManager *cbCentralManager;
@property (nonatomic, strong) NSMutableDictionary *peripheralInterfaces;
@end

@implementation YMSCBNativeCentralManager

- (nullable instancetype)initWithDelegate:(id<YMSCBCentralManagerInterfaceDelegate>)delegate
                                    queue:(nullable dispatch_queue_t)queue {

    self = [super init];
    if (self) {
        _cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
        _delegate = delegate;
        _peripheralInterfaces = [NSMutableDictionary new];
    }
    return self;
}

- (nullable instancetype)initWithDelegate:(nullable id<YMSCBCentralManagerInterfaceDelegate>)delegate
                                    queue:(nullable dispatch_queue_t)queue
                                  options:(nullable NSDictionary<NSString *, id> *)options {

    self = [super init];
    if (self) {
        _cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:options];
        _delegate = delegate;
        _peripheralInterfaces = [NSMutableDictionary new];
    }

    return self;
}

- (CBCentralManagerState)state {
    // TODO: update to use CBManagerState when supporting iOS 10 minimum
    CBCentralManagerState result;
    result = (CBCentralManagerState)_cbCentralManager.state;
    return result;
}

- (id<YMSCBPeripheralInterface>)peripheralInterfaceForPeripheral:(CBPeripheral *)peripheral {
    // TODO: make thread safe
    
    id<YMSCBPeripheralInterface> peripheralInterface = _peripheralInterfaces[peripheral];
    if (!peripheralInterface) {
        peripheralInterface = [[YMSCBNativePeripheral alloc] initWithPeripheral:peripheral];
        // !!!: Note that the peripheral interface needs access to the parent centralInterface
        //peripheralInterface.centralInterface = self;
        _peripheralInterfaces[peripheral] = peripheralInterface;
    }
    return peripheralInterface;
}


- (nullable NSArray<id<YMSCBPeripheralInterface>> *)retrievePeripheralsWithIdentifiers:(nullable NSArray<NSUUID *> *)identifiers {
    
    NSArray<id<YMSCBPeripheralInterface>> *result = nil;
    NSArray<CBPeripheral *> *retrievedPeripherals = nil;
    retrievedPeripherals = [_cbCentralManager retrievePeripheralsWithIdentifiers:identifiers];
    
    NSMutableArray<id<YMSCBPeripheralInterface>> *tempArray = [NSMutableArray new];
    
    for (CBPeripheral *peripheral in retrievedPeripherals) {
        id<YMSCBPeripheralInterface> peripheralInterface = [self peripheralInterfaceForPeripheral:peripheral];
        [tempArray addObject:peripheralInterface];
    }
    
    result = [NSArray arrayWithArray:tempArray];
    return result;
}

- (nullable NSArray<id<YMSCBPeripheralInterface>> *)retrieveConnectedPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs {

    NSArray<id<YMSCBPeripheralInterface>> *result = nil;
    NSArray<CBPeripheral *> *retrievedPeripherals = nil;
    retrievedPeripherals = [_cbCentralManager retrieveConnectedPeripheralsWithServices:serviceUUIDs];
    
    NSMutableArray<id<YMSCBPeripheralInterface>> *tempArray = [NSMutableArray new];
    
    for (CBPeripheral *peripheral in retrievedPeripherals) {
        id<YMSCBPeripheralInterface> peripheralInterface = [self peripheralInterfaceForPeripheral:peripheral];
        [tempArray addObject:peripheralInterface];
    }
    
    result = [NSArray arrayWithArray:tempArray];
    return result;

}

- (void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options {
    [_cbCentralManager scanForPeripheralsWithServices:serviceUUIDs options:options];
}

- (void)stopScan {
    [_cbCentralManager stopScan];
}

- (void)connectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface options:(nullable NSDictionary<NSString *, id> *)options {
    YMSCBNativePeripheral *nativePeripheral = (YMSCBNativePeripheral *)peripheralInterface;
    [_cbCentralManager connectPeripheral:nativePeripheral.cbPeripheral options:options];
}

- (void)cancelPeripheralConnection:(id<YMSCBPeripheralInterface>)peripheralInterface {
    YMSCBNativePeripheral *nativePeripheral = (YMSCBNativePeripheral *)peripheralInterface;
    [_cbCentralManager cancelPeripheralConnection:nativePeripheral.cbPeripheral];
}


#pragma mark - CBCentralManagerDelegate Methods


- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [self.delegate centralManagerDidUpdateState:self];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    id<YMSCBPeripheralInterface> peripheralInterface = [self peripheralInterfaceForPeripheral:peripheral];
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
        [self.delegate centralManager:self didDiscoverPeripheral:peripheralInterface advertisementData:advertisementData RSSI:RSSI];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    id<YMSCBPeripheralInterface> peripheralInterface = [self peripheralInterfaceForPeripheral:peripheral];
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
        [self.delegate centralManager:self didConnectPeripheral:peripheralInterface];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    id<YMSCBPeripheralInterface> peripheralInterface = [self peripheralInterfaceForPeripheral:peripheral];
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)]) {
        [self.delegate centralManager:self didFailToConnectPeripheral:peripheralInterface error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    id<YMSCBPeripheralInterface> peripheralInterface = [self peripheralInterfaceForPeripheral:peripheral];
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
        [self.delegate centralManager:self didDisconnectPeripheral:peripheralInterface error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict {
    if ([self.delegate respondsToSelector:@selector(centralManager:willRestoreState:)]) {
        [self.delegate centralManager:self willRestoreState:dict];
    }
}


@end
