//
//  YMSBFMStimulusEvent.h
//  Deanna
//
//  Created by Paul Wong on 1/26/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSUInteger, YMSBFMStimulusEventType) {
    YMSBFMStimulusEvent_centralDidDiscoverPeripheral,
    YMSBFMStimulusEvent_centralDidConnect,
    YMSBFMStimulusEvent_centralDidDisconnect,
    YMSBFMStimulusEvent_centralDidFailToConnect,
    YMSBFMStimulusEvent_centralDidUpdateState,
    YMSBFMStimulusEvent_centralWillRestoreState,
    YMSBFMStimulusEvent_peripheralDidDiscoverServices,
    YMSBFMStimulusEvent_peripheralDidDiscoverCharacteristics,
    YMSBFMStimulusEvent_peripheralDidUpdateNotificationState,
    YMSBFMStimulusEvent_peripheralDidReadRSSI,
    YMSBFMStimulusEvent_peripheralDidWriteValue,
    YMSBFMStimulusEvent_peripheralDidUpdateValue
};

NS_ASSUME_NONNULL_BEGIN

@protocol YMSCBCentralManagerInterface;
@protocol YMSCBPeripheralInterface;
@protocol YMSCBServiceInterface;
@protocol YMSCBCharacteristicInterface;
@protocol YMSCBCentralManagerInterfaceDelegate;

@protocol YMSCBCentralManagerInterface<YMSCBCentralManagerInterfaceDelegate>

@end

@interface YMSBFMStimulusEvent : NSObject

@property (nonatomic, strong) NSDate *time;
@property (nonatomic, assign) YMSBFMStimulusEventType type;
@property (nonatomic, strong, nullable) id<YMSCBCentralManagerInterface> central;
@property (nonatomic, strong, nullable) id<YMSCBPeripheralInterface> peripheral;
@property (nonatomic, strong, nullable) id<YMSCBServiceInterface> service;
@property (nonatomic, strong, nullable) id<YMSCBCharacteristicInterface> characteristic;
@property (nonatomic, strong) NSNumber *RSSI;
@property (nonatomic, strong, nullable) NSError *error;

- (nullable instancetype)initWithTime:(NSDate *)time type:(YMSBFMStimulusEventType)type;

@end

NS_ASSUME_NONNULL_END
