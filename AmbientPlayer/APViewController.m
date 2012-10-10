//
//  APViewController.m
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/09/05.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import "APViewController.h"

#import <iAd/iAd.h>
#import "AudioToolbox/AudioToolbox.h"
#import "APCrossFadePlayer.h"
#import "APSoundEntry.h"
#import "APSoundSelectViewCell.h"

NSString * const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString * const BannerViewActionDidFinish = @"BannerViewActionDidFinish";

NSString * const SoundCellIdentifier = @"SoundCell";
NSString * const AddCellIdentifier = @"AddCell";

const int kSectionPreset = 0;
const int kSectionRecorded = 1;
const int kSectionOther = 2;

const NSInteger kTagPresetSoundCollectionView = 1;
const NSInteger kTagRecordedSoundCollectionView = 0;

@interface APViewController () <ADBannerViewDelegate>

@property (nonatomic, strong) AVAudioSession* session;
@property (nonatomic, strong) APCrossFadePlayer *player;
@property (nonatomic, copy) NSArray *preset;
@property (nonatomic, strong) ADBannerView *bannerView;
@property (nonatomic, strong) NSArray *recordedSoundEntries;

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
                   [[APSoundEntry alloc] initWithTitle:@"Airport" withFileName:@"airport_in" andImageFileName:@"airport_in"],
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
    
    self.recordedCollectionView.tag = kTagRecordedSoundCollectionView;
    [self.recordedCollectionView registerClass:[APSoundSelectViewCell class] forCellWithReuseIdentifier:SoundCellIdentifier];
    [self.recordedCollectionView registerClass:[APSoundSelectViewCell class] forCellWithReuseIdentifier:AddCellIdentifier];
    ((UICollectionViewFlowLayout*)self.recordedCollectionView.collectionViewLayout).minimumInteritemSpacing = 2;
    ((UICollectionViewFlowLayout*)self.recordedCollectionView.collectionViewLayout).minimumLineSpacing = 2;
    _playingItemPathInRecorded = nil;
    
    self.player = [APCrossFadePlayer new];

    self.routeView.showsRouteButton = YES;
    self.routeView.showsVolumeSlider = NO;
    CGSize sz = [self.routeView sizeThatFits:self.routeView.bounds.size];
    self.routeView.bounds = CGRectMake(self.routeView.bounds.origin.x, self.routeView.bounds.origin.y, sz.width, sz.height);
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

- (NSArray *)findRecordedSoundEntries {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:[APSoundEntry recordedFileDirectory] error:nil];
    
    //サムネイル検索処理が少し重いので、1エントリごとに.m4aと.pngを含む1ディレクトリというファイル構造にした方がよくない？
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.m4a'"];
    NSPredicate *thumbFltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.png'"];
    NSArray *thumbs = [dirContents filteredArrayUsingPredicate:thumbFltr];

    //保存した.m4aファイルからAPSoundEntryを生成する処理
    NSMutableArray *recordedSoundEntries = [NSMutableArray array];
    id recordedFileName;
    for (recordedFileName in [dirContents filteredArrayUsingPredicate:fltr]) {
        NSString *thumbFileName = [recordedFileName stringByReplacingOccurrencesOfString:@".m4a" withString:@".png"]; // know that ".m4a" occurs only in the extension?
        APSoundEntry *recordedSountEntry;
        if ([thumbs containsObject:thumbFileName])
            recordedSountEntry = [[APSoundEntry alloc] initWithTitle:recordedFileName withFileName:recordedFileName andImageFileName:thumbFileName];
        else
            recordedSountEntry = [[APSoundEntry alloc] initWithTitle:recordedFileName withFileName:recordedFileName];
        [recordedSoundEntries addObject:recordedSountEntry];
    }
    
    //return [dirContents filteredArrayUsingPredicate:fltr];
    return recordedSoundEntries;
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
            if ([collectionView numberOfItemsInSection:0] == indexPath.row + 1) {
                // last item in the section: "Add" button
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
    APSoundEntry *entry = [soundEntries objectAtIndex:index];
    APSoundSelectViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SoundCellIdentifier forIndexPath:indexPath];
    
    cell.title.text = entry.title;
    [cell.info addTarget:self action:@selector(showDetailView:) forControlEvents:UIControlEventTouchUpInside];
    
    if (collectionView.tag == kTagPresetSoundCollectionView) {
        NSString *path = [[NSBundle mainBundle] pathForResource:entry.imageFileName ofType:@"jpg"];
        UIImage *img = [UIImage imageWithContentsOfFile:path];
        cell.preview.image = img;
        cell.playing = [indexPath isEqual:_playingItemPathInPreset];
    } else if (collectionView.tag == kTagRecordedSoundCollectionView) {
        NSString *path = nil;
        if (entry.imageFileName == nil)
            path = [[NSBundle mainBundle] pathForResource:@"sound" ofType:@"png"];
        else
            path = [[APSoundEntry recordedFileDirectory] stringByAppendingPathComponent:entry.imageFileName];
        UIImage *img = [UIImage imageWithContentsOfFile:path];
        cell.preview.image = img;
        cell.playing = [indexPath isEqual:_playingItemPathInRecorded];
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
    if (collectionView.tag == kTagRecordedSoundCollectionView && [collectionView numberOfItemsInSection:0] == indexPath.row + 1) {
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
            cell.playing = NO;
            _playingItemPathInPreset = nil;
        } else {
            // deselect the current cell
            ((APSoundSelectViewCell*)[self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset]).playing = NO;
            cell.playing = YES;
            _playingItemPathInPreset = indexPath;
            
            if (_playingItemPathInRecorded) {
                // deselect all in recorded collection view
                ((APSoundSelectViewCell*)[self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded]).playing = NO;
                _playingItemPathInRecorded = nil;
            }
        }
        [self updatePlayState];
    } else if (tag == kTagRecordedSoundCollectionView) {
        // if the same cell is selected again, then deselect it
        if (cell.playing) {
            cell.playing = NO;
            _playingItemPathInRecorded = nil;
        } else {
            // deselect the current cell
            ((APSoundSelectViewCell*)[self.recordedCollectionView cellForItemAtIndexPath:_playingItemPathInRecorded]).playing = NO;
            cell.playing = YES;
            _playingItemPathInRecorded = indexPath;
            // deselect all in preset collection view
            if (_playingItemPathInPreset) {
                ((APSoundSelectViewCell*)[self.presetCollectionView cellForItemAtIndexPath:_playingItemPathInPreset]).playing = NO;
                _playingItemPathInPreset = nil;
            }
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
        APSoundEntry *entry = [self.recordedSoundEntries objectAtIndex:_playingItemPathInRecorded.row];
        [self.player setVolume:self.volumeSlider.value];
        [self.player play:entry rootDirectory:[APSoundEntry recordedFileDirectory]];
    } else {
        [self.player stop];
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

- (void)showDetailView:(id)sender {

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
