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

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMPeripheral ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBServiceInterface>> *servicesByUUID;
@end

@implementation YMSBFMPeripheral

- (nullable instancetype)initWithCentral:(id<YMSCBCentralManagerInterface>)central {
    self = [super init];
    if (self) {
        _central = central;
        _servicesByUUID = [NSMutableDictionary new];
        _name = @"Sensor";
        _identifier = [[NSUUID alloc] initWithUUIDString:@"D54414EB-2229-43C5-91C8-748F37F200E1"];
    }
    return self;
}

- (void)readRSSI {
    
}

- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs {
    NSError *didDiscoverServices = nil;
    
    // TODO: Handle case when serviceUUIDs is nil
    
    for (CBUUID *serviceUUID in serviceUUIDs) {
        YMSBFMService *service = [[YMSBFMService alloc] initWithCBUUID:serviceUUID peripheralInterface:self];
        _servicesByUUID[serviceUUID.UUIDString] = service;
    }
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)]) {
        [self.delegate peripheral:self didDiscoverServices:didDiscoverServices];
    }
}

- (void)discoverIncludedServices:(nullable NSArray<CBUUID *> *)includedServiceUUIDs forService:(id<YMSCBServiceInterface>)yService {
    // TODO: implement me
}

- (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(id<YMSCBServiceInterface>)yService {
    NSError *error = nil;
    
    YMSBFMService *service = (YMSBFMService *)yService;
    [service addCharacteristicsWithUUIDs:characteristicUUIDs];
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
        [self.delegate peripheral:self didDiscoverCharacteristicsForService:yService error:error];
    }
}

- (void)readValueForCharacteristic:(id<YMSCBCharacteristicInterface>)yCharacteristic {
    
}

- (void)writeValue:(NSData *)data forCharacteristic:(id<YMSCBCharacteristicInterface>)yCharacteristic type:(CBCharacteristicWriteType)type {
    
}

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(id<YMSCBCharacteristicInterface>)yCharacteristic {
    
}

- (void)discoverDescriptorsForCharacteristic:(id<YMSCBCharacteristicInterface>)yCharacteristic {
    
}

- (void)readValueForDescriptor:(id<YMSCBDescriptorInterface>)yDescriptor {
    
}

- (void)writeValue:(NSData *)data forDescriptor:(id<YMSCBDescriptorInterface>)yDescriptor {
    
}

- (nullable NSArray<id<YMSCBServiceInterface>> *)services {
    NSArray<id<YMSCBServiceInterface>> *result = nil;
    result = _servicesByUUID.allValues;
    return result;
}

@end

NS_ASSUME_NONNULL_END
