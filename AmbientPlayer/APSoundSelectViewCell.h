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
    
    BOOL _playing;
}

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UIImageView *preview;
@property (nonatomic, strong) UIButton *info;
@property (nonatomic, strong) APLevelMeterView *levelMeter;

@property (getter=isPlaying) BOOL playing;
@property (getter=isDisclosed) BOOL disclosed;
@end
