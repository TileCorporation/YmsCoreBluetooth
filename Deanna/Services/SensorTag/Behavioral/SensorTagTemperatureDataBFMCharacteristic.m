//
//  SensorTagTemperatureDataBFMCharacteristic.m
//  Deanna
//
//  Created by Paul Wong on 1/24/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "SensorTagTemperatureDataBFMCharacteristic.h"
#import "TISensorTag.h"
#import "YMSCBUtils.h"
#import "YMSCBService.h"
#import "YMSCBPeripheral.h"

@implementation SensorTagTemperatureDataBFMCharacteristic

- (void)setIsNotifying:(BOOL)isNotifying {
    [super setIsNotifying:isNotifying];
    
    // TODO: Send message to stimulus generator
    
    NSLog(@"Hey! Temperature Data");
    // temperature data characteristic
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uint8_t temperatureValues[4] = {0x51, 0xFF, 0x80, 0x0B};
        [self writeValue:[NSData dataWithBytes:&temperatureValues length:sizeof(temperatureValues)]];
        [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
        
        __block uint8_t v0 = 0x51;
        __block uint8_t v1 = 0xFF;
        __block uint8_t v2 = 0x80;
        __block uint8_t v3 = 0x0B;
        for (int i = 0; i < 10; i++) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                uint8_t temperatureValues[4] = {v0, v1, v2, v3};
                v0 += 1;
                v2 += 1;
                [self writeValue:[NSData dataWithBytes:&temperatureValues length:sizeof(temperatureValues)]];
                [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
            });
        }
    });
}

@end
