//
//  YMSCBNativeCentralManager.h
//  Deanna
//
//  Created by Charles Choi on 1/10/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//


@import Foundation;
#import "YMSCBCentralManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSCBNativeCentralManager : NSObject <YMSCBCentralManagerInterface, CBCentralManagerDelegate>

@property(assign, nonatomic, nullable) id<YMSCBCentralManagerInterfaceDelegate, NSObject> delegate;
@property(readonly) CBCentralManagerState state;

@end

NS_ASSUME_NONNULL_END
