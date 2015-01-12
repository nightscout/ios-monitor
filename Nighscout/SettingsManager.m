//
//  SettingsManager.m
//  Nightscout
//
//  Created by Rick Friele on 1/3/15.
//  Copyright (c) 2015 Nightscout Foundation. All rights reserved.
//

#import "SettingsManager.h"
#import <UIKit/UIKit.h>

@implementation SettingsManager

NSString* const kSettingsKeyScreenLock = @"screenLock";
NSString* const kSettingsKeyLastURL = @"lastUrl";

+ (instancetype)sharedManager {
    static SettingsManager *sharedSettingsManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSettingsManager = [[self alloc] init];
    });
    return sharedSettingsManager;
}

- (id)init {
    if (self = [super init]) {
        [self registerDefaults];
    }
    return self;
}

- (void)registerDefaults {
    // this function writes default settings as settings
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if (!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
            NSLog(@"writing as default %@ to the key %@",[prefSpecification objectForKey:@"DefaultValue"],key);
        }
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

- (BOOL)isScreenLock {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsKeyScreenLock];
}

- (void)setScreenLock:(BOOL)on {
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:kSettingsKeyScreenLock];
    [UIApplication sharedApplication].idleTimerDisabled = on;
}

- (NSString *)getLastURL {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kSettingsKeyLastURL];
}

- (void)setLastURL:(NSString *)lastURL {
    [[NSUserDefaults standardUserDefaults] setObject:lastURL forKey:kSettingsKeyLastURL];
}

@end
