//
//  SensorTagSimpleKeysDataBFMCharacteristic.m
//  Deanna
//
//  Created by Paul Wong on 1/24/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "SensorTagSimpleKeysDataBFMCharacteristic.h"

@implementation SensorTagSimpleKeysDataBFMCharacteristic

- (void)didUpdateValueWithPeripheral:(id<YMSCBPeripheralInterface>)peripheral error:(NSError *)error {
    uint8_t value = (uint8_t)self.behavioralValue.intValue;
    NSData *valueData = [NSData dataWithBytes:&value length:sizeof(value)];
    [self writeValue:valueData];
    
    [super didUpdateValueWithPeripheral:peripheral error:error];
}

@end
