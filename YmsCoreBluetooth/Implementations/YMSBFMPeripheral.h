//
//  YMSBFMPeripheral.h
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
#import "YMSCBPeripheral.h"
@protocol YMSCBCentralManagerInterfaceDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMPeripheral : NSObject<YMSCBPeripheralInterface>

@property(assign, nonatomic, nullable) id<YMSCBPeripheralInterfaceDelegate> delegate;

@property(retain, readonly, nullable) NSString *name;

@property(readonly, nonatomic) NSUUID *identifier;

@property(readonly) CBPeripheralState state;

#if TARGET_OS_IPHONE
#else
@property(readonly) NSNumber *RSSI;
#endif

@property(retain, readonly, nullable) NSArray<id<YMSCBServiceInterface>> *services;

@property(nonatomic, weak, nullable) id<YMSCBCentralManagerInterface> central;

- (nullable instancetype)initWithCentral:(id<YMSCBCentralManagerInterface>)central;

@end

NS_ASSUME_NONNULL_END
