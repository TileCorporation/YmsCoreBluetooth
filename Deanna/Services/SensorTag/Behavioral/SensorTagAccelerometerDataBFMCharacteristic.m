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

- (void)setIsNotifying:(BOOL)isNotifying {
    [super setIsNotifying:isNotifying];
    
    // TODO: Send message to stimulus generator
    
    NSLog(@"Hey! Accelerometer Data");
    // accelerometer data characteristic
    int8_t accelerometerValues[3] = {1, 8, 64};
    [self writeValue:[NSData dataWithBytes:&accelerometerValues length:sizeof(accelerometerValues)]];
    [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
    
    __block int8_t x = 1;
    __block int8_t y = 8;
    __block int8_t z = 64;
    for (int i = 0; i < 10; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            int8_t accelerometerValues[3] = {x, y, z};
            x += 10;
            y -= 10;
            z += 10;
            [self writeValue:[NSData dataWithBytes:&accelerometerValues length:sizeof(accelerometerValues)]];
            [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
        });
    }
}

@end
