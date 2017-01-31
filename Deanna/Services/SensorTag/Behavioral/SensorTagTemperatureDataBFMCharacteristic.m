//
//  SensorTagTemperatureDataBFMCharacteristic.m
//  Deanna
//
//  Created by Paul Wong on 1/24/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "SensorTagTemperatureDataBFMCharacteristic.h"

@implementation SensorTagTemperatureDataBFMCharacteristic

- (void)didUpdateValueWithPeripheral:(id<YMSCBPeripheralInterface>)peripheral error:(NSError *)error {
    uint8_t value = (uint8_t)self.behavioralValue.intValue;
    uint8_t temperatureValues[4] = {value, value, value, value};
    NSData *valueData = [NSData dataWithBytes:&temperatureValues length:sizeof(temperatureValues)];
    [self writeValue:valueData];
    
    [super didUpdateValueWithPeripheral:peripheral error:error];
}

@end
