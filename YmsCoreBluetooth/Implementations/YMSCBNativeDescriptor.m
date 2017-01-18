//
//  YMSCBNativeDescriptor.m
//  Deanna
//
//  Created by Charles Choi on 1/11/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSCBNativeDescriptor.h"

@implementation YMSCBNativeDescriptor

- (nullable instancetype)initWithParent:(id<YMSCBCharacteristicInterface>)characteristicInterface descriptor:(CBDescriptor *)descriptor {
    self = [super init];
    if (self) {
        _characteristicInterface = characteristicInterface;
        _cbDescriptor = descriptor;
    }
    
    return self;
}


- (CBUUID *)UUID {
    CBUUID *result = nil;
    result = _cbDescriptor.UUID;
    return result;
}


- (id)value {
    id result = nil;
    result = _cbDescriptor.value;
    return result;
}


@end
