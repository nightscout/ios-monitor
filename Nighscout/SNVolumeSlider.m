//
//  SNVolumeSlider.m
//
//  Created by Noda Shimpei on 2013/05/14.
//  Copyright (c) 2013年 Noda Shimpei. All rights reserved.
//

#import "SNVolumeSlider.h"

#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

@implementation SNVolumeSlider

void onPushVolumeButton(void *inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void *inData) {
    const float *volumePointer = inData;
    float volume = *volumePointer;
    
    SNVolumeSlider *voluemSlider = (__bridge SNVolumeSlider *)inClientData;
    [voluemSlider setValue:volume];
}

- (instancetype)awakeAfterUsingCoder:(NSCoder *)aDecoder{
    [self setup];
    return [super awakeAfterUsingCoder:aDecoder];
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup{
    [self syncVolume];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syncVolume)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(unsyncVolume)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)syncVolume {
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    AudioSessionSetActive(YES);

    [self setValue:[[MPMusicPlayerController applicationMusicPlayer] volume]];
    [self addTarget:self action:@selector(movedVolumeSlider:) forControlEvents:UIControlEventValueChanged];
    AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume, onPushVolumeButton, (__bridge void *)(self));
}

- (void)unsyncVolume {
    [self removeTarget:self action:@selector(movedVolumeSlider:) forControlEvents:UIControlEventValueChanged];
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, onPushVolumeButton, (__bridge void *)(self));
}

- (void)movedVolumeSlider:(UISlider *)slider {
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:[self value]];
}

- (void)dealloc {
    [self unsyncVolume];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
