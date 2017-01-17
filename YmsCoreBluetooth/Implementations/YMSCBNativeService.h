//
//  YMSCBNativeService.h
//  Deanna
//
//  Created by Charles Choi on 1/11/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
#import "YMSCBService.h"

NS_ASSUME_NONNULL_BEGIN

@class CBService;
@protocol YMSCBPeripheralInterface;

@interface YMSCBNativeService : NSObject<YMSCBServiceInterface>

@property (nonatomic, strong) CBService *cbService;

@property(assign, readonly, nonatomic, nonnull) id<YMSCBPeripheralInterface> peripheralInterface;
@property(readonly, nonatomic) CBUUID *UUID;
@property(readonly, nonatomic) BOOL isPrimary;
@property(retain, readonly, nullable) NSArray<id<YMSCBServiceInterface>> *includedServices;
@property(retain, readonly, nullable) NSArray<id<YMSCBCharacteristicInterface>> *characteristics;

@property (nonatomic, weak, nullable) YMSCBService *owner;


- (nullable instancetype)initWithPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface service:(CBService *)service;

- (nullable id<YMSCBCharacteristicInterface>)interfaceForCharacteristic:(CBCharacteristic *)characteristic;



@end

NS_ASSUME_NONNULL_END
