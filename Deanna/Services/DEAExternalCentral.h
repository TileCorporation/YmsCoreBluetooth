//
//  DEAExternalCentral.h
//  Deanna
//
//  Created by Charles Choi on 3/8/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;
#import "YMSCBCentralManager.h"

@interface DEAExternalCentral : NSObject<CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *central;
@property (nonatomic, weak) id<YMSCBCentralManagerInterfaceDelegate> delegate;

@end
