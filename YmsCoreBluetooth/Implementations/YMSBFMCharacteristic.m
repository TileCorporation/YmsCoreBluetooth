//
//  YMSBFMCharacteristic.m
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMCharacteristic.h"
#import "TISensorTag.h"
#import "YMSCBService.h"
#import "YMSCBPeripheral.h"
#import "YMSCBUtils.h"
#import "YMSBFMStimulusGenerator.h"
#import "YMSBFMModelConfiguration.h"
#import "YMSCBService.h"
#import "YMSCBPeripheral.h"
#import "YMSBFMSyntheticValue.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMCharacteristic ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBDescriptorInterface>> *descriptorsByUUID;
@property (nonatomic, strong) YMSBFMStimulusGenerator *stimulusGenerator;
@end

@implementation YMSBFMCharacteristic

- (nullable instancetype)initWithCBUUID:(CBUUID *)uuid serviceInterface:(id<YMSCBServiceInterface>)serviceInterface stimulusGenerator:(YMSBFMStimulusGenerator *)stimulusGenerator {
    self = [super init];
    if (self) {
        _UUID = uuid;
        _service = serviceInterface;
        _stimulusGenerator = stimulusGenerator;
        _descriptorsByUUID = [NSMutableDictionary new];
        
        NSDictionary<NSString *, NSDictionary<NSString *, id> *> *servicesJSON = [_stimulusGenerator.modelConfiguration servicesForPeripheralIdentifier:_service.peripheralInterface.identifier.UUIDString];
        NSDictionary<NSString *, NSDictionary<NSString *, id> *> *characteristicJSON = [_stimulusGenerator.modelConfiguration characteristicForService:servicesJSON[_service.UUID.UUIDString] withCharacteristicUUID:_UUID.UUIDString];
        _syntheticValue = [[YMSBFMSyntheticValue alloc] initWithJSON:characteristicJSON];
    }
    return self;
}

- (void)setIsNotifying:(BOOL)isNotifying {
    _isNotifying = isNotifying;
}

- (void)writeValue:(NSData *)value {
    // TODO: Support/Reconcile with BFMPeripheral on who talks to the stimulus generator
    _value = value;
}

@end

NS_ASSUME_NONNULL_END
