//
//  APCrossFadePlayer.m
//  AmbientPlayer
//
//  Created by KAWACHI Takashi on 9/8/12.
//  Copyright (c) 2012 InteractionPlus. All rights reserved.
//

#import "APCrossFadePlayer.h"

#define SYNTHESIZE(propertyName) @synthesize propertyName = _ ## propertyName

static const NSTimeInterval kCrossFadeDuration = 1.0;
static const NSTimeInterval kCrossFadeStep = 0.1;

@interface APCrossFadePlayer ()
@property (nonatomic, strong) AVAudioPlayer *player1;
@property (nonatomic, strong) AVAudioPlayer *player2;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, copy) NSString *currentSoundName;
@property float targetVolume;
@end

@implementation APCrossFadePlayer
SYNTHESIZE(player1);
SYNTHESIZE(player2);
SYNTHESIZE(duration);
SYNTHESIZE(currentSoundName);
SYNTHESIZE(targetVolume);

- (id)init
{
    self = [super init];
    if (self) {
        self.targetVolume = 1.0f;
    }
    return self;
}

-(void)setCurrentSoundName:(NSString *)currentSoundName {
    self.currentSoundFileName = [[NSBundle mainBundle] pathForResource:currentSoundName ofType:@"m4a"];
}

- (BOOL)play {
    if ([self isPlaying]) {
        [self stop];
    }
    self.player1 = [self newPlayer];
    [self.player1 setVolume:self.targetVolume];

    self.player2 = [self newPlayer];
    
    self.duration = self.player1.duration;
    NSAssert(self.duration > kCrossFadeDuration, @"Sound duration %f should > %f", self.duration, kCrossFadeDuration);
    
    BOOL playSucc = [self.player1 play];
    if (playSucc) {
        [self performSelector:@selector(startCrossFade) withObject:nil afterDelay:self.duration - kCrossFadeDuration];
    }
    return playSucc;
}

- (void)stop {
    [self.player1 stop];
    [self.player2 stop];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (BOOL)isPlaying {
    return (self.player1 && self.player1.isPlaying) || (self.player2 && self.player2.isPlaying);
}

- (void)startCrossFade {
    [self.player2 setVolume:0.0];
    [self.player2 play];
    [self performSelector:@selector(stepCrossFade) withObject:nil afterDelay:kCrossFadeStep];
}

- (void)stepCrossFade {
    if (self.player1.volume - 0.1 < 0.0) {
        [self.player1 stop];
        self.player1 = self.player2;
        self.player1.volume = self.targetVolume;
        self.player2 = [self newPlayer];
        [self performSelector:@selector(startCrossFade) withObject:nil afterDelay:self.duration - self.player1.currentTime - kCrossFadeDuration];
    } else {
        self.player1.volume -= 0.1;
        self.player2.volume += 0.1;
        [self performSelector:@selector(stepCrossFade) withObject:nil afterDelay:kCrossFadeStep];
    }
}

- (void)setVolume:(float)vol {
    self.targetVolume = vol;
    self.player1.volume = vol;
    self.player2.volume = vol;
}

-(AVAudioPlayer *)newPlayer {
    NSError* error = nil;
    NSURL* url = [[NSURL alloc] initFileURLWithPath:self.currentSoundFileName];
    
    AVAudioPlayer *player =[[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (error) {
        NSLog(@"%@", error);
        return nil;
    }
    [player prepareToPlay];
    return player;
}

@end
