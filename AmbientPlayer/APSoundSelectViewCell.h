//
//  APSoundSelectViewCell.h
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/09/18.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "APGradientBackgroundView.h"
#import "APLevelMeterView.h"

@interface APSoundSelectViewCell : UICollectionViewCell {
    APGradientBackgroundView *_cover;
    APLevelMeterView *_levelMeter;
    
    BOOL _playing;
}

- (void)updateLevelMeterForChannels:(float)ch0 and:(float)ch1;

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UIImageView *preview;
@property (getter=isPlaying) BOOL playing;

@end
