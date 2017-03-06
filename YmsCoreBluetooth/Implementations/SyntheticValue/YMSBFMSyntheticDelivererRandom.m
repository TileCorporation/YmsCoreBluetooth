//
//  YMSBFMSyntheticDelivererRandom.m
//  Deanna
//
//  Created by Paul Wong on 1/30/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticDelivererRandom.h"

@interface YMSBFMSyntheticDelivererRandom ()

@property (nonatomic, strong, nullable) NSNumber *lower;
@property (nonatomic, strong, nullable) NSNumber *upper;

@end

@implementation YMSBFMSyntheticDelivererRandom

- (nullable instancetype)initWithLower:(NSNumber *)lower upper:(NSNumber *)upper {
    self = [super init];
    if (self) {
        _lower = lower;
        _upper = upper;
    }
    return self;
}

- (NSTimeInterval)genTime:(NSError * _Nullable __autoreleasing *)error {
    NSTimeInterval result = 0;
    
    double milliseconds = 1000;
    double lowerBound = [_lower doubleValue] * milliseconds;
    double upperBound = [_upper doubleValue] * milliseconds;
    // random number generation is using a uint32
    // TODO: Clean up for supporting larger types
    // TODO: Handle errors
    uint32_t dt = (uint32_t)lround(upperBound - lowerBound);
    uint32_t rndValue = arc4random_uniform(dt) + lowerBound;
    result = (NSTimeInterval)(rndValue/milliseconds);
    
    return result;
}

- (BOOL)hasNext {
    return YES;
}

@end
