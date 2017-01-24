//
//  YMSBFMPeripheral.m
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMPeripheral.h"
#import "YMSBFMCentralManager.h"
#import "YMSBFMService.h"
#import "YMSCBService.h"
#import "YMSBFMCharacteristic.h"
#import "YMSBFMConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMPeripheral ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBServiceInterface>> *servicesByUUID;
@property (nonatomic, strong) YMSBFMConfig *config;
@end

@implementation YMSBFMPeripheral

- (nullable instancetype)initWithCentral:(id<YMSCBCentralManagerInterface>)central config:(YMSBFMConfig *)config {
    self = [super init];
    if (self) {
        _central = central;
        _name = config.peripheralName;
        _identifier = [[NSUUID alloc] initWithUUIDString:config.peripheralUUID];
        _servicesByUUID = [NSMutableDictionary new];
        _config = config;
    }
    return self;
}

- (void)readRSSI {

}

- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs {
    NSError *didDiscoverServices = nil;
    
    if (!serviceUUIDs) {
        // TODO: Handle case when serviceUUIDs is nil
    } else {
        for (NSDictionary<NSString *, id> *service in _config.services) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"UUIDString == %@", service[@"uuid"]];
            NSArray *result = [serviceUUIDs filteredArrayUsingPredicate:predicate];
            
            if (result.count == 1) {
                Class YMSBFMService = NSClassFromString(service[@"name"]);
                if (YMSBFMService) {
                    id service = [[YMSBFMService alloc] initWithCBUUID:result.firstObject peripheralInterface:self];
                    _servicesByUUID[result.firstObject] = service;
                }
            }
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)]) {
        [self.delegate peripheral:self didDiscoverServices:didDiscoverServices];
    }
}

- (void)discoverIncludedServices:(nullable NSArray<CBUUID *> *)includedServiceUUIDs forService:(id<YMSCBServiceInterface>)serviceInterface {
    // TODO: implement me
}

- (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(id<YMSCBServiceInterface>)serviceInterface {
    NSError *error = nil;
    
    YMSBFMService *service = (YMSBFMService *)serviceInterface;
    [service addCharacteristicsWithUUIDs:characteristicUUIDs config:self.config];
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
        [self.delegate peripheral:self didDiscoverCharacteristicsForService:serviceInterface error:error];
    }
}

- (void)readValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    NSError *error = nil;
    if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]) {
        [self.delegate peripheral:self didUpdateValueForCharacteristic:characteristicInterface error:error];
    }
}

- (void)writeValue:(NSData *)data forCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface type:(CBCharacteristicWriteType)type {
    NSError *error = nil;
    YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)characteristicInterface;
    if ([characteristic.UUID.UUIDString isEqualToString:@"F000AA02-0451-4000-B000-000000000000"]) {
        // temperature config characteristic
        [characteristic writeValue:data];
    } else if ([characteristic.UUID.UUIDString isEqualToString:@"F000AA12-0451-4000-B000-000000000000"]) {
        // accelerometer config characteristic
        [characteristic writeValue:data];
    }
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
        [self.delegate peripheral:self didWriteValueForCharacteristic:characteristicInterface error:error];
    }
}

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    NSError *error = nil;
    YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)characteristicInterface;
    characteristic.isNotifying = enabled;
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]) {
        [self.delegate peripheral:self didUpdateNotificationStateForCharacteristic:characteristicInterface error:error];
    }
}

- (void)discoverDescriptorsForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    
}

- (void)readValueForDescriptor:(id<YMSCBDescriptorInterface>)descriptorInterface {
    
}

- (void)writeValue:(NSData *)data forDescriptor:(id<YMSCBDescriptorInterface>)descriptorInterface {
    
}

- (nullable NSArray<id<YMSCBServiceInterface>> *)services {
    NSArray<id<YMSCBServiceInterface>> *result = nil;
    result = _servicesByUUID.allValues;
    return result;
}

- (void)setConnectionState:(CBPeripheralState)state {
    _state = state;
}

@end

NS_ASSUME_NONNULL_END
