//
//  YMSBFMStimulusGenerator.h
//  Deanna
//
//  Created by Paul Wong on 1/26/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
@protocol YMSCBCentralManagerInterface;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMStimulusGenerator : NSObject

- (instancetype)initWithCentral:(id<YMSCBCentralManagerInterface>)central;

@end

NS_ASSUME_NONNULL_END
