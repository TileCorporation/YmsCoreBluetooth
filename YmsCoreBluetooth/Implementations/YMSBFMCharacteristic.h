//
//  YMSBFMCharacteristic.h
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
#import "YMSCBCharacteristic.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMCharacteristic : NSObject<YMSCBCharacteristicInterface>

@property(assign, readonly, nonatomic) id<YMSCBServiceInterface>service;
@property(readonly, nonatomic) CBUUID *UUID;

@property(readonly, nonatomic) CBCharacteristicProperties properties;
@property(retain, readonly, nullable) NSData *value;
@property(retain, readonly, nullable) NSArray<id<YMSCBDescriptorInterface>> *descriptors;
@property(readonly) BOOL isBroadcasted;
@property(readonly) BOOL isNotifying;

- (nullable instancetype)initWithCBUUID:(CBUUID *)uuid serviceInterface:(id<YMSCBServiceInterface>)serviceInterface;
- (void)setIsNotifying:(BOOL)isNotifying;

@end

NS_ASSUME_NONNULL_END
