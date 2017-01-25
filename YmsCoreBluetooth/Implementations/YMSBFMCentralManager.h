//
//  YMSBFMCentralManager.h
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
#import "YMSCBCentralManager.h"
@class YMSBFMConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMCentralManager : NSObject<YMSCBCentralManagerInterface>

@property(assign, nonatomic, nullable) id<YMSCBCentralManagerInterfaceDelegate> delegate;

@property(readonly) CBCentralManagerState state;

@end

NS_ASSUME_NONNULL_END
