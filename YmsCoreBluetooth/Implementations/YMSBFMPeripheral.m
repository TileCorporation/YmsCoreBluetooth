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
#import "YMSBFMConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMPeripheral ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBServiceInterface>> *servicesByUUID;
@property (nonatomic, strong) YMSBFMConfiguration *modelConfiguration;
@end

@implementation YMSBFMPeripheral

- (nullable instancetype)initWithCentral:(id<YMSCBCentralManagerInterface>)central modelConfiguration:(YMSBFMConfiguration *)modelConfiguration {
    self = [super init];
    if (self) {
        _central = central;
        _servicesByUUID = [NSMutableDictionary new];
        // TODO: Get ID from the stimulus generator
        _identifier = [[NSUUID alloc] initWithUUIDString:@"D54414EB-2229-43C5-91C8-748F37F200E1"];
        _modelConfiguration = modelConfiguration;
        _name = [_modelConfiguration peripheralWithName:NSStringFromClass(self.class)][@"name"];
    }
    return self;
}

- (void)readRSSI {
    // TODO: Get RSSI from the stimulus generator
    NSError *error = nil;
    
    int lowerBound = 1;
    int upperBound = 100;
    int rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
    NSNumber *randomNumber = @(-rndValue);
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didReadRSSI:error:)]) {
        [self.delegate peripheral:self didReadRSSI:randomNumber error:error];
    }
}

- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs {
    NSError *didDiscoverServices = nil;
    
    if (!serviceUUIDs) {
        // TODO: Handle case when serviceUUIDs is nil
    } else {
        NSDictionary<NSString *, NSDictionary<NSString *, id> *> *services = [_modelConfiguration servicesForPeripheral:NSStringFromClass(self.class)];
        for (CBUUID *serviceUUID in serviceUUIDs) {
            NSDictionary<NSString *, id> *service = services[serviceUUID.UUIDString];
            
            Class YMSBFMService = NSClassFromString(service[@"class_name"]);
            if (YMSBFMService) {
                id service = [[YMSBFMService alloc] initWithCBUUID:serviceUUID peripheralInterface:self modelConfiguration:_modelConfiguration];
                _servicesByUUID[serviceUUID.UUIDString] = service;
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
    [service addCharacteristicsWithUUIDs:characteristicUUIDs];
    
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
    // TODO: Apply write to stimulus generator
    NSError *error = nil;
    YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)characteristicInterface;
    [characteristic writeValue:data];
    
    // TODO: Get write response from stimulus generator. How to make more realistic like adding a delay?
    if ([self.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
        [self.delegate peripheral:self didWriteValueForCharacteristic:characteristicInterface error:error];
    }
}

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    NSError *error = nil;
    YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)characteristicInterface;
    characteristic.isNotifying = enabled;
    
    // TODO: Send message to stimulus generator that the characteristic isNotifying
    if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]) {
        [self.delegate peripheral:self didUpdateNotificationStateForCharacteristic:characteristicInterface error:error];
    }
}

- (void)discoverDescriptorsForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    // TODO: TBD
}

- (void)readValueForDescriptor:(id<YMSCBDescriptorInterface>)descriptorInterface {
    // TODO: TBD
}

- (void)writeValue:(NSData *)data forDescriptor:(id<YMSCBDescriptorInterface>)descriptorInterface {
    // TODO: TBD
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
