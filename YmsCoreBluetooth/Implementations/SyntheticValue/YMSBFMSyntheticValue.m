//
//  YMSBFMSyntheticValue.m
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticValue.h"
#import "YMSBFMSyntheticGeneratorConstant.h"
#import "YMSBFMSyntheticGeneratorRandom.h"
#import "YMSBFMSyntheticGeneratorLoop.h"
#import "YMSBFMSyntheticDelivererConstant.h"
#import "YMSBFMSyntheticDelivererOneShot.h"
#import "YMSBFMSyntheticDelivererRandom.h"

NS_ASSUME_NONNULL_BEGIN

@implementation YMSBFMSyntheticValue

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)json {
    self = [super init];
    if (self) {
        NSDictionary *delivererJson = json[@"deliverer"];
        NSString *delivererType = delivererJson[@"type"];
        
        // TODO: Build JSON Validation
        if ([delivererType isEqualToString:@"CONSTANT"]) {
            _deliverer = [[YMSBFMSyntheticDelivererConstant alloc] initWithDeliveryTime:[delivererJson[@"delivery_time"] doubleValue]];
        } else if ([delivererType isEqualToString:@"ONESHOT"]) {
            _deliverer = [[YMSBFMSyntheticDelivererOneShot alloc] initWithDeliveryTime:[delivererJson[@"delivery_time"] doubleValue]];
        } else if ([delivererType isEqualToString:@"RANDOM"]) {
            _deliverer = [[YMSBFMSyntheticDelivererRandom alloc] initWithLower:delivererJson[@"lower"] upper:delivererJson[@"upper"]];
        }
        
        NSDictionary *generatorJson = json[@"generator"];
        NSString *generatorType = generatorJson[@"type"];
        
        // TODO: Build JSON Validation
        if ([generatorType isEqualToString:@"CONSTANT"]) {
            _generator = [[YMSBFMSyntheticGeneratorConstant alloc] initWithValue:generatorJson[@"value"]];
        } else if ([generatorType isEqualToString:@"RANDOM"]) {
            _generator = [[YMSBFMSyntheticGeneratorRandom alloc] initWithLower:generatorJson[@"lower"] upper:generatorJson[@"upper"]];
        } else if ([generatorType isEqualToString:@"LOOP"]) {
            _generator = [[YMSBFMSyntheticGeneratorLoop alloc] initWithRange:generatorJson[@"range"] step:generatorJson[@"step"] repeat:[generatorJson[@"repeat"] boolValue]];
        }
    }
    return self;
}

- (void)genValueAndTime:(void (^)(NSNumber *, NSTimeInterval, NSError *))result {
    NSError *error = nil;
    
    NSNumber *value = [_generator genValue:&error];
    if (error) {
        result(value, 0, error);
        return;
    }
    
    NSTimeInterval dt = [_deliverer genTime:&error];
    result(value, dt, error);
}

- (BOOL)hasNext {
    return _generator.hasNext && _deliverer.hasNext;
}

@end

NS_ASSUME_NONNULL_END
