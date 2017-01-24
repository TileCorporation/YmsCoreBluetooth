//
//  SensorTagPeripheral.m
//  Deanna
//
//  Created by Paul Wong on 1/23/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "SensorTagPeripheral.h"
#import "YMSCBCentralManager.h"
#import "YMSBFMConfig.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SensorTagPeripheral

- (void)readRSSI {
    NSError *error = nil;
    
    int lowerBound = 1;
    int upperBound = 100;
    int rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
    NSNumber *randomNumber = @(-rndValue);
    
    if ([self.delegate respondsToSelector:@selector(peripheral:didReadRSSI:error:)]) {
        [self.delegate peripheral:self didReadRSSI:randomNumber error:error];
    }
}

@end

NS_ASSUME_NONNULL_END
