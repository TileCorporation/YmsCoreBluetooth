//
//  YMSBFMCharacteristic.m
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMCharacteristic.h"

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

@end

NS_ASSUME_NONNULL_END
