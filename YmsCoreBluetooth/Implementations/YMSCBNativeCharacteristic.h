//
//  YMSCBNativeCharacteristic.h
//  Deanna
//
//  Created by Charles Choi on 1/11/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
#import "YMSCBCharacteristic.h"

NS_ASSUME_NONNULL_BEGIN

@class CBCharacteristic;
@protocol YMSCBServiceInterface;

@interface YMSCBNativeCharacteristic : NSObject<YMSCBCharacteristicInterface>

@property (nonatomic, strong) CBCharacteristic *cbCharacteristic;

@property(assign, readonly, nonatomic) id<YMSCBServiceInterface>service;
@property(readonly, nonatomic) CBUUID *UUID;

@property(readonly, nonatomic) CBCharacteristicProperties properties;
@property(retain, readonly, nullable) NSData *value;
@property(retain, readonly, nullable) NSArray<id<YMSCBDescriptorInterface>> *descriptors;
@property(readonly) BOOL isBroadcasted;
@property(readonly) BOOL isNotifying;

- (nullable instancetype)initWithService:(id<YMSCBServiceInterface>)serviceInterface characteristic:(CBCharacteristic *)characteristic;

- (nullable id<YMSCBDescriptorInterface>)interfaceForDescriptor:(CBDescriptor *)descriptor;

@end

NS_ASSUME_NONNULL_END
