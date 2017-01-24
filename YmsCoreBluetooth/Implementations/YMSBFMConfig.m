//
//  YMSBFMConfig.m
//  Deanna
//
//  Created by Paul Wong on 1/23/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMConfig ()
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *peripheral;
@end

@implementation YMSBFMConfig

- (nullable instancetype)initWithJsonFile:(NSString *)jsonFile {
    self = [super init];
    if (self) {
        NSURL *jsonURL = [[NSBundle mainBundle] URLForResource:jsonFile withExtension:@"json"];
        NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL];
        NSError *jsonError = nil;
        NSDictionary<NSString *, NSDictionary *> *json = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&jsonError];
        _peripheral = json[@"peripheral"];
    }
    return self;
}

- (nullable NSString *)peripheralName {
    return _peripheral[@"name"];
}

- (nullable NSString *)peripheralUUID {
    return _peripheral[@"uuid"];
}

- (nullable NSArray<NSDictionary<NSString *, id> *> *)services {
    return _peripheral[@"services"];
}

- (nullable NSDictionary *)firstServiceCharacteristics {
    return self.services[0][@"characteristics"];
    //return ((NSDictionary *)self.services[0])[characteristics
}

@end

NS_ASSUME_NONNULL_END
