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
#import "APSoundCellBackView.h"

@interface APSoundSelectViewCell : UICollectionViewCell {
    APGradientBackgroundView *_cover;
    UIView *_frontView;
    BOOL _playing;
}

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UIImageView *preview;
@property (nonatomic, strong) UIButton *info;
@property (nonatomic, strong) APLevelMeterView *levelMeter;
@property (nonatomic, strong) APSoundCellBackView *backView;

@property (getter=isPlaying) BOOL playing;

- (void)flipViewToBackSide:(BOOL)backSide withAnimation:(BOOL)animation;

@end
