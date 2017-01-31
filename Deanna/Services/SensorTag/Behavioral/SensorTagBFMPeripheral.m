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
    [super peripheral:peripheralInterface didUpdateValueForCharacteristic:characteristicInterface error:error];
    
    YMSBFMCharacteristic *characteristic = (YMSBFMCharacteristic *)characteristicInterface;
    if ([characteristic.UUID.UUIDString isEqualToString:@"FFE1"]) {
        uint8_t value = (uint8_t)characteristic.behavioralValue.intValue;
        NSData *valueData = [NSData dataWithBytes:&value length:sizeof(value)];
        [characteristic writeValue:valueData];
    }
}

@end
