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

@interface APViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, AVAudioPlayerDelegate> {
    CADisplayLink *_updateTimer;
    NSIndexPath *_playingItemPathInPreset;
    BOOL _playingItemInPresetFlipped;
    NSIndexPath *_playingItemPathInRecorded;
    BOOL _playingItemInRecordedFlipped;
}

@property (weak, nonatomic) IBOutlet UIScrollView *pageScrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UICollectionView *presetCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *recordedCollectionView;
@property (weak, nonatomic) IBOutlet MPVolumeView *routeView;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UIView *collectionParent;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)changeVolume:(id)sender;
- (IBAction)showShareSheet:(id)sender;

- (void)deselectAll;
- (void)updatePlayState;

- (IBAction)onSwipeLeft:(id)sender;
- (IBAction)onSwipeRight:(id)sender;

@end

