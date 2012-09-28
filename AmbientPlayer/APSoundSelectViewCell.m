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
        
        // Slider
        //self.slider = [[UISlider alloc] initWithFrame:CGRectMake(10.0, frame.size.height - 40.0, frame.size.width - 20.0, 40.0)];
        //self.slider.minimumValue = 0;
        //self.slider.maximumValue = 1.0;
        //self.slider.value = 1.0;
        //self.slider.hidden = YES;
        //self.slider.minimumTrackTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4];
        //self.slider.maximumTrackTintColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4];
        //[self.contentView addSubview:self.slider];
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    // Configure the view for the selected state
    cover.selected = selected;
    [cover setNeedsDisplay];
    //self.slider.hidden = !selected;

}

@end
