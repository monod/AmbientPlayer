//
//  APSoundSelectViewCell.m
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/09/18.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import "APSoundSelectViewCell.h"

@implementation APSoundSelectViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        // Image
        self.preview = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 100.0)];
        self.backgroundView = self.preview;
        
        // Cover
        cover = [[APGradientBackgroundView alloc]initWithFrame:CGRectMake(0.0, 0.0, 320.0, 100.0)];
        [self.contentView addSubview:cover];
        
        // Title
        self.title = [[UILabel alloc]initWithFrame:CGRectMake(10.0, 60.0, 310.0, 40.0)];
        self.title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
        self.title.backgroundColor = [UIColor clearColor];
        self.title.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.title];
        
        // Slider
        self.slider = [[UISlider alloc] initWithFrame:CGRectMake(120.0, 60.0, 180.0, 40.0)];
        self.slider.minimumValue = 0;
        self.slider.maximumValue = 1.0;
        self.slider.value = 1.0;
        self.slider.hidden = YES;
        [self.contentView addSubview:self.slider];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    cover.selected = selected;
    [cover setNeedsDisplay];
    self.slider.hidden = !selected;

}

@end
