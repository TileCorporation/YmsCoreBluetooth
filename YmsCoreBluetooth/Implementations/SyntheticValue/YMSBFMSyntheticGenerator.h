//
//  YMSBFMSyntheticGenerator.h
//  Deanna
//
//  Created by Paul Wong on 1/27/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSUInteger, YMSBFMSyntheticGeneratorType) {
    YMSBFMSyntheticGenerator_CONSTANT,
    YMSBFMSyntheticGenerator_LOOP,
    YMSBFMSyntheticGenerator_RANDOM,
//    YMSBFMSyntheticGenerator_FILE
};

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticGenerator : NSObject

@property (nonatomic, readonly) YMSBFMSyntheticGeneratorType type;

- (NSInteger)genValue;

@end

NS_ASSUME_NONNULL_END
