//
//  APViewController.m
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/09/05.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import "APViewController.h"
#import "APAppDelegate.h"

#import <MediaPlayer/MediaPlayer.h>

#import "APCrossFadePlayer.h"
#import "APSoundSelectViewCell.h"
#import "APCustomSoundEntryModel.h"
#import "SCUI.h"
#import "APSoundCloudActivity.h"

NSString *const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString *const BannerViewActionDidFinish = @"BannerViewActionDidFinish";

NSString *const SoundCellIdentifier = @"SoundCell";
NSString *const AddCellIdentifier = @"AddCell";

const int kSectionPreset = 0;
const int kSectionRecorded = 1;
const int kSectionOther = 2;

const NSInteger kTagPresetSoundCollectionView = 1;
const NSInteger kTagRecordedSoundCollectionView = 2;

const NSInteger kTagAlertDeleteSound = 1;

@interface APViewController ()

@property(nonatomic, strong) AVAudioSession *session;
@property(nonatomic, strong) APCrossFadePlayer *player;
@property(nonatomic, copy) NSArray *preset;
@property(nonatomic, strong) NSMutableArray *recordedSoundEntries;

@end

#define SYNTHESIZE(propertyName) @synthesize propertyName = _ ## propertyName


@implementation APViewController

SYNTHESIZE(session);
SYNTHESIZE(player);
SYNTHESIZE(preset);

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initPreset];
        //self.bannerView = [ADBannerView new];
        //self.bannerView.delegate = self;
        _updateTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerUpdate:)];
        _dateFormatter = [[NSDateFormatter alloc]init];
        _dateFormatter.dateFormat = @"HH:mm:ss";
    }
    return self;
}

- (void)dealloc {
    AudioSessionRemovePropertyListenerWithUserData(
            kAudioSessionProperty_AudioRouteChange,
            audioRouteChangeListenerCallback,
            (__bridge void *) (self)
    );
}

- (void)initPreset {
    self.preset = [NSArray arrayWithObjects:
            [[APSoundEntry alloc] initWithTitle:@"Waterfall" fileName:@"waterfall" image:@"waterfall" description: NSLocalizedString(@"DescWaterfall", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Forest" fileName:@"forest" image:@"forest" description:NSLocalizedString(@"DescForest", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Ocean" fileName:@"ocean" image:@"ocean" description:NSLocalizedString(@"DescOcean", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Rain" fileName:@"rain" image:@"rain" description:NSLocalizedString(@"DescRain", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Thunder" fileName:@"thunder" image:@"thunder" description:NSLocalizedString(@"DescThunder", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Stream" fileName:@"stream" image:@"stream" description:NSLocalizedString(@"DescStream", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Fire" fileName:@"fire" image:@"fire" description:NSLocalizedString(@"DescFire", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Crickets" fileName:@"crickets" image:@"crickets" description:NSLocalizedString(@"DescCrickets", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Seagulls" fileName:@"seagull" image:@"seagull" description:NSLocalizedString(@"DescSeagull", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Cicadas" fileName:@"cicada" image:@"cicada" description:NSLocalizedString(@"DescCicada", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Airport" fileName:@"airport_in" image:@"airport_in" description:NSLocalizedString(@"DescTerminal", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Runway" fileName:@"airport_deck" image:@"airport_deck" description:NSLocalizedString(@"DescDeck", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Fireworks" fileName:@"fireworks" image:@"fireworks" description:NSLocalizedString(@"DescFireworks", nil)],
            [[APSoundEntry alloc] initWithTitle:@"Pub" fileName:@"pub" image:@"pub" description:NSLocalizedString(@"DescPub", nil)],
            nil];
}

void audioRouteChangeListenerCallback(void *clientData, AudioSessionPropertyID inID, UInt32 dataSize, const void *inData) {
    CFDictionaryRef dict = (CFDictionaryRef) inData;
    CFNumberRef reason = CFDictionaryGetValue(dict, kAudioSession_RouteChangeKey_Reason);
    //    CFDictionaryRef oldRoute = CFDictionaryGetValue(dict, kAudioSession_AudioRouteChangeKey_PreviousRouteDescription);
    //    CFDictionaryRef newRoute = CFDictionaryGetValue(dict, kAudioSession_AudioRouteChangeKey_CurrentRouteDescription);

    SInt32 routeChangeReason;
    CFNumberGetValue(reason, kCFNumberSInt32Type, &routeChangeReason);
    if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
        APViewController *controller = (__bridge APViewController *) (clientData);
        [controller deselectAll];
        [controller updatePlayState];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];

    //set CoreData managedObjectContext
    self.managedObjectContext = [APAppDelegate sharedManagedObjectContext];

    // PageScroll
    self.pageScrollView.contentSize = CGSizeMake(self.pageScrollView.frame.size.width * 2, self.pageScrollView.frame.size.height);

    // CollectionView configuration
    self.presetCollectionView.tag = kTagPresetSoundCollectionView;
    [self.presetCollectionView registerClass:[APSoundSelectViewCell class] forCellWithReuseIdentifier:SoundCellIdentifier];
    ((UICollectionViewFlowLayout *) self.presetCollectionView.collectionViewLayout).minimumInteritemSpacing = 2;
    ((UICollectionViewFlowLayout *) self.presetCollectionView.collectionViewLayout).minimumLineSpacing = 2;
    _playingItemPathInPreset = nil;
    _playingItemInPresetFlipped = NO;

    self.recordedCollectionView.tag = kTagRecordedSoundCollectionView;
    [self.recordedCollectionView registerClass:[APSoundSelectViewCell class] forCellWithReuseIdentifier:SoundCellIdentifier];
    [self.recordedCollectionView registerClass:[APSoundSelectViewCell class] forCellWithReuseIdentifier:AddCellIdentifier];
    ((UICollectionViewFlowLayout *) self.recordedCollectionView.collectionViewLayout).minimumInteritemSpacing = 2;
    ((UICollectionViewFlowLayout *) self.recordedCollectionView.collectionViewLayout).minimumLineSpacing = 2;
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

    // Init CALayer
    [self initLayersAndViewsForAnimation];
    
    // Set default value for timer
    self.timerPicker.countDownDuration = 1800;
}

- (void)setupAudioSession {
    _session = [AVAudioSession sharedInstance];
    NSError *errRet = nil;
    [self.session setCategory:AVAudioSessionCategoryPlayback error:&errRet];

    UInt32 allowMixing = true;
    AudioSessionSetProperty(
            kAudioSessionProperty_OverrideCategoryMixWithOthers,  // 1
            sizeof (allowMixing),                                 // 2
            &allowMixing                                          // 3
    );
    [self.session setActive:YES error:&errRet];
    AudioSessionAddPropertyListener(
            kAudioSessionProperty_AudioRouteChange,
            audioRouteChangeListenerCallback,
            (__bridge void *) (self)
    );

}

- (void)viewWillAppear:(BOOL)animated {
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    // Deselect all if there is an incoming call
    [self deselectAll];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    switch (collectionView.tag) {
        case kTagPresetSoundCollectionView: {
            return [self setUpCollectionViewCell:collectionView cellForItemAtIndexPath:indexPath soundEntries:self.preset];
        }
        case kTagRecordedSoundCollectionView: {
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

- (UICollectionViewCell *)setUpCollectionViewCell:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath soundEntries:(NSArray *)soundEntries {
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
        cell.backView.description.text = entry.description;

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
            //NSLog(@"entry's image file for view cell is %@  -----------------", entry.imageFileName);
            path = [entry getRecordedImageFilePath];
            //NSLog(@"custom image file for view cell is %@  -----------------", path);
        }


        UIImage *img = [UIImage imageWithContentsOfFile:path];
        cell.preview.image = img;
        cell.backView.deleteButton.hidden = NO;
        cell.backView.description.text = entry.description;
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout *) collectionViewLayout;
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

- (void)toggleCellInView:(UICollectionView *)collectionView withIndexPath:(NSIndexPath *)indexPath {
    NSInteger tag = collectionView.tag;
    APSoundSelectViewCell *cell = (APSoundSelectViewCell *) [collectionView cellForItemAtIndexPath:indexPath];

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
                APSoundSelectViewCell *currentCell = (APSoundSelectViewCell *) [self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset];
                if (_playingItemInPresetFlipped) {
                    [currentCell flipViewToBackSide:NO withAnimation:YES];
                }
                currentCell.playing = NO;
            } else if (_playingItemPathInRecorded) {
                // deselect the current cell in Recorded Collection
                APSoundSelectViewCell *currentCell = (APSoundSelectViewCell *) [self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded];
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
                APSoundSelectViewCell *currentCell = (APSoundSelectViewCell *) [self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded];
                if (_playingItemInRecordedFlipped) {
                    [currentCell flipViewToBackSide:NO withAnimation:YES];
                }
                currentCell.playing = NO;
            } else if (_playingItemPathInPreset) {
                // deselect the current cell in Preset Collection
                APSoundSelectViewCell *currentCell = (APSoundSelectViewCell *) [self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset];
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
        APSoundSelectViewCell *cell = (APSoundSelectViewCell *) [self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset];
        cell.playing = NO;
        _playingItemPathInPreset = nil;
    }
    if (_playingItemPathInRecorded) {
        APSoundSelectViewCell *cell = (APSoundSelectViewCell *) [self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded];
        cell.playing = NO;
        _playingItemPathInRecorded = nil;
    }
}

- (int)currentRecordedSoundPlayingItemIndex {
    return _playingItemPathInRecorded.row - 1;
}

- (int)currentPresetSoundPlayingItemIndex {
    return _playingItemPathInPreset.row;
}

// Play or stop sound according to the selection state
- (void)updatePlayState {
    if (_playingItemPathInPreset) {
        APSoundEntry *entry = [self.preset objectAtIndex:[self currentPresetSoundPlayingItemIndex]];
        [self.player setVolume:self.volumeSlider.value];
        [self.player play:entry rootDirectory:nil];
    } else if (_playingItemPathInRecorded) {
        APSoundEntry *entry = [self.recordedSoundEntries objectAtIndex:[self currentRecordedSoundPlayingItemIndex]];
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
        APSoundEntry *entry = [self.recordedSoundEntries objectAtIndex:[self currentRecordedSoundPlayingItemIndex]];
        [self.recordedSoundEntries removeObject:entry];

        //Remove From CoreData
        if (entry.moID) {
            [APCustomSoundEntryModel removeAPCustomSoundEntryModel:entry.moID inManagedObjectContext:self.managedObjectContext];
        }


        // Remove Localfiles
        NSString *soundPath = [[APSoundEntry recordedFileDirectory] stringByAppendingPathComponent:entry.fileName];
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        [fileMgr removeItemAtPath:soundPath error:nil];

        // 画像ファイルがある場合は、画像をローカルから消す。
        if (entry.imageFileName) {
            NSString *imagePath = [[APSoundEntry recordedFileDirectory] stringByAppendingPathComponent:entry.imageFileName];
            [fileMgr removeItemAtPath:imagePath error:nil];
        }

        // Update UI
        [self.recordedCollectionView deleteItemsAtIndexPaths:@[_playingItemPathInRecorded]];
        _playingItemInRecordedFlipped = NO;
        _playingItemPathInRecorded = nil;
    }
}

- (void)timerUpdate:(CADisplayLink *)sender {
    APSoundSelectViewCell *cell = nil;
    if (_playingItemPathInPreset) {
        cell = (APSoundSelectViewCell *) [self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset];
    } else if (_playingItemPathInRecorded) {
        cell = (APSoundSelectViewCell *) [self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded];
    }

    if (cell && cell.isPlaying) {
        float ch0 = [self.player powerForChannel:0];
        float ch1 = [self.player powerForChannel:1];
        [cell.levelMeter updateValuesWith:ch0 and:ch1];
    }
}

- (IBAction)changeVolume:(id)sender {
    UISlider *slider = (UISlider *) sender;
    [self.player setVolume:slider.value];
}

- (void)showBackView:(id)sender {
    APSoundSelectViewCell *cell = (APSoundSelectViewCell *) ((UIView *) sender).superview.superview;
    [cell flipViewToBackSide:YES withAnimation:YES];
    if (_playingItemPathInPreset) {
        _playingItemInPresetFlipped = YES;
    } else if (_playingItemPathInRecorded) {
        _playingItemInRecordedFlipped = YES;
    }
}

- (void)hideBackView:(id)sender {
    APSoundSelectViewCell *cell = (APSoundSelectViewCell *) ((UIView *) sender).superview.superview.superview;
    [cell flipViewToBackSide:NO withAnimation:YES];
    if (_playingItemPathInPreset) {
        _playingItemInPresetFlipped = NO;
    } else if (_playingItemPathInRecorded) {
        _playingItemInRecordedFlipped = NO;
    }

}

- (void)showShareSheet:(id)sender {
    NSMutableString *text = [NSMutableString stringWithString:@"#NowPlaying "];
    MPMediaItem *nowplaying = [MPMusicPlayerController iPodMusicPlayer].nowPlayingItem;
    if (nowplaying) {
        NSString *track = (NSString *) [nowplaying valueForProperty:MPMediaItemPropertyTitle];
        NSString *artist = (NSString *) [nowplaying valueForProperty:MPMediaItemPropertyArtist];
        [text appendFormat:@" %@ / %@ + ", track, artist];
    }

    UIImage *img = nil;
    APSoundEntry *recordedSoundEntry = nil;
    if (_playingItemPathInPreset) {
        APSoundSelectViewCell *cell = (APSoundSelectViewCell *) [self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset];
        [text appendString:@"\""];
        [text appendString:cell.title.text];
        [text appendString:@"\""];
        img = cell.preview.image;
    } else if (_playingItemPathInRecorded) {
        recordedSoundEntry = [self.recordedSoundEntries objectAtIndex:[self currentRecordedSoundPlayingItemIndex]];
        APSoundSelectViewCell *cell = (APSoundSelectViewCell *) [self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded];
        [text appendString:@"\""];
        [text appendString:cell.title.text];
        [text appendString:@"\""];
        img = cell.preview.image;
    }

    if (img) {
        UIGraphicsBeginImageContext(CGSizeMake(160, 160));
        [img drawInRect:CGRectMake(0, 0, 160, 160)];
        img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    NSURL *url = [NSURL URLWithString:@"https://itunes.apple.com/app/ambientplayer/id578213987?ls=1&mt=8"];

    [text appendString:@" #AmbientPlayer"];

    NSArray *items = nil;
    APSoundCloudActivity *scActivity = nil;
    NSArray *applicationActivities = nil;

    if (recordedSoundEntry && recordedSoundEntry.soundCloudURL) {
        //SoundCloudのURLがある場合、画像の添付ではなく、そっちのURLを共有する。Facebookの場合、そのまま再生できるはず。
        scActivity = [[APSoundCloudActivity alloc] init];
        applicationActivities = [NSArray arrayWithObject:scActivity];
        url = [NSURL URLWithString:recordedSoundEntry.soundCloudURL];

        //textの方に公式サイトへのリンクはつけとく。
        [text appendString:@"\n"];
        [text appendString:@"https://itunes.apple.com/app/ambientplayer/id578213987?ls=1&mt=8"];
        [text appendString:@"\n"];

        items = @[text, url, recordedSoundEntry];
    } else if (recordedSoundEntry){
        scActivity = [[APSoundCloudActivity alloc] init];
        applicationActivities = [NSArray arrayWithObject:scActivity];
        items = @[text, img, url, recordedSoundEntry];
    } else {
        items = @[text, img, url];
    }


    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:applicationActivities];
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
            initWithTitle:NSLocalizedString(@"DeleteAlertTitle", nil) message:NSLocalizedString(@"DeleteAlertMessage", nil) delegate:self
        cancelButtonTitle:NSLocalizedString(@"CancelButtonLabel", nil) otherButtonTitles:@"OK", nil];
    alert.tag = kTagAlertDeleteSound;
    [alert show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
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

#pragma mark UIGestureRecognizer

- (IBAction)onSwipeLeft:(id)sender {
    int index = self.pageControl.currentPage;
    if (index == 0) {
        [self turnFace:1];
    } else if (index == 1) {
        [self turnFace:2];
    }
}

- (IBAction)onSwipeRight:(id)sender {
    int index = self.pageControl.currentPage;
    if (index == 2) {
        [self turnFace:1];
    } else if (index == 1) {
        [self turnFace:0];
    }
}

#pragma mark Cubic transition

CALayer *_parent;
CALayer *_layers[3];
UIView *_views[3];

- (void)initLayersAndViewsForAnimation {

    CGFloat viewWidth = self.presetCollectionView.frame.size.width;
    CGFloat viewHeight = self.presetCollectionView.frame.size.height;

    CATransform3D r;
    CATransform3D t;

    CATransform3D front = CATransform3DMakeTranslation(0, 0, 0);

    r = CATransform3DMakeRotation(M_PI * 0.5, 0, 1, 0);
    t = CATransform3DMakeTranslation(viewWidth / 2, 0, -viewWidth / 2);
    CATransform3D right = CATransform3DConcat(r, t);
    
    r = CATransform3DMakeRotation(-M_PI * 0.5, 0, 1, 0);
    t = CATransform3DMakeTranslation(-viewWidth / 2, 0, -viewWidth / 2);
    CATransform3D left = CATransform3DConcat(r, t);
    
    if (_parent == nil) {
        _parent = [CALayer layer];
        _parent.bounds = CGRectMake(0, 0, viewWidth, viewHeight);
        _parent.position = CGPointMake(viewWidth / 2, viewHeight / 2);

        [self initParentTransform];
        [self.view.layer insertSublayer:_parent atIndex:0];
    }

    if (_layers[0] == nil) {
        _layers[0] = [CALayer layer];
        _layers[0].bounds = CGRectMake(0, 0, viewWidth, viewHeight);
        _layers[0].position = CGPointMake(viewWidth / 2, viewHeight / 2);
        _layers[0].transform = left;
        [_parent addSublayer:_layers[0]];
    }

    if (_layers[1] == nil) {
        _layers[1] = [CALayer layer];
        _layers[1].bounds = CGRectMake(0, 0, viewWidth, viewHeight);
        _layers[1].position = CGPointMake(viewWidth / 2, viewHeight / 2);
        _layers[1].transform = front;
        [_parent addSublayer:_layers[1]];
    }

    if (_layers[2] == nil) {
        _layers[2] = [CALayer layer];
        _layers[2].bounds = CGRectMake(0, 0, viewWidth, viewHeight);
        _layers[2].position = CGPointMake(viewWidth / 2, viewHeight / 2);
        _layers[2].transform = right;
        [_parent addSublayer:_layers[2]];
    }

    _views[0] = self.settingsView;
    _views[1] = self.presetCollectionView;
    _views[2] = self.recordedCollectionView;
}

- (void)turnFace:(int)newIndex {
    [self initParentTransform];
    int index = self.pageControl.currentPage;
    CGFloat viewWidth = self.presetCollectionView.frame.size.width;
    CGFloat viewHeight = self.presetCollectionView.frame.size.height;

    // Update current view to layer
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (_layers[index].contents == nil) {
        // Get image from parent view in case view has been scrolled
        [self setContentToLayer:_layers[index] fromView:self.collectionParent];
    }
    if (_layers[newIndex].contents == nil) {
        [self setContentToLayer:_layers[newIndex] fromView:_views[newIndex]];
    }
    [CATransaction commit];

    // Hide current view
    _views[index].frame = CGRectMake(-viewWidth, 0, viewWidth, viewHeight);

    // Begin animation
    CGFloat rad = (1 - newIndex) * M_PI * 0.5;
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.5];
    [CATransaction setCompletionBlock:^(void) {
        // Show next view
        _views[newIndex].frame = CGRectMake(0, 0, viewWidth, viewHeight);
        // update page control
        self.pageControl.currentPage = newIndex;
        // delete layer contents
        _layers[newIndex].contents = nil;
    }];
    _parent.sublayerTransform = CATransform3DTranslate(_parent.sublayerTransform, 0, 0, -viewWidth / 2);
    _parent.sublayerTransform = CATransform3DRotate(_parent.sublayerTransform, rad, 0, 1, 0);
    _parent.sublayerTransform = CATransform3DTranslate(_parent.sublayerTransform, 0, 0, viewWidth / 2);
    [CATransaction commit];
}

- (void)initParentTransform {
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = -1.0 / 800;
    _parent.sublayerTransform = perspective;
}

- (void)setContentToLayer:(CALayer *)layer fromView:(UIView *)view {
    UIGraphicsBeginImageContext(view.frame.size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    layer.contents = (__bridge id) viewImage.CGImage;
}

- (void)viewDidUnload {
    [self setCollectionParent:nil];
    [super viewDidUnload];
}

#pragma mark Timer

BOOL _timerRunning = NO;
NSInteger _remaining = 0;
NSTimer *_timer = nil;

- (void)toggleTimer:(id)sender {
    if (_timerRunning) {
        _timerRunning = NO;
        [_timer invalidate];
        self.timerPicker.hidden = NO;
        self.timerLabel.hidden = YES;
        [self.timerStartButton setTitle:@"Start" forState:UIControlStateNormal];
    } else {
        self.timerLabel.text = [_dateFormatter stringFromDate:self.timerPicker.date];
        _remaining = self.timerPicker.countDownDuration;
        _timerRunning = YES;
        self.timerPicker.hidden = YES;
        self.timerLabel.hidden = NO;
        [self.timerStartButton setTitle:@"Stop" forState:UIControlStateNormal];
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
        [_timer fire];
    }
}

- (void)updateTimer:(NSTimer *)timer {
    if (_timerRunning) { 
        _remaining = MAX(0, _remaining - timer.timeInterval);
        NSInteger h = _remaining / 3600;
        NSInteger m = (_remaining % 3600) / 60;
        NSInteger s = _remaining % 60;
        NSString *label = [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
        self.timerLabel.text = label;
        
        if (_remaining == 0) {
            [self toggleTimer:nil];
            [self deselectAll];
            [self updatePlayState];
            // Stop playing music as well
            [[MPMusicPlayerController iPodMusicPlayer] stop];
        }
    }
}

@end
