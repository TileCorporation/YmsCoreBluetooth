//
//  YMSCBNativeCharacteristic.m
//  Deanna
//
//  Created by Charles Choi on 1/11/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import CoreBluetooth;

#import "YMSCBNativeCharacteristic.h"
#import "YMSCBNativeDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSCBNativeCharacteristic ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, YMSCBNativeDescriptor *> *nativeDescriptors;
@end

@implementation YMSCBNativeCharacteristic

- (nullable instancetype)initWithService:(id<YMSCBServiceInterface>)serviceInterface characteristic:(CBCharacteristic *)characteristic {
    self = [super init];
    if (self) {
        _cbCharacteristic = characteristic;
        _service = serviceInterface;
        _nativeDescriptors = [NSMutableDictionary new];
    }
    return self;
}


- (CBUUID *)UUID {
    CBUUID *result = nil;
    result = _cbCharacteristic.UUID;
    return result;
}

- (CBCharacteristicProperties)properties {
    CBCharacteristicProperties result;
    result = _cbCharacteristic.properties;
    return result;
}

- (nullable NSData *)value {
    NSData *result = nil;
    result = _cbCharacteristic.value;
    return result;
}


- (nullable NSArray<id<YMSCBDescriptorInterface>> *)descriptors {
    NSArray<id<YMSCBDescriptorInterface>> *result = nil;
    
    for (CBDescriptor *descriptor in _cbCharacteristic.descriptors) {
        NSString *key = descriptor.UUID.UUIDString;
        
        if (_nativeDescriptors[key]) {
            YMSCBNativeDescriptor *descriptorInterface = [[YMSCBNativeDescriptor alloc] initWithParent:self descriptor:descriptor];
            _nativeDescriptors[key] = descriptorInterface;
        }
    }
    
    result = [_nativeDescriptors allValues];
    
    return result;
}


/*
- (BOOL)isBroadcasted {
    BOOL result = NO;
    result = [_cbCharacteristic isBroadcasted];
    return result;
}
 */


- (BOOL)isNotifying {
    BOOL result = NO;
    result = _cbCharacteristic.isNotifying;
    return result;
}

- (nullable id<YMSCBDescriptorInterface>)interfaceForDescriptor:(CBDescriptor *)descriptor {
    id<YMSCBDescriptorInterface> result = nil;
    result = _nativeDescriptors[descriptor.UUID.UUIDString];
    return result;
}


@end

NS_ASSUME_NONNULL_END
