//
//  APCrossFadePlayer.m
//  AmbientPlayer
//
//  Created by KAWACHI Takashi on 9/8/12.
//  Copyright (c) 2012 InteractionPlus. All rights reserved.
//

#import "APCrossFadePlayer.h"

#define SYNTHESIZE(propertyName) @synthesize propertyName = _ ## propertyName

static const NSTimeInterval kCrossFadeDuration = 2.0;
static const NSTimeInterval kCrossFadeStep = 0.1;

@interface APCrossFadePlayer ()
@property (nonatomic, strong) AVAudioPlayer *player1;
@property (nonatomic, strong) AVAudioPlayer *player2;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, copy) NSString *currentSoundName;
@property float targetVolume;
@property (nonatomic, strong) APSoundEntry * soundEntry;
@end

@implementation APCrossFadePlayer
SYNTHESIZE(player1);
SYNTHESIZE(player2);
SYNTHESIZE(duration);
SYNTHESIZE(currentSoundName);
SYNTHESIZE(targetVolume);
SYNTHESIZE(soundEntry);

- (id)init {
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

- (BOOL)play:(APSoundEntry *) soundEntry rootDirectory:(NSString *)rootDirectory {
    if (rootDirectory) {
        [self setCurrentSoundFileName:[rootDirectory stringByAppendingPathComponent:soundEntry.fileName]];
    } else {
        [self setCurrentSoundName:soundEntry.fileName];
    }
        
    self.soundEntry = soundEntry;
    
    return [self play];
}

- (void)stop {
    [self.player1 stop];
    [self.player2 stop];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)stopEntry{
    if(self.soundEntry) {
        self.soundEntry = nil;
    }
    
    [self stop];
}

- (BOOL)isPlaying {
    return (self.player1 && self.player1.isPlaying) || (self.player2 && self.player2.isPlaying);
}

- (BOOL)isPlaying:(APSoundEntry*) soundEntry {
    return [self isPlaying] && self.soundEntry == soundEntry;
}

- (float)powerForChannel:(NSUInteger)ch {
    float ret = 0.0;
    if (self.player1 && self.player1.isPlaying) {
        [self.player1 updateMeters];
        ret = [self.player1 averagePowerForChannel:ch];
    }
    return ret;
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
        self.player2.volume = MIN(self.player2.volume + 0.2, self.targetVolume);
        NSLog(@"[Volume] #1:%4.2f #2:%4.2f", self.player1.volume, self.player2.volume);
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
    player.meteringEnabled = YES;
    return player;
}

@end
