//
//  APSoundSelectViewCell.h
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/09/18.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "APGradientBackgroundView.h"

@interface APSoundSelectViewCell : UICollectionViewCell {
    APGradientBackgroundView* cover;
}

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UIImageView *preview;

@end
