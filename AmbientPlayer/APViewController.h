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
#import "APSoundCellBackView.h"

@interface APViewController : UIViewController <UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, AVAudioPlayerDelegate> {
    CADisplayLink *_updateTimer;
    NSIndexPath *_playingItemPathInPreset;
    BOOL _playingItemInPresetFlipped;
    NSIndexPath *_playingItemPathInRecorded;
    BOOL _playingItemInRecordedFlipped;
}

@property (nonatomic, strong) IBOutlet UIScrollView *pageScrollView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UICollectionView *presetCollectionView;
@property (nonatomic, strong) IBOutlet UICollectionView *recordedCollectionView;
@property (nonatomic, strong) IBOutlet MPVolumeView *routeView;
@property (nonatomic, strong) IBOutlet UISlider *volumeSlider;

- (IBAction)changeVolume:(id)sender;
- (IBAction)changePage:(id)sender;

- (void)deselectAll;
- (void)updatePlayState;

@end

