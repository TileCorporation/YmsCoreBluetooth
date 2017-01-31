//
//  SensorTagBFMPeripheral.m
//  Deanna
//
//  Created by Paul Wong on 1/24/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "SensorTagBFMPeripheral.h"
#import "YMSBFMCharacteristic.h"

@implementation SensorTagBFMPeripheral

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didUpdateValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(NSError *)error {
    // TODO: Put this logic down in the characteristic level
    [super peripheral:peripheralInterface didUpdateValueForCharacteristic:characteristicInterface error:error];
    
    YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)characteristicInterface;
    if ([characteristic.UUID.UUIDString isEqualToString:@"FFE1"]) {
        uint8_t value = (uint8_t)characteristic.behavioralValue.intValue;
        NSData *valueData = [NSData dataWithBytes:&value length:sizeof(value)];
        [characteristic writeValue:valueData];
    } else if ([characteristic.UUID.UUIDString isEqualToString:@"F000AA01-0451-4000-B000-000000000000"]) {
        uint8_t value = (uint8_t)characteristic.behavioralValue.intValue;
        uint8_t temperatureValues[4] = {value, value, value, value};
        NSData *valueData = [NSData dataWithBytes:&temperatureValues length:sizeof(temperatureValues)];
        [characteristic writeValue:valueData];
    }
}

- (void)peripheral:(id<YMSCBPeripheralInterface>)peripheralInterface didWriteValueForCharacteristic:(id<YMSCBCharacteristicInterface>)characteristicInterface error:(NSError *)error {
    // TODO: Put this logic down in the characteristic level
    [super peripheral:peripheralInterface didWriteValueForCharacteristic:characteristicInterface error:error];
    
    YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)characteristicInterface;
    if ([characteristic.UUID.UUIDString isEqualToString:@"F000AA02-0451-4000-B000-000000000000"]) {
        NSLog(@"didWriteValueForCharacteristic for %@", characteristic.UUID);
    }
}

@end
