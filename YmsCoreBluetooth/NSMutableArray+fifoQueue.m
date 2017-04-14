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


#import "NSMutableArray+fifoQueue.h"

@implementation NSMutableArray (fifoQueue)

#pragma mark - Properties

@dynamic queue;

- (dispatch_queue_t)queue {
    
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("NSMutableArray fifo queue", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

#pragma mark - Methods

- (void)push:(id)anObject {
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_sync(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf addObject:anObject];
    });
}

- (id)pop {
    
    __block id result = nil;
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_sync(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf count] > 0) {
            result = [strongSelf objectAtIndex:0];
            [strongSelf removeObjectAtIndex:0];
        }
    });
    
    return result;
}

- (BOOL)threadSafeContainsObject:(id)anObject {
    
    __block BOOL result = NO;
    
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        result = [strongSelf containsObject:anObject];
    });
    
    return result;
}

- (void)threadSafeRemoveObjectsInArray:(NSArray *)array {
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf removeObjectsInArray:array];
    });
}

@end
