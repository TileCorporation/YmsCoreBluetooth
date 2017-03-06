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
#import "YMSBFMStimulusGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMService ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBCharacteristicInterface>> *characteristicsByUUID;
@property (nonatomic, strong) YMSBFMStimulusGenerator *stimulusGenerator;
@end

@implementation YMSBFMService

- (nullable instancetype)initWithCBUUID:(CBUUID *)uuid peripheralInterface:(id<YMSCBPeripheralInterface>)peripheralInterface stimulusGenerator:(YMSBFMStimulusGenerator *)stimulusGenerator {
    self = [super init];
    if (self) {
        _UUID = uuid;
        _peripheralInterface = peripheralInterface;
        _stimulusGenerator = stimulusGenerator;
        _characteristicsByUUID = [NSMutableDictionary new];
    }
    return self;
}

- (nullable NSArray<id<YMSCBCharacteristicInterface>> *)characteristics {
    NSArray<id<YMSCBCharacteristicInterface>> *result = nil;
    result = _characteristicsByUUID.allValues;
    return result;
}

- (void)addCharacteristic:(id<YMSCBCharacteristicInterface>)characteristic {
    _characteristicsByUUID[characteristic.UUID.UUIDString] = characteristic;
}

@end

NS_ASSUME_NONNULL_END
