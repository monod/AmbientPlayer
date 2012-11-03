//
//  APViewController.m
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/09/05.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import "APViewController.h"
#import "APAppDelegate.h"

#import <iAd/iAd.h>
#import <MediaPlayer/MediaPlayer.h>

#import "AudioToolbox/AudioToolbox.h"
#import "APCrossFadePlayer.h"
#import "APSoundEntry.h"
#import "APSoundSelectViewCell.h"
#import "APiCloudAdapter.h"
#import "APCustomSoundEntryModel.h"

NSString * const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString * const BannerViewActionDidFinish = @"BannerViewActionDidFinish";

NSString * const SoundCellIdentifier = @"SoundCell";
NSString * const AddCellIdentifier = @"AddCell";

const int kSectionPreset = 0;
const int kSectionRecorded = 1;
const int kSectionOther = 2;

const NSInteger kTagPresetSoundCollectionView = 1;
const NSInteger kTagRecordedSoundCollectionView = 2;

const NSInteger kTagAlertDeleteSound = 1;

@interface APViewController () <ADBannerViewDelegate>

@property (nonatomic, strong) AVAudioSession* session;
@property (nonatomic, strong) APCrossFadePlayer *player;
@property (nonatomic, copy) NSArray *preset;
@property (nonatomic, strong) ADBannerView *bannerView;
@property (nonatomic, strong) NSMutableArray *recordedSoundEntries;

@end

#define SYNTHESIZE(propertyName) @synthesize propertyName = _ ## propertyName


@implementation APViewController

SYNTHESIZE(session);
SYNTHESIZE(player);
SYNTHESIZE(preset);

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initPreset];
        //self.bannerView = [ADBannerView new];
        //self.bannerView.delegate = self;
        _updateTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerUpdate:)];
    }
    return self;
}

-(void)dealloc {
    AudioSessionRemovePropertyListenerWithUserData(
                                                   kAudioSessionProperty_AudioRouteChange,
                                                   audioRouteChangeListenerCallback,
                                                   (__bridge void *)(self)
                                                   );
}

-(void)initPreset {
    self.preset = [NSArray arrayWithObjects:
                   [[APSoundEntry alloc] initWithTitle:@"Forest" withFileName:@"forest" andImageFileName:@"forest"],
                   [[APSoundEntry alloc] initWithTitle:@"Ocean" withFileName:@"ocean" andImageFileName:@"ocean"],
                   [[APSoundEntry alloc] initWithTitle:@"Rain" withFileName:@"rain" andImageFileName:@"rain"],
                   [[APSoundEntry alloc] initWithTitle:@"Seagull" withFileName:@"sea" andImageFileName:@"sea"],
                   [[APSoundEntry alloc] initWithTitle:@"Stream" withFileName:@"stream" andImageFileName:@"stream"],
                   [[APSoundEntry alloc] initWithTitle:@"Crickets" withFileName:@"crickets" andImageFileName:@"crickets"],
                   [[APSoundEntry alloc] initWithTitle:@"Terminal" withFileName:@"airport_in" andImageFileName:@"airport_in"],
                   [[APSoundEntry alloc] initWithTitle:@"Deck" withFileName:@"airport_deck" andImageFileName:@"airport_deck"],
                   nil];
}

void audioRouteChangeListenerCallback (void *clientData, AudioSessionPropertyID inID, UInt32 dataSize, const void *inData) {
    CFDictionaryRef dict = (CFDictionaryRef) inData;
    CFNumberRef reason = CFDictionaryGetValue(dict, kAudioSession_RouteChangeKey_Reason);
    //    CFDictionaryRef oldRoute = CFDictionaryGetValue(dict, kAudioSession_AudioRouteChangeKey_PreviousRouteDescription);
    //    CFDictionaryRef newRoute = CFDictionaryGetValue(dict, kAudioSession_AudioRouteChangeKey_CurrentRouteDescription);
    
    SInt32 routeChangeReason;
    CFNumberGetValue (reason, kCFNumberSInt32Type, &routeChangeReason);
    if (routeChangeReason ==  kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
        APViewController *controller = (__bridge APViewController *)(clientData);
        [controller deselectAll];
        [controller updatePlayState];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //set CoreData managedObjectContext
    self.managedObjectContext = [APAppDelegate sharedManagedObjectContext];
    
	// Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:_bannerView];
    
    // PageScroll
    self.pageScrollView.contentSize = CGSizeMake(self.pageScrollView.frame.size.width * 2, self.pageScrollView.frame.size.height);
    
    // CollectionView configuration
    self.presetCollectionView.tag = kTagPresetSoundCollectionView;
    [self.presetCollectionView registerClass:[APSoundSelectViewCell class] forCellWithReuseIdentifier:SoundCellIdentifier];
    ((UICollectionViewFlowLayout*)self.presetCollectionView.collectionViewLayout).minimumInteritemSpacing = 2;
    ((UICollectionViewFlowLayout*)self.presetCollectionView.collectionViewLayout).minimumLineSpacing = 2;
    _playingItemPathInPreset = nil;
    _playingItemInPresetFlipped = NO;
    
    self.recordedCollectionView.tag = kTagRecordedSoundCollectionView;
    [self.recordedCollectionView registerClass:[APSoundSelectViewCell class] forCellWithReuseIdentifier:SoundCellIdentifier];
    [self.recordedCollectionView registerClass:[APSoundSelectViewCell class] forCellWithReuseIdentifier:AddCellIdentifier];
    ((UICollectionViewFlowLayout*)self.recordedCollectionView.collectionViewLayout).minimumInteritemSpacing = 2;
    ((UICollectionViewFlowLayout*)self.recordedCollectionView.collectionViewLayout).minimumLineSpacing = 2;
    _playingItemPathInRecorded = nil;
    _playingItemInRecordedFlipped = NO;
    
    self.player = [APCrossFadePlayer new];
    
    self.routeView.showsRouteButton = YES;
    self.routeView.showsVolumeSlider = NO;
    CGSize sz = [self.routeView sizeThatFits:self.routeView.bounds.size];
    self.routeView.bounds = CGRectMake(self.routeView.bounds.origin.x, self.routeView.bounds.origin.y, sz.width, sz.height);
    
    // Slider
    NSString *path = [[NSBundle mainBundle] pathForResource:@"knob" ofType:@"png"];
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    [self.volumeSlider setThumbImage:img forState:UIControlStateNormal];
    
    path = [[NSBundle mainBundle] pathForResource:@"knob_hl" ofType:@"png"];
    img = [UIImage imageWithContentsOfFile:path];
    [self.volumeSlider setThumbImage:img forState:UIControlStateHighlighted];
    
    path = [[NSBundle mainBundle] pathForResource:@"min" ofType:@"png"];
    img = [UIImage imageWithContentsOfFile:path];
    [self.volumeSlider setMinimumTrackImage:img forState:UIControlStateNormal];
    
    path = [[NSBundle mainBundle] pathForResource:@"max" ofType:@"png"];
    img = [UIImage imageWithContentsOfFile:path];
    [self.volumeSlider setMaximumTrackImage:img forState:UIControlStateNormal];
}

- (void)setupAudioSession {
    _session = [AVAudioSession sharedInstance];
    NSError* errRet = nil;
    [self.session setCategory: AVAudioSessionCategoryPlayback error: &errRet];
    
    UInt32 allowMixing = true;
    AudioSessionSetProperty (
                             kAudioSessionProperty_OverrideCategoryMixWithOthers,  // 1
                             sizeof (allowMixing),                                 // 2
                             &allowMixing                                          // 3
                             );
    [self.session setActive: YES error: &errRet];
    AudioSessionAddPropertyListener(
                                    kAudioSessionProperty_AudioRouteChange,
                                    audioRouteChangeListenerCallback,
                                    (__bridge void *)(self)
                                    );
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_updateTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.recordedSoundEntries = [self findRecordedSoundEntries];
    [self.recordedCollectionView reloadData];
    self.recordedCollectionView.delegate = self;
    [self setupAudioSession];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_updateTimer removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (NSMutableArray *)findRecordedSoundEntries {
    return [APCustomSoundEntryModel getAllSoundEntriesIn:self.managedObjectContext];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)viewDidLayoutSubviews
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        self.bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    } else {
        self.bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    }
    CGRect contentFrame = self.view.bounds;
    CGRect bannerFrame = self.bannerView.frame;
    if (self.bannerView.bannerLoaded) {
        contentFrame.size.height -= self.bannerView.frame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
    }
    self.bannerView.frame = bannerFrame;
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    // Deselect all if there is an incoming call
    [self deselectAll];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
	
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.pageScrollView.frame.size.width;
    int page = floor((self.pageScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    switch (collectionView.tag) {
        case kTagPresetSoundCollectionView:
        {
            return [self setUpCollectionViewCell:collectionView cellForItemAtIndexPath:indexPath soundEntries:self.preset];
        }
        case kTagRecordedSoundCollectionView:
        {
            if (indexPath.section == 0 && indexPath.row == 0) {
                // first item in the section: "Add" button
                APSoundSelectViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:AddCellIdentifier forIndexPath:indexPath];
                cell.title.text = @"Add...";
                NSString *path = [[NSBundle mainBundle] pathForResource:@"add" ofType:@"png"];
                UIImage *img = [UIImage imageWithContentsOfFile:path];
                cell.preview.image = img;
                return cell;
            } else {
                return [self setUpCollectionViewCell:collectionView cellForItemAtIndexPath:indexPath soundEntries:self.recordedSoundEntries];
            }
        }
        default:
            NSAssert(NO, @"This line should not be reached");
            return nil;
    }
}

- (UICollectionViewCell *) setUpCollectionViewCell:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath soundEntries:(NSArray *) soundEntries {
    NSInteger index = indexPath.row;
    if (collectionView.tag == kTagRecordedSoundCollectionView) {
        index--;
    }
    APSoundEntry *entry = [soundEntries objectAtIndex:index];
    APSoundSelectViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SoundCellIdentifier forIndexPath:indexPath];
    
    cell.title.text = entry.title;
    cell.backView.title.text = entry.title;
    
    // Event handlers
    [cell.info addTarget:self action:@selector(showBackView:) forControlEvents:UIControlEventTouchUpInside];
    [cell.backView.doneButton addTarget:self action:@selector(hideBackView:) forControlEvents:UIControlEventTouchUpInside];
    [cell.backView.deleteButton addTarget:self action:@selector(showDeleteConfirmAlert) forControlEvents:UIControlEventTouchUpInside];
    [cell.backView.shareButton addTarget:self action:@selector(showShareSheet:) forControlEvents:UIControlEventTouchUpInside];
    
    if (collectionView.tag == kTagPresetSoundCollectionView) {
        NSString *path = [[NSBundle mainBundle] pathForResource:entry.imageFileName ofType:@"jpg"];
        UIImage *img = [UIImage imageWithContentsOfFile:path];
        cell.preview.image = img;
        cell.backView.deleteButton.hidden = YES;
        // check wheter it is now playing
        if ([indexPath isEqual:_playingItemPathInPreset]) {
            cell.playing = YES;
            [cell flipViewToBackSide:_playingItemInPresetFlipped withAnimation:NO];
        } else {
            cell.playing = NO;
            [cell flipViewToBackSide:NO withAnimation:NO];
        }
    } else if (collectionView.tag == kTagRecordedSoundCollectionView) {
        NSString *path = nil;
        if (entry.imageFileName == nil)
            path = [[NSBundle mainBundle] pathForResource:@"sound" ofType:@"png"];
        else {
            NSLog(@"entry's image file for view cell is %@  -----------------", entry.imageFileName);
            path = [[APSoundEntry recordedFileDirectory] stringByAppendingPathComponent:entry.imageFileName];
            NSLog(@"custom image file for view cell is %@  -----------------", path);
        }
        
        
        UIImage *img = [UIImage imageWithContentsOfFile:path];
        cell.preview.image = img;
        cell.backView.deleteButton.hidden = NO;
        // check wheter it is now playing
        if ([indexPath isEqual:_playingItemPathInRecorded]) {
            cell.playing = YES;
            [cell flipViewToBackSide:_playingItemInRecordedFlipped withAnimation:NO];
        } else {
            cell.playing = NO;
            [cell flipViewToBackSide:NO withAnimation:NO];
        }
    }
    return cell;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (collectionView.tag) {
        case kTagPresetSoundCollectionView:
            return [self.preset count];
        case kTagRecordedSoundCollectionView:
            return [self.recordedSoundEntries count] + 1;
        default:
            NSAssert(NO, @"This line should not be reached");
            return 0;
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout*)collectionViewLayout;
    CGFloat w = (collectionView.frame.size.width - flow.minimumInteritemSpacing) / 2;
    return CGSizeMake(w, w);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == kTagRecordedSoundCollectionView && indexPath.section == 0 && indexPath.row
         == 0) {
        // 「追加」のセルだった場合、録音用画面を呼び出すようにする
        [self deselectAll];
        [self updatePlayState];
        [self performSegueWithIdentifier:@"toRecord" sender:self];
    } else {
        [self toggleCellInView:collectionView withIndexPath:indexPath];
    }
}

- (void) toggleCellInView:(UICollectionView*)collectionView withIndexPath:(NSIndexPath*)indexPath {
    NSInteger tag = collectionView.tag;
    APSoundSelectViewCell *cell = (APSoundSelectViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (tag == kTagPresetSoundCollectionView) {
        // if the same cell is selected again, then deselect it
        if (cell.playing) {
            if (!_playingItemInPresetFlipped) {
                // unless the cell is flipped
                cell.playing = NO;
                _playingItemPathInPreset = nil;
            }
        } else {
            if (_playingItemPathInPreset) {
                // deselect the current cell in Preset Collection
                APSoundSelectViewCell *currentCell = (APSoundSelectViewCell*)[self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset];
                if (_playingItemInPresetFlipped) {
                    [currentCell flipViewToBackSide:NO withAnimation:YES];
                }
                currentCell.playing = NO;
            } else if (_playingItemPathInRecorded) {
                // deselect the current cell in Recorded Collection
                APSoundSelectViewCell *currentCell = (APSoundSelectViewCell*)[self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded];
                if (_playingItemInRecordedFlipped) {
                    [currentCell flipViewToBackSide:NO withAnimation:YES];
                }
                currentCell.playing = NO;
                _playingItemPathInRecorded = nil;
            }
            cell.playing = YES;
            _playingItemPathInPreset = indexPath;
            _playingItemInPresetFlipped = NO;
        }
        [self updatePlayState];
    } else if (tag == kTagRecordedSoundCollectionView) {
        // if the same cell is selected again, then deselect it
        if (cell.playing) {
            if (!_playingItemInRecordedFlipped) {
                // unless the cell is flipped
                cell.playing = NO;
                _playingItemPathInRecorded = nil;
            }
        } else {
            if (_playingItemPathInRecorded) {
                // deselect the current cell in Recorded Collection
                APSoundSelectViewCell *currentCell = (APSoundSelectViewCell*)[self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded];
                if (_playingItemInRecordedFlipped) {
                    [currentCell flipViewToBackSide:NO withAnimation:YES];
                }
                currentCell.playing = NO;
            } else if (_playingItemPathInPreset) {
                // deselect the current cell in Preset Collection
                APSoundSelectViewCell *currentCell = (APSoundSelectViewCell*)[self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset];
                if (_playingItemInPresetFlipped) {
                    [currentCell flipViewToBackSide:NO withAnimation:YES];
                }
                currentCell.playing = NO;
                _playingItemPathInPreset = nil;
            }
            cell.playing = YES;
            _playingItemPathInRecorded = indexPath;
            _playingItemInRecordedFlipped = NO;
        }
        [self updatePlayState];
    }
}

- (void)deselectAll {
    if (_playingItemPathInPreset) {
        APSoundSelectViewCell *cell = (APSoundSelectViewCell*)[self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset];
        cell.playing = NO;
        _playingItemPathInPreset = nil;
    }
    if (_playingItemPathInRecorded) {
        APSoundSelectViewCell *cell = (APSoundSelectViewCell*)[self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded];
        cell.playing = NO;
        _playingItemPathInRecorded = nil;
    }
}

// Play or stop sound according to the selection state
- (void)updatePlayState {
    if (_playingItemPathInPreset) {
        APSoundEntry *entry = [self.preset objectAtIndex:_playingItemPathInPreset.row];
        [self.player setVolume:self.volumeSlider.value];
        [self.player play:entry rootDirectory:nil];
    } else if (_playingItemPathInRecorded) {
        APSoundEntry *entry = [self.recordedSoundEntries objectAtIndex:_playingItemPathInRecorded.row - 1];
        [self.player setVolume:self.volumeSlider.value];
        [self.player play:entry rootDirectory:[APSoundEntry recordedFileDirectory]];
    } else {
        [self.player stop];
    }
}

- (void)deleteSelectedItem {
    if (_playingItemPathInRecorded) {
        
        //削除処理をする前にplayerを停止しておく
        [self.player stop];
        
        // Remove entry from array
        APSoundEntry *entry = [self.recordedSoundEntries objectAtIndex:_playingItemPathInRecorded.row - 1];
        [self.recordedSoundEntries removeObject:entry];

        //Remove From CoreData
        if (entry.moID) {
            [APCustomSoundEntryModel removeAPCustomSoundEntryModel:entry.moID inManagedObjectContext:self.managedObjectContext];
        }
        
        //Remove From iCloud
        NSString *path = [[APSoundEntry recordedFileDirectory] stringByAppendingPathComponent:entry.fileName];
        NSURL* fileURL = [NSURL fileURLWithPath:path];
        [APiCloudAdapter removeCorrespondingFileFromiCloud:fileURL];

        // Remove Localfile
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        [fileMgr removeItemAtPath:path error:nil];

        
        
        
        // Update UI
        [self.recordedCollectionView deleteItemsAtIndexPaths:@[_playingItemPathInRecorded]];
        _playingItemInRecordedFlipped = NO;
        _playingItemPathInRecorded = nil;
    }
}

- (void)timerUpdate:(CADisplayLink*)sender {
    APSoundSelectViewCell *cell = nil;
    if (_playingItemPathInPreset) {
        cell = (APSoundSelectViewCell*)[self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset];
    } else if (_playingItemPathInRecorded) {
        cell = (APSoundSelectViewCell*)[self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded];
    }
    
    if (cell && cell.isPlaying) {
        float ch0 = [self.player powerForChannel:0];
        float ch1 = [self.player powerForChannel:1];
        [cell.levelMeter updateValuesWith:ch0 and:ch1];
    }
}

- (IBAction)changeVolume:(id)sender {
    UISlider *slider = (UISlider*)sender;
    [self.player setVolume:slider.value];
}

- (IBAction)changePage:(id)sender
{
    int page = self.pageControl.currentPage;
    
	// update the scroll view to the appropriate page
    CGRect frame = self.pageScrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [self.pageScrollView scrollRectToVisible:frame animated:YES];
}

- (void)showBackView:(id)sender {
    APSoundSelectViewCell *cell = (APSoundSelectViewCell *)((UIView *)sender).superview.superview;
    [cell flipViewToBackSide:YES withAnimation:YES];
    if (_playingItemPathInPreset) {
        _playingItemInPresetFlipped = YES;
    } else if (_playingItemPathInRecorded) {
        _playingItemInRecordedFlipped = YES;
    }
}

- (void)hideBackView:(id)sender {
    APSoundSelectViewCell *cell = (APSoundSelectViewCell *)((UIView *)sender).superview.superview.superview;
    [cell flipViewToBackSide:NO withAnimation:YES];
    if (_playingItemPathInPreset) {
        _playingItemInPresetFlipped = NO;
    } else if (_playingItemPathInRecorded) {
        _playingItemInRecordedFlipped = NO;
    }
    
}

- (void)showShareSheet:(id)sender {
    NSMutableString *text = [NSMutableString string];
    UIImage *img = nil;
    if (_playingItemPathInPreset) {
        APSoundSelectViewCell *cell = (APSoundSelectViewCell *)[self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset];
        [text appendString:cell.title.text];
        img = cell.preview.image;
    } else if (_playingItemPathInRecorded) {
        APSoundSelectViewCell *cell = (APSoundSelectViewCell *)[self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded];
        [text appendString:cell.title.text];
        img = cell.preview.image;
    }
    
    MPMediaItem *nowplaying = [MPMusicPlayerController iPodMusicPlayer].nowPlayingItem;
    if (nowplaying) {
        NSString *track = (NSString *)[nowplaying valueForProperty:MPMediaItemPropertyTitle];
        NSString *artist = (NSString *)[nowplaying valueForProperty:MPMediaItemPropertyArtist];
        [text appendFormat:@" with %@ / %@", track, artist];
    }
    [text appendString:@" #AmbientPlayer"];
    NSArray *items = @[text, img];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc]initWithActivityItems: items applicationActivities:@[]];
    activityVC.excludedActivityTypes = @[
        UIActivityTypeAssignToContact,
        UIActivityTypePrint,
        UIActivityTypeSaveToCameraRoll,
        UIActivityTypeMail,
        UIActivityTypeCopyToPasteboard
    ];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)showDeleteConfirmAlert {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"DeleteAlertTitle", nil)
                          message:NSLocalizedString(@"DeleteAlertMessage", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"CancelButtonLabel", nil)
                          otherButtonTitles:@"OK", nil];
    alert.tag = kTagAlertDeleteSound;
    [alert show];
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case kTagAlertDeleteSound:
            if (buttonIndex == 1) {
                [self deleteSelectedItem];
            }
            break;
        default:
            break;
    }
}

#pragma mark - iAd

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionWillBegin object:self];
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionDidFinish object:self];
}

@end
