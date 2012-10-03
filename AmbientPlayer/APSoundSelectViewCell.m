//
//  APSoundSelectViewCell.m
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/09/18.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import "APSoundSelectViewCell.h"

@implementation APSoundSelectViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        // Image
        self.preview = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        self.backgroundView = self.preview;
        
        // Cover
        _cover = [[APGradientBackgroundView alloc]initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        [self.contentView addSubview:_cover];
        
        // Level
        _levelMeter = [[APLevelMeterView alloc] initWithFrame:CGRectMake(0.0, frame.size.height * 3 / 8, frame.size.width, frame.size.height / 4.0)];
        _levelMeter.nLights = 10;
        _levelMeter.bgColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.1];
        _levelMeter.fgColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4];
        _levelMeter.hidden = YES;
        [self.contentView addSubview:_levelMeter];
        
        // Title
        self.title = [[UILabel alloc]initWithFrame:CGRectMake(10.0, frame.size.height - 40.0, frame.size.width - 20.0, 40.0)];
        self.title.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:32.0];
        self.title.backgroundColor = [UIColor clearColor];
        self.title.textColor = [UIColor whiteColor];
        self.title.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.title];
        
    }
    return self;
}

- (void)setPlaying:(BOOL)playing {
    _playing = playing;
    // Configure the view for the selected state
    _cover.selected = playing;
    _levelMeter.hidden = !playing;
    [_cover setNeedsDisplay];
}

- (BOOL)isPlaying {
    return _playing;
}

- (void)updateLevelMeterForChannels:(float)ch0 and:(float)ch1 {
    if (self.playing) {
        [_levelMeter updateValuesWith:ch0 and:ch1];
    }
}

@end
