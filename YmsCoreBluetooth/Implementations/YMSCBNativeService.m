//
//  YMSCBNativeService.m
//  Deanna
//
//  Created by Charles Choi on 1/11/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import CoreBluetooth;

#import "YMSCBNativeService.h"
#import "YMSCBNativeCharacteristic.h"

@interface YMSCBNativeService ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, YMSCBNativeCharacteristic *> *nativeCharacteristics;

@end

@implementation YMSCBNativeService

- (instancetype)initWithPeripheral:(id<YMSCBPeripheralInterface>)peripheralInterface service:(CBService *)service {
    self = [super init];
    if (self) {
        _cbService = service;
        _peripheralInterface = peripheralInterface;
        _nativeCharacteristics = [NSMutableDictionary new];
    }
    return self;
}

- (CBUUID *)UUID {
    CBUUID *result = nil;
    result = _cbService.UUID;
    return result;
}


- (BOOL)isPrimary {
    BOOL result = NO;
    result = _cbService.isPrimary;
    return result;
}

- (NSArray<id<YMSCBServiceInterface>> *)includedServices {
    NSArray<id<YMSCBServiceInterface>> *result = nil;
    
    // TODO: Implement
    return result;
}


- (NSArray<id<YMSCBCharacteristicInterface>> *)characteristics {
    NSArray<id<YMSCBCharacteristicInterface>> *result = nil;
    
    
    for (CBCharacteristic *ct in _cbService.characteristics) {
        NSString *key = ct.UUID.UUIDString;
        
        if (!_nativeCharacteristics[key]) {
            YMSCBNativeCharacteristic *characteristicInterface = [[YMSCBNativeCharacteristic alloc] initWithService:self characteristic:ct];
            _nativeCharacteristics[key] = characteristicInterface;
        }
    }

    result = [_nativeCharacteristics allValues];
    return result;
}

- (nullable id<YMSCBCharacteristicInterface>)interfaceForCharacteristic:(CBCharacteristic *)characteristic {
    id<YMSCBCharacteristicInterface> result = nil;
    result = _nativeCharacteristics[characteristic.UUID.UUIDString];
    return result;
}

@end
