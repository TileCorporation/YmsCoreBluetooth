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
#import "YMSBFMPeripheralConfiguration.h"
#import "YMSCBPeripheral.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMService ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBCharacteristicInterface>> *characteristicsByUUID;
@property (nonatomic, strong, readonly) YMSBFMPeripheralConfiguration *modelConfiguration;
@end

@implementation YMSBFMService

- (nullable instancetype)initWithCBUUID:(CBUUID *)uuid peripheralInterface:(id<YMSCBPeripheralInterface>)peripheralInterface modelConfiguration:(YMSBFMPeripheralConfiguration *)modelConfiguration {
    self = [super init];
    if (self) {
        _UUID = uuid;
        _peripheralInterface = peripheralInterface;
        _characteristicsByUUID = [NSMutableDictionary new];
        _modelConfiguration = modelConfiguration;
    }
    return self;
}

- (void)addCharacteristicsWithUUIDs:(nullable NSArray<CBUUID *> *)uuids {
    if (!uuids) {
        // TODO: Handle nil uuids. Add all characteristics for this service.
    } else {
        for (CBUUID *uuid in uuids) {
            NSDictionary<NSString *, NSDictionary<NSString *, id> *> *characteristics = [_modelConfiguration characteristicsForServiceUUID:_UUID.UUIDString peripheral:NSStringFromClass([_peripheralInterface class])];
            
            // TODO: Make sure the uuid exists and if not create an error
            NSDictionary<NSString *, id> *characteristic = characteristics[uuid.UUIDString];
            Class YMSBFMCharacteristic = NSClassFromString(characteristic[@"class_name"]);
            if (YMSBFMCharacteristic) {
                id characteristic = [[YMSBFMCharacteristic alloc] initWithCBUUID:uuid serviceInterface:self];
                _characteristicsByUUID[uuid.UUIDString] = characteristic;
            }
        }
    }
}

- (nullable NSArray<id<YMSCBCharacteristicInterface>> *)characteristics {
    NSArray<id<YMSCBCharacteristicInterface>> *result = nil;
    result = _characteristicsByUUID.allValues;
    return result;
}

@end

NS_ASSUME_NONNULL_END
