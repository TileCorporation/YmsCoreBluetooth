//
//  YMSBFMSyntheticValue.m
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticValue.h"
#import "YMSBFMSyntheticGeneratorConstant.h"
#import "YMSBFMSyntheticDelivererConstant.h"

NS_ASSUME_NONNULL_BEGIN

@implementation YMSBFMSyntheticValue

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)json {
    self = [super init];
    if (self) {
        NSDictionary *delivererJson = json[@"deliverer"];
        
        if ([delivererJson[@"type"] isEqualToString:@"CONSTANT"]) {
            // TODO: Build JSON Validation
            _deliverer = [[YMSBFMSyntheticDelivererConstant alloc] initWithDeliveryTime:[delivererJson[@"delivery_time"] doubleValue]];
        }
        
        NSDictionary *generatorJson = json[@"generator"];
        
        if ([generatorJson[@"type"] isEqualToString:@"CONSTANT"]) {
            // TODO: Build JSON Validation
            _generator = [[YMSBFMSyntheticGeneratorConstant alloc] initWithValue:generatorJson[@"value"]];
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

@end

NS_ASSUME_NONNULL_END
