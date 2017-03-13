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
#import "YMSBFMStimulusGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMPeripheral ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBServiceInterface>> *servicesByUUID;
@property (nonatomic, strong) YMSBFMStimulusGenerator *stimulusGenerator;
@end

@implementation YMSBFMPeripheral

- (nullable instancetype)initWithCentral:(id<YMSCBCentralManagerInterface>)central stimulusGenerator:(YMSBFMStimulusGenerator *)stimulusGenerator identifier:(NSString *)identifier name:(NSString *)name {
    self = [super init];
    if (self) {
        _central = central;
        _stimulusGenerator = stimulusGenerator;
        _servicesByUUID = [NSMutableDictionary new];
        _identifier = [[NSUUID alloc] initWithUUIDString:identifier];
        _name = name;
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
    if (!serviceUUIDs) {
        // TODO: Handle case when serviceUUIDs is nil
    } else {
        [_stimulusGenerator discoverServices:serviceUUIDs peripheral:self];
    }
}

- (void)discoverIncludedServices:(nullable NSArray<CBUUID *> *)includedServiceUUIDs forService:(id<YMSCBServiceInterface>)serviceInterface {
    // TODO: implement me
}

- (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(id<YMSCBServiceInterface>)serviceInterface {
    [_stimulusGenerator discoverCharacteristics:characteristicUUIDs forService:serviceInterface peripheral:self];
}

- (void)readValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface {
    [_stimulusGenerator readValueForCharacteristic:characteristicInterface];
}

- (void)writeValue:(NSData *)data forCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface type:(CBCharacteristicWriteType)type {
    [_stimulusGenerator writeValue:data forCharacteristic:characteristicInterface type:type];
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

- (void)addService:(id<YMSCBServiceInterface>)service {
    _servicesByUUID[service.UUID.UUIDString] = service;
}

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverServices:(nullable NSError *)error {
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)]) {
        [self.delegate peripheral:peripheralInterface didDiscoverServices:error];
    }
}

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didDiscoverCharacteristicsForService:(id<YMSCBServiceInterface>)serviceInterface error:(nullable NSError *)error {
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
        [self.delegate peripheral:peripheralInterface didDiscoverCharacteristicsForService:serviceInterface error:error];
    }
}

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didUpdateValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error {
    if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]) {
        [self.delegate peripheral:self didUpdateValueForCharacteristic:characteristicInterface error:error];
    }
}

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didWriteValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(nullable NSError *)error {
    if ([self.delegate respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
        [self.delegate peripheral:self didWriteValueForCharacteristic:characteristicInterface error:error];
    }
}

@end

NS_ASSUME_NONNULL_END
