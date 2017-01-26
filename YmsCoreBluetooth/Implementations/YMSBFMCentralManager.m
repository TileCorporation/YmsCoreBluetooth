//
//  YMSBFMCentralManager.m
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMCentralManager.h"
#import "YMSBFMPeripheral.h"
#import "YMSBFMConfiguration.h"
#import "YMSBFMStimulusGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMCentralManager ()
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nullable, nonatomic, strong) NSDictionary<NSString *, id> *options;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBPeripheralInterface>> *peripherals;
@property (nonatomic, strong) YMSBFMConfiguration *modelConfiguration;
@end

@implementation YMSBFMCentralManager

- (nullable instancetype)initWithDelegate:(nullable id<YMSCBCentralManagerInterfaceDelegate>)delegate
                                    queue:(nullable dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _queue = queue;
        _peripherals = [NSMutableDictionary new];
        _modelConfiguration = [[YMSBFMConfiguration alloc] initWithConfigurationFile:nil];
        
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
        _modelConfiguration = [[YMSBFMConfiguration alloc] initWithConfigurationFile:nil];
        
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
    // TODO: Stimulus generator should handle this
    for (NSDictionary<id, id> *peripheral in _modelConfiguration.peripherals) {
        Class YMSBFMPeripheral = NSClassFromString(peripheral[@"class_name"]);
        if (YMSBFMPeripheral) {
            id peripheral = [[YMSBFMPeripheral alloc] initWithCentral:self modelConfiguration:_modelConfiguration];
            
            if ([self.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
                [self.delegate centralManager:self didDiscoverPeripheral:peripheral advertisementData:@{} RSSI:@(-54)];
            }
        }
    }
}

- (void)stopScan {
    
}

- (void)connectPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface options:(nullable NSDictionary<NSString *, id> *)options {
    YMSBFMPeripheral *peripheral = (YMSBFMPeripheral *)peripheralInterface;
    
    [peripheral setConnectionState:CBPeripheralStateConnected];
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
        [self.delegate centralManager:self didConnectPeripheral:peripheralInterface];
    }
}

- (void)cancelPeripheralConnection:(id<YMSCBPeripheralInterface>)peripheralInterface {
    NSError *error = nil;
    
    YMSBFMPeripheral *peripheral = (YMSBFMPeripheral *)peripheralInterface;
    
    [peripheral setConnectionState:CBPeripheralStateDisconnected];
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
        [self.delegate centralManager:self didDisconnectPeripheral:peripheralInterface error:error];
    }
}

@end

NS_ASSUME_NONNULL_END
