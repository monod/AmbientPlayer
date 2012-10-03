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
        cover = [[APGradientBackgroundView alloc]initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        [self.contentView addSubview:cover];
        
        // Title
        self.title = [[UILabel alloc]initWithFrame:CGRectMake(10.0, frame.size.height - 40.0, frame.size.width - 20.0, 40.0)];
        self.title.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:32.0];
        self.title.backgroundColor = [UIColor clearColor];
        self.title.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.title];
        
    }
    return self;
}

- (void)setPlaying:(BOOL)playing {
    _playing = playing;
    // Configure the view for the selected state
    cover.selected = playing;
    [cover setNeedsDisplay];
}

- (BOOL)isPlaying {
    return _playing;
}

@end
