//
//  SettingsManager.h
//  Nightscout
//
//  Created by Rick Friele on 1/3/15.
//  Copyright (c) 2015 Nightscout Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)isScreenLock;
- (void)setScreenLock:(BOOL)on;
- (NSString *)getLastURL;
- (void)setLastURL:(NSString *)lastURL;

@end
