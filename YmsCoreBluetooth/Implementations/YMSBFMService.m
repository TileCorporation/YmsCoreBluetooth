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
#import "YMSBFMConfig.h"

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

- (void)addCharacteristicsWithUUIDs:(nullable NSArray<CBUUID *> *)uuids config:(YMSBFMConfig *)config {
    if (!uuids) {
        // TODO: Handle nil uuids
    } else {
        for (CBUUID *uuid in uuids) {
            NSString *serviceClass = NSStringFromClass([self class]);
            NSArray<NSDictionary<NSString *, id> *> *characteristics = config.firstServiceCharacteristics;
            
            /*NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", serviceClass];
            NSArray *result = [characteristics filteredArrayUsingPredicate:predicate];
            
            if (result.count == 1) {*/
                Class YMSBFMCharacteristic = NSClassFromString(characteristics.firstObject[@"name"]);
                if (YMSBFMCharacteristic) {
                    id characteristic = [[YMSBFMCharacteristic alloc] initWithCBUUID:uuid serviceInterface:self];
                   _characteristicsByUUID[characteristics.firstObject[@"uuid"]] = characteristic;
                }
            //}
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
