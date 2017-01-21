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

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMCharacteristic ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<YMSCBDescriptorInterface>> *descriptorsByUUID;
@end

@implementation YMSBFMCharacteristic

- (nullable instancetype)initWithCBUUID:(CBUUID *)uuid serviceInterface:(id<YMSCBServiceInterface>)serviceInterface {
    self = [super init];
    if (self) {
        _UUID = uuid;
        _service = serviceInterface;
        _descriptorsByUUID = [NSMutableDictionary new];
    }
    return self;
}

- (void)setIsNotifying:(BOOL)isNotifying {
    _isNotifying = isNotifying;
    uint8_t uuidLength = _UUID.UUIDString.length;
    if (uuidLength == 4) {
        // 16 bit
        uint16_t uuidValue = [YMSCBUtils dataToUInt16:_UUID.data];
        
        if (uuidValue == kSensorTag_SIMPLEKEYS_DATA) {
            NSLog(@"Hey! Simple Keys Data");
            uint8_t sksValue = 0x2;
            _value = [NSData dataWithBytes:&sksValue length:sizeof(sksValue)];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    uint8_t sksValue = 0x1;
                    _value = [NSData dataWithBytes:&sksValue length:sizeof(sksValue)];
                    [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        uint8_t sksValue = 0x3;
                        _value = [NSData dataWithBytes:&sksValue length:sizeof(sksValue)];
                        [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            uint8_t sksValue = 0x0;
                            _value = [NSData dataWithBytes:&sksValue length:sizeof(sksValue)];
                            [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
                        });
                    });
                });
            });
        }
    } else {
        // 128 bit
        if ([_UUID.UUIDString isEqualToString:@"F000AA01-0451-4000-B000-000000000000"]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                uint8_t temperatureValues[4] = {0x51, 0xFF, 0x80, 0x0B};
                _value = [NSData dataWithBytes:temperatureValues length:sizeof(temperatureValues)];
                [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];

                __block uint8_t v0 = 0x51;
                __block uint8_t v1 = 0xFF;
                __block uint8_t v2 = 0x80;
                __block uint8_t v3 = 0x0B;
                for (int i = 0; i < 10; i++) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        uint8_t temperatureValues[4] = {v0, v1, v2, v3};
                        v0 += 1;
                        v2 += 1;
                        _value = [NSData dataWithBytes:temperatureValues length:sizeof(temperatureValues)];
                        [[[self.service peripheralInterface] delegate] peripheral:[self.service peripheralInterface] didUpdateValueForCharacteristic:self error:nil];
                    });
                }
            });
        }
    }
}

- (void)writeValue:(NSData *)value {
    if ([_UUID.UUIDString isEqualToString:@"F000AA02-0451-4000-B000-000000000000"]) {
        _value = value;
    }
}

@end

NS_ASSUME_NONNULL_END
