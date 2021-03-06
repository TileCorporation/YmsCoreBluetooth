//
//  YMSBFMCentralManager.m
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMCentralManager.h"
#import "YMSBFMPeripheral.h"
#import "YMSBFMPeripheralConfiguration.h"
#import "YMSBFMStimulusGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMCentralManager ()
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nullable, nonatomic, strong) NSDictionary<NSString *, id> *options;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBPeripheralInterface>> *peripherals;
@end

@implementation YMSBFMCentralManager

- (nullable instancetype)initWithDelegate:(nullable id<YMSCBCentralManagerInterfaceDelegate>)delegate
                                    queue:(nullable dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _queue = queue;
        _peripherals = [NSMutableDictionary new];
        
        _state = CBCentralManagerStatePoweredOn;
        [self.delegate centralManagerDidUpdateState:self];
    }
    return self;
}

- (nullable instancetype)initWithDelegate:(nullable id<YMSCBCentralManagerInterfaceDelegate>)delegate
                                    queue:(nullable dispatch_queue_t)queue
                                  options:(nullable NSDictionary<NSString *, id> *)options {
    
    self = [super init];
    if (self) {
        _delegate = delegate;
        _queue = queue;
        _options = options;
        _peripherals = [NSMutableDictionary new];
        
        _state = CBCentralManagerStatePoweredOn;
        [self.delegate centralManagerDidUpdateState:self];
    }
    return self;
}

- (nullable NSArray<id<YMSCBPeripheralInterface>> *)retrievePeripheralsWithIdentifiers:(nullable NSArray<NSUUID *> *)identifiers {
    // TODO: Implement when modeling state restoration.
    return nil;
}

- (nullable NSArray<id<YMSCBPeripheralInterface>> *)retrieveConnectedPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs {
    // TODO: Implement when modeling state restoration.
    return nil;
}

- (void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options {
    [_stimulusGenerator scanForPeripheralsWithServices:serviceUUIDs options:options];
}

- (void)stopScan {
    [_stimulusGenerator stopScan];
}

- (void)connectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface options:(nullable NSDictionary<NSString *, id> *)options {
    // TODO: Support real connection lifecycle
    [_stimulusGenerator connectPeripheral:peripheralInterface options:options];
}

- (void)cancelPeripheralConnection:(id<YMSCBPeripheralInterface>)peripheralInterface {
    // TODO: Support real connection lifecycle
    [_stimulusGenerator cancelPeripheralConnection:peripheralInterface];
}

// MARK: - YMSCBCentralManagerInterfaceDelegate Methods

- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didDiscoverPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if ([self.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
        [self.delegate centralManager:self didDiscoverPeripheral:peripheralInterface advertisementData:advertisementData RSSI:RSSI];
    }
}

- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didConnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface {
    if ([self.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
        [self.delegate centralManager:self didConnectPeripheral:peripheralInterface];
    }
}

- (void)centralManager:(id<YMSCBCentralManagerInterface>)centralInterface didDisconnectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface error:(nullable NSError *)error {
    if ([self.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
        [self.delegate centralManager:self didDisconnectPeripheral:peripheralInterface error:error];
    }
}

@end

NS_ASSUME_NONNULL_END
