//
//  SensorTagAccelerometerDataBFMCharacteristic.m
//  Deanna
//
//  Created by Paul Wong on 1/24/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "SensorTagAccelerometerDataBFMCharacteristic.h"
#import "TISensorTag.h"
#import "YMSCBUtils.h"
#import "YMSCBService.h"
#import "YMSCBPeripheral.h"

@implementation SensorTagAccelerometerDataBFMCharacteristic

- (void)didUpdateValueWithPeripheral:(id<YMSCBPeripheralInterface>)peripheral error:(NSError *)error {
    int8_t value = self.behavioralValue.intValue;
    int8_t accelerometerValues[3] = {value, value*2, value*3};
    [self writeValue:[NSData dataWithBytes:&accelerometerValues length:sizeof(accelerometerValues)]];
    
    [super didUpdateValueWithPeripheral:peripheral error:error];
}

@end
