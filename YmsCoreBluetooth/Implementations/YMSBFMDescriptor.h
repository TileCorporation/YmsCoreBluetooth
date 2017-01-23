//
//  YMSBFMDescriptor.h
//  Deanna
//
//  Created by Paul Wong on 1/19/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
#import "YMSCBDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMDescriptor : NSObject<YMSCBDescriptorInterface>
@property(readonly, nonatomic) CBUUID *UUID;
@property(assign, readonly, nonatomic) id<YMSCBCharacteristicInterface> characteristicInterface;
@property(retain, readonly) id value;

@end


NS_ASSUME_NONNULL_END
