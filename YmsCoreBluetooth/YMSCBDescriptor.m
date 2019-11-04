//
// Copyright 2013-2014 Yummy Melon Software LLC
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

#import "YMSCBDescriptor.h"
#import "YMSCBCharacteristic.h"
#import "YMSCBPeripheral.h"
#import "NSMutableArray+fifoQueue.h"

NS_ASSUME_NONNULL_BEGIN

@implementation YMSCBDescriptor

- (CBUUID *)UUID {
    CBUUID *result = nil;
    if (self.cbDescriptor) {
        result = self.cbDescriptor.UUID;
    }

    return result;
}

- (void)writeValue:(NSData *)data withBlock:(nullable void (^)(NSError * _Nullable))writeCallback {
    [self.writeCallbacks push:[writeCallback copy]];
    [self.parent.cbPeripheral writeValue:data forDescriptor:self.cbDescriptor];
}


- (void)writeByte:(int8_t)val withBlock:(nullable void (^)(NSError * _Nullable))writeCallback {
    NSData *data = [NSData dataWithBytes:&val length:1];
    [self writeValue:data withBlock:writeCallback];
}


- (void)readValueWithBlock:(void (^)(NSData * _Nullable, NSError * _Nullable))readCallback {
    [self.readCallbacks push:[readCallback copy]];
    [self.parent.cbPeripheral readValueForDescriptor:self.cbDescriptor];
}

- (void)executeReadCallback:(NSData *)data error:(nullable NSError *)error {
    YMSCBReadCallbackBlockType readCB = [self.readCallbacks pop];
    readCB(data, error);
}

- (void)executeWriteCallback:(nullable NSError *)error {
    YMSCBWriteCallbackBlockType writeCB = [self.writeCallbacks pop];
    writeCB(error);
}

@end
NS_ASSUME_NONNULL_END
