//
//  YMSCBNativeDescriptor.h
//  Deanna
//
//  Created by Charles Choi on 1/11/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
#import "YMSCBDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSCBNativeDescriptor : NSObject<YMSCBDescriptorInterface>

@property (nonatomic, strong) CBDescriptor *cbDescriptor;

@property(readonly, nonatomic) CBUUID *UUID;
@property(assign, readonly, nonatomic) id<YMSCBCharacteristicInterface> characteristicInterface;
@property(retain, readonly) id value;

- (nullable instancetype)initWithParent:(id<YMSCBCharacteristicInterface>)characteristicInterface descriptor:(CBDescriptor *)descriptor;

@end

NS_ASSUME_NONNULL_END
