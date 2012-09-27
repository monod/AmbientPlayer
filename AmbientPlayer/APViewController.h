//
//  APViewController.h
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/09/05.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPVolumeView.h>

@interface APViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource> {
}

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet MPVolumeView *volumeView;

@end

