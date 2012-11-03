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
        self.playing = NO;
        _frontView = nil;
        
        // Image
        self.preview = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        self.backgroundColor = [UIColor darkGrayColor];
        //self.backgroundView = self.preview;
        [self.contentView addSubview:self.preview];
        
        // Cover
        _cover = [[APGradientBackgroundView alloc]initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        [self.contentView addSubview:_cover];
        
        // Level
        self.levelMeter = [[APLevelMeterView alloc] initWithFrame:CGRectMake(0.0, frame.size.height * 3 / 8, frame.size.width, frame.size.height / 4.0)];
        self.levelMeter.nLights = 20;
        self.levelMeter.bgColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.1];
        self.levelMeter.fgColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4];
        self.levelMeter.hidden = YES;
        [self.contentView addSubview:self.levelMeter];
        
        // Title
        self.title = [[UILabel alloc]initWithFrame:CGRectMake(10.0, frame.size.height - 40.0, frame.size.width - 20.0, 40.0)];
        self.title.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:32.0];
        self.title.backgroundColor = [UIColor clearColor];
        self.title.textColor = [UIColor whiteColor];
        self.title.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.title];
        
        // Info
        self.info = [UIButton buttonWithType:UIButtonTypeInfoLight];
        self.info.frame = CGRectMake(frame.size.width - 27.0, 9.0, 18.0, 18.0);
        self.info.hidden = YES;
        [self.contentView addSubview:self.info];
        
        // Back View
        self.backView = [[APSoundCellBackView alloc] initWithFrame:frame];
    }
    return self;
}

- (void)setPlaying:(BOOL)playing {
    _playing = playing;
    // Configure the view for the selected state
    _cover.selected = playing;
    self.levelMeter.hidden = !playing;
    self.info.hidden = !playing;
    [_cover setNeedsDisplay];
}

- (BOOL)isPlaying {
    return _playing;
}

- (void)flipViewToBackSide:(BOOL)backSide withAnimation:(BOOL)animation {
    UIViewAnimationOptions options = UIViewAnimationOptionTransitionNone;
    NSTimeInterval duration = 0;
    if (animation) {
        options = backSide ? UIViewAnimationOptionTransitionFlipFromRight : UIViewAnimationOptionTransitionFlipFromLeft;
        duration = 0.75;
    }
    
    if (backSide) {
        _frontView = self.contentView;
        //NSLog(@"[FRNT] frame(x,y)=(%f,%f), bounds(x,y)=(%f,%f)", _frontView.frame.origin.x, _frontView.frame.origin.y, _frontView.bounds.origin.x, _frontView.bounds.origin.y);
        //NSLog(@"[BACK] frame(x,y)=(%f,%f), bounds(x,y)=(%f,%f)", self.backView.frame.origin.x, self.backView.frame.origin.y, self.backView.bounds.origin.x, self.backView.bounds.origin.y);
        self.backView.frame = _frontView.frame;
        [UIView transitionFromView:_frontView
                            toView:self.backView
                          duration:duration
                           options:options
                        completion:^(BOOL finished) {
                            // animation completed
                        }];
    } else {
        [UIView transitionFromView:self.backView
                            toView:_frontView
                          duration:duration
                           options:options
                        completion:^(BOOL finished) {
                            // animation completed
                            _frontView = nil;
                        }];
    }
}

@end
