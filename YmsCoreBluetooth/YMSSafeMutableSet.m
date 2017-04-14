#import "YMSSafeMutableSet.h"

@interface YMSSafeMutableSet ()

@property (nonatomic, strong) NSMutableSet *set;
@property (nonatomic, strong, readonly) dispatch_queue_t queue;

@end

@implementation YMSSafeMutableSet

- (instancetype)init {
    
    self = [super init];
    if (self) {
        _set = [NSMutableSet new];
        _queue = dispatch_queue_create("YMSSafeMutableSet queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (NSUInteger)count {
    
    __block NSUInteger result = 0;
    
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        result = strongSelf.set.count;
    });
    
    return result;
}


- (id)member:(id)object {
    
    __block id result = nil;
    
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        result = [strongSelf.set member:object];
    });
    
    return result;
}

- (NSEnumerator *)objectEnumerator {
    
    __block NSEnumerator *result = nil;
    
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        result = [strongSelf.set objectEnumerator];
    });
    
    return result;
}

- (NSArray *)allObjects {
    
    __block NSArray *result = nil;
    
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        result = [strongSelf.set allObjects];
    });
    
    return result;
}

- (void)addObject:(id)object {
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.set addObject:object];
    });
}

- (void)removeObject:(id)object {
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.set removeObject:object];
    });
}

- (void)removeAllObjects {
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.set removeAllObjects];
    });
}

- (void)intersectSet:(YMSSafeMutableSet *)otherSet {
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.set intersectSet:otherSet];
    });
}

- (void)minusSet:(YMSSafeMutableSet *)otherSet {
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.set minusSet:otherSet];
    });
}

- (void)unionSet:(NSSet *)otherSet {
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(self.queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.set unionSet:otherSet];
    });
}

@end
