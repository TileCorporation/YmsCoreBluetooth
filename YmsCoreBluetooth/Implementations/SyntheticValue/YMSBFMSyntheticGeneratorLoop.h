//
//  YMSBFMSyntheticGeneratorLoop.h
//  Deanna
//
//  Created by Paul Wong on 1/30/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMSyntheticGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMSyntheticGeneratorLoop : YMSBFMSyntheticGenerator

- (nullable instancetype)initWithRange:(NSArray<NSNumber *> *)range step:(NSNumber *)step repeat:(BOOL)repeat;

@end

NS_ASSUME_NONNULL_END
