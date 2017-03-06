//
//  YMSBFMSyntheticGeneratorRandom.m
//  Deanna
//
//  Created by Paul Wong on 1/30/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticGeneratorRandom.h"
#import "YMSBFMSyntheticValueUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticGeneratorRandom () {
    YMSBFMSyntheticGeneratorType _type;
}

@property (nonatomic, strong, nullable) NSNumber *lower;
@property (nonatomic, strong, nullable) NSNumber *upper;

@end

@implementation YMSBFMSyntheticGeneratorRandom

- (nullable instancetype)initWithLower:(NSNumber *)lower upper:(NSNumber *)upper {
    self = [super init];
    if (self) {
        _lower = lower;
        _upper = upper;
        _type = YMSBFMSyntheticGenerator_RANDOM;
    }
    return self;
}

- (nullable NSNumber *)genValue:(NSError * _Nullable __autoreleasing *)error {
    if (!_lower || !_upper) {
        if (error != NULL) {
            *error = [YMSBFMSyntheticValueUtils errorForErrorType:YMSBFMSyntheticValueErrorInvalidRange];
        }
    }
    
    NSNumber *result = nil;
    
    NSInteger lowerBound = [_lower integerValue];
    NSInteger upperBound = [_upper integerValue];
    NSInteger rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
    result = @(rndValue);
    
    return result;
}

- (BOOL)hasNext {
    return YES;
}

@end

NS_ASSUME_NONNULL_END
