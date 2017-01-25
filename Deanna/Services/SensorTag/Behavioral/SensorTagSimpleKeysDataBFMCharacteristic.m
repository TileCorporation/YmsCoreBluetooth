//
//  SensorTagSimpleKeysDataBFMCharacteristic.m
//  Deanna
//
//  Created by Paul Wong on 1/24/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "SensorTagSimpleKeysDataBFMCharacteristic.h"
#import "TISensorTag.h"
#import "YMSCBUtils.h"
#import "YMSCBService.h"
#import "YMSCBPeripheral.h"

@implementation SensorTagSimpleKeysDataBFMCharacteristic

- (void)setIsNotifying:(BOOL)isNotifying {
    [super setIsNotifying:isNotifying];
    
    // TODO: Send message to stimulus generator
    
    NSLog(@"Hey! Simple Keys Data");
    uint8_t sksValue = 0x2;
    [self writeValue:[NSData dataWithBytes:&sksValue length:sizeof(sksValue)]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            uint8_t sksValue = 0x1;
            [self writeValue:[NSData dataWithBytes:&sksValue length:sizeof(sksValue)]];
            [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                uint8_t sksValue = 0x3;
                [self writeValue:[NSData dataWithBytes:&sksValue length:sizeof(sksValue)]];
                [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    uint8_t sksValue = 0x0;
                    [self writeValue:[NSData dataWithBytes:&sksValue length:sizeof(sksValue)]];
                    [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
                });
            });
        });
    });
}

@end
