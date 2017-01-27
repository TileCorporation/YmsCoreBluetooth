//
//  YMSBFMService.h
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
#import "YMSCBService.h"
@class YMSBFMConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMService : NSObject<YMSCBServiceInterface>

@property(assign, readonly, nonatomic, nonnull) id<YMSCBPeripheralInterface> peripheralInterface;
@property(readonly, nonatomic) CBUUID *UUID;
@property(readonly, nonatomic) BOOL isPrimary;
@property(retain, readonly, nullable) NSArray<id<YMSCBServiceInterface>> *includedServices;
@property(retain, readonly, nullable) NSArray<id<YMSCBCharacteristicInterface>> *characteristics;

- (nullable instancetype)initWithCBUUID:(CBUUID *)uuid peripheralInterface:(id<YMSCBPeripheralInterface>)peripheralInterface;
- (void)addCharacteristicsWithUUIDs:(nullable NSArray<CBUUID *> *)uuids;

@end

NS_ASSUME_NONNULL_END
