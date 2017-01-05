//
// Copyright 2013-2015 Yummy Melon Software LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Author: Charles Y. Choi <charles.choi@yummymelon.com>
//

@import Foundation;
@import CoreBluetooth;
#import "YMSCBUtils.h"

NS_ASSUME_NONNULL_BEGIN

@class YMSCBCharacteristic;

@protocol YMSCBDescriptorInterface
@property(readonly, nonatomic) CBUUID *UUID;
@property(assign, readonly, nonatomic) YMSCBCharacteristic *characteristic;
@property(retain, readonly) id value;
@end


@class YMSCBPeripheral;

/**
 Base class for defining a Bluetooth LE descriptor.
 
 YMSCBDescriptor holds an instance of CBDescriptor (cbDescriptor).
 
 The implementation of this class is TBD.
 */
@interface YMSCBDescriptor : NSObject

/// Pointer to actual CBDescriptor
@property (atomic, strong) CBDescriptor *cbDescriptor;

/// Descriptor UUID
@property (atomic, readonly) CBUUID *UUID;

@property(retain, readonly) id value;


NS_ASSUME_NONNULL_END

@end
