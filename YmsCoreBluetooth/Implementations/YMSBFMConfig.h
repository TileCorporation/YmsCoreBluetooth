//
//  YMSBFMConfig.h
//  Deanna
//
//  Created by Paul Wong on 1/23/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMConfig : NSObject
@property (nonatomic, strong, readonly, nullable) NSString *peripheralName;
@property (nonatomic, strong, readonly, nullable) NSString *peripheralUUID;
@property (nonatomic, strong, readonly, nullable) NSArray<NSDictionary<NSString *, id> *> *services;
@property (nonatomic, strong, readonly, nullable) NSArray<NSDictionary<NSString *, id> *> *firstServiceCharacteristics;

- (nullable instancetype)initWithJsonFile:(NSString *)jsonFile;
@end

NS_ASSUME_NONNULL_END
