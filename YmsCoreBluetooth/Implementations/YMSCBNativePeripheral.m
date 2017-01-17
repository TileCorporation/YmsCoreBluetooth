//
//  YMSCBNativePeripheral.m
//  Deanna
//
//  Created by Charles Choi on 1/11/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import CoreBluetooth;
#import "YMSCBNativePeripheral.h"
#import "YMSCBNativeCentralManager.h"
#import "YMSCBNativeService.h"
#import "YMSCBNativeCharacteristic.h"

NS_ASSUME_NONNULL_BEGIN
@interface YMSCBNativePeripheral()


@property (nonatomic, strong) NSMutableDictionary<NSString *, YMSCBNativeService*> *nativeServices;

@end

@implementation YMSCBNativePeripheral

- (nullable instancetype)initWithPeripheral:(CBPeripheral *)peripheral {
    self = [super init];
    if (self) {
        _cbPeripheral = peripheral;
        _cbPeripheral.delegate = self;
        _nativeServices = [NSMutableDictionary new];
    }
    return self;
}

- (nullable NSString *)name {
    NSString *result = nil;
    result = _cbPeripheral.name;
    return result;
}

- (NSUUID *)identifier {
    NSUUID *result = nil;
    result = _cbPeripheral.identifier;
    return result;
}

- (CBPeripheralState)state {
    CBPeripheralState result;
    result = _cbPeripheral.state;
    return result;
}

- (nullable NSArray<id<YMSCBServiceInterface>> *)services {
    NSArray<id<YMSCBServiceInterface>> *result = nil;
    
    for (CBService *service in _cbPeripheral.services) {
        NSString *key = service.UUID.UUIDString;
        
        if (!_nativeServices[key]) {
            YMSCBNativeService *serviceInterface = [[YMSCBNativeService alloc] initWithPeripheral:self service:service];
            _nativeServices[key] = serviceInterface;
        }
    }
    
    result = [_nativeServices allValues];
    return result;
}

- (void)readRSSI {
    [_cbPeripheral readRSSI];
}

- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs {
    [_cbPeripheral discoverServices:serviceUUIDs];
}

- (void)discoverIncludedServices:(nullable NSArray<CBUUID *> *)includedServiceUUIDs forService:(id<YMSCBServiceInterface>)serviceInterface {

    YMSCBNativeService *nativeService = (YMSCBNativeService *)serviceInterface;
    [_cbPeripheral discoverIncludedServices:includedServiceUUIDs forService:nativeService.cbService];
}

- (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(id<YMSCBServiceInterface>)serviceInterface {
    
    YMSCBNativeService *nativeService = (YMSCBNativeService *)serviceInterface;
    [_cbPeripheral discoverCharacteristics:characteristicUUIDs forService:nativeService.cbService];
}

- (void)readValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    
    YMSCBNativeCharacteristic *nativeCt = (YMSCBNativeCharacteristic *)characteristicInterface;
    [_cbPeripheral readValueForCharacteristic:nativeCt.cbCharacteristic];
}

- (void)writeValue:(NSData *)data forCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface type:(CBCharacteristicWriteType)type {
    
    YMSCBNativeCharacteristic *nativeCt = (YMSCBNativeCharacteristic *)characteristicInterface;
    [_cbPeripheral writeValue:data forCharacteristic:nativeCt.cbCharacteristic type:type];
}

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    
    YMSCBNativeCharacteristic *nativeCt = (YMSCBNativeCharacteristic *)characteristicInterface;
    [_cbPeripheral setNotifyValue:enabled forCharacteristic:nativeCt.cbCharacteristic];
}

- (void)discoverDescriptorsForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    
    YMSCBNativeCharacteristic *nativeCt = (YMSCBNativeCharacteristic *)characteristicInterface;
    [_cbPeripheral discoverDescriptorsForCharacteristic:nativeCt.cbCharacteristic];
}

- (void)readValueForDescriptor:(id<YMSCBDescriptorInterface>)descriptorInterface {

    // TODO: implement
}

- (void)writeValue:(NSData *)data forDescriptor:(id<YMSCBDescriptorInterface>)descriptorInterface {
    
    // TODO: implement
}


#pragma mark - Utility Methods

- (nullable id<YMSCBCharacteristicInterface>)interfaceForCharacteristic:(CBCharacteristic *)characteristic {
    id<YMSCBCharacteristicInterface> result = nil;
    
    NSString *serviceKey = characteristic.service.UUID.UUIDString;
    id<YMSCBServiceInterface> serviceInterface = self.nativeServices[serviceKey];
    YMSCBNativeService *nativeService = (YMSCBNativeService *)serviceInterface;
    
    result = [nativeService interfaceForCharacteristic:characteristic];
    return result;
}


#pragma mark - CBPeripheralDelegate Methods

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {

    if ([self.delegate respondsToSelector:@selector(peripheralDidUpdateName:)]) {
        [self.delegate peripheralDidUpdateName:self];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
    if ([self.delegate respondsToSelector:@selector(peripheral:didModifyServices:)]) {
        [self.delegate peripheral:self didModifyServices:self.services];
    }
}



- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(nonnull NSNumber *)RSSI error:(nullable NSError *)error {
    if ([self.delegate respondsToSelector:@selector(peripheral:didReadRSSI:error:)]) {
        [self.delegate peripheral:self didReadRSSI:RSSI error:error];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    // Create YMSCBNativeService instances in `nativeServices`
    [self services];
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)]) {
        [self.delegate peripheral:self didDiscoverServices:error];
    }
}



- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error {
    id<YMSCBServiceInterface> serviceInterface = self.nativeServices[service.UUID.UUIDString];
    
    if (serviceInterface && [self.delegate respondsToSelector:@selector(peripheral:didDiscoverIncludedServicesForService:error:)]) {
        [self.delegate peripheral:self didDiscoverIncludedServicesForService:serviceInterface error:error];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    id<YMSCBServiceInterface> serviceInterface = self.nativeServices[service.UUID.UUIDString];
    
    [serviceInterface characteristics];
    
    if (serviceInterface && [self.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
        [self.delegate peripheral:self didDiscoverCharacteristicsForService:serviceInterface error:error];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    id<YMSCBCharacteristicInterface> characteristicInterface = [self interfaceForCharacteristic:characteristic];
    
    if (characteristicInterface && [self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]) {
        [self.delegate peripheral:self didUpdateValueForCharacteristic:characteristicInterface error:error];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    id<YMSCBCharacteristicInterface> characteristicInterface = [self interfaceForCharacteristic:characteristic];

    if (characteristicInterface && [self.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
        [self.delegate peripheral:self didWriteValueForCharacteristic:characteristicInterface error:error];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    id<YMSCBCharacteristicInterface> characteristicInterface = [self interfaceForCharacteristic:characteristic];
    
    if (characteristicInterface && [self.delegate respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]) {
        [self.delegate peripheral:self didUpdateNotificationStateForCharacteristic:characteristicInterface error:error];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    id<YMSCBCharacteristicInterface> characteristicInterface = [self interfaceForCharacteristic:characteristic];
    
    if (characteristicInterface && [self.delegate respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)]) {
        [self.delegate peripheral:self didDiscoverDescriptorsForCharacteristic:characteristicInterface error:error];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
    id<YMSCBCharacteristicInterface> characteristicInterface = [self interfaceForCharacteristic:descriptor.characteristic];
    YMSCBNativeCharacteristic *nativeCharacteristic = (YMSCBNativeCharacteristic *)characteristicInterface;
    
    id<YMSCBDescriptorInterface> descriptorInterface = [nativeCharacteristic interfaceForDescriptor:descriptor];
    
    if (descriptorInterface && [self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)]) {
        [self.delegate peripheral:self didUpdateValueForDescriptor:descriptorInterface error:error];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
    id<YMSCBCharacteristicInterface> characteristicInterface = [self interfaceForCharacteristic:descriptor.characteristic];
    YMSCBNativeCharacteristic *nativeCharacteristic = (YMSCBNativeCharacteristic *)characteristicInterface;
    
    id<YMSCBDescriptorInterface> descriptorInterface = [nativeCharacteristic interfaceForDescriptor:descriptor];
    
    if (descriptorInterface && [self.delegate respondsToSelector:@selector(peripheral:didWriteValueForDescriptor:error:)]) {
        [self.delegate peripheral:self didWriteValueForDescriptor:descriptorInterface error:error];
    }
}

@end

NS_ASSUME_NONNULL_END
