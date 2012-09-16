//
//  APCrossFadePlayer.h
//  AmbientPlayer
//
//  Created by KAWACHI Takashi on 9/8/12.
//  Copyright (c) 2012 InteractionPlus. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface APCrossFadePlayer : NSObject
- (BOOL)play;
- (void)stop;
- (BOOL)isPlaying;
-(void)setCurrentSoundName:(NSString *)currentSoundName;

@property (nonatomic, copy) NSString *currentSoundFileName;
@end
