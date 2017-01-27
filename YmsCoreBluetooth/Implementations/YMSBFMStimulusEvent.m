//
//  YMSBFMStimulusEvent.m
//  Deanna
//
//  Created by Paul Wong on 1/26/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMStimulusEvent.h"
#import "YMSCBCentralManager.h"
#import "YMSCBPeripheral.h"
#import "YMSCBService.h"
#import "YMSCBCharacteristic.h"

NS_ASSUME_NONNULL_BEGIN

@implementation YMSBFMStimulusEvent

- (nullable instancetype)initWithTime:(NSDate *)time type:(YMSBFMStimulusEventType)type {
    self = [super init];
    if (self) {
        _time = time;
        _type = type;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", _time];
}

@end

NS_ASSUME_NONNULL_END
