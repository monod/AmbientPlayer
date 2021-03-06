//
//  APCrossFadePlayer.h
//  AmbientPlayer
//
//  Created by KAWACHI Takashi on 9/8/12.
//  Copyright (c) 2012 InteractionPlus. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "APSoundEntry.h"

@interface APCrossFadePlayer : NSObject
- (BOOL)play;
- (BOOL)play:(APSoundEntry *) soundEntry rootDirectory:(NSString *) rootDirectory;
- (void)stop;
- (void)stopEntry;
- (BOOL)isPlaying;
- (void)setVolume:(float)vol;
- (void)setCurrentSoundName:(NSString *)currentSoundName;
- (BOOL)isPlaying:(APSoundEntry *) soundEntry;
- (float)powerForChannel:(NSUInteger)ch;

@property (nonatomic, copy) NSString *currentSoundFileName;

@end
