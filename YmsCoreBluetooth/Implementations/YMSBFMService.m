//
//  YMSBFMService.m
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMService.h"
#import "YMSCBCharacteristic.h"
#import "YMSBFMCharacteristic.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMService ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBCharacteristicInterface>> *characteristicsByUUID;
@end

@implementation YMSBFMService

- (nullable instancetype)initWithCBUUID:(CBUUID *)uuid peripheralInterface:(id<YMSCBPeripheralInterface>)peripheralInterface {
    self = [super init];
    if (self) {
        _UUID = uuid;
        _peripheralInterface = peripheralInterface;
        _characteristicsByUUID = [NSMutableDictionary new];
    }
    return self;
}

- (void)addCharacteristicsWithUUIDs:(nullable NSArray<CBUUID *> *)uuids {
    // TODO: Handle nil uuids
    for (CBUUID *uuid in uuids) {
        _characteristicsByUUID[uuid.UUIDString] = [[YMSBFMCharacteristic alloc] initWithCBUUID:uuid serviceInterface:self];
    }
}

@end

NS_ASSUME_NONNULL_END
