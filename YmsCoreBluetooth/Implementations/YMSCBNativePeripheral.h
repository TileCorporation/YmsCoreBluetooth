//
//  YMSCBNativePeripheral.h
//  Deanna
//
//  Created by Charles Choi on 1/11/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
#import "YMSCBPeripheral.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSCBNativePeripheral : NSObject<YMSCBPeripheralInterface, CBPeripheralDelegate>

// TODO: needs a pointer to central!

@property(assign, nonatomic, nullable) id<YMSCBPeripheralInterfaceDelegate> delegate;

@property(retain, readonly, nullable) NSString *name;

@property(readonly, nonatomic) NSUUID *identifier;

@property(retain, readonly, nullable) NSNumber *RSSI;

@property(readonly) CBPeripheralState state;

@property(retain, readonly, nullable) NSArray<id<YMSCBServiceInterface>> *services;

@property (nonatomic, strong) CBPeripheral *cbPeripheral;

#pragma mark - Hey

- (nullable instancetype)initWithPeripheral:(CBPeripheral *)peripheral;



@end

NS_ASSUME_NONNULL_END
