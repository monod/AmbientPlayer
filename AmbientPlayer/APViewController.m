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
        [controller.player stop];
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
    
    self.recordedCollectionView.tag = kTagRecordedSoundCollectionView;
    [self.recordedCollectionView registerClass:[APSoundSelectViewCell class] forCellWithReuseIdentifier:SoundCellIdentifier];
    ((UICollectionViewFlowLayout*)self.recordedCollectionView.collectionViewLayout).minimumInteritemSpacing = 2;
    ((UICollectionViewFlowLayout*)self.recordedCollectionView.collectionViewLayout).minimumLineSpacing = 2;
    
    
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

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.recordedSoundEntries = [self findRecordedSoundEntries];
    [self.recordedCollectionView reloadData];
    [self setupAudioSession];
}

- (NSArray *)findRecordedSoundEntries {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:[APSoundEntry recordedFileDirectory] error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.m4a'"];
    
    //保存した.m4aファイルからAPSoundEntryを生成する処理
    NSMutableArray *recordedSoundEntries = [NSMutableArray array];
    id recordedFileName;
    for (recordedFileName in [dirContents filteredArrayUsingPredicate:fltr]) {
        APSoundEntry *recordedSountEntry = [[APSoundEntry alloc] initWithTitle:recordedFileName withFileName:recordedFileName];
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
                APSoundSelectViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SoundCellIdentifier forIndexPath:indexPath];
                cell.title.text = @"Add...";
                cell.preview.image = nil;
                cell.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2];
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
    
    if (entry.imageFileName) {
        NSString *path = [[NSBundle mainBundle] pathForResource:entry.imageFileName ofType:@"jpg"];
        UIImage *img = [UIImage imageWithContentsOfFile:path];
        cell.preview.image = img;
    } else {
        cell.preview.image = nil;
        cell.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2];
    }
    return cell;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (collectionView.tag) {
        case kTagPresetSoundCollectionView:
            return self.preset.count;
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
    switch (collectionView.tag) {
        case kTagPresetSoundCollectionView:
        {
            [self playOrStopSoundEntry:collectionView itemAtIndexPath:indexPath soundEntries:self.preset soundRootDirectory:nil];

            return;
        }
        case kTagRecordedSoundCollectionView:
        {
            if ([collectionView numberOfItemsInSection:0] == indexPath.row + 1) {
                // 「追加」のセルだった場合、録音用画面を呼び出すようにする
                [self.player stop];
                [self performSegueWithIdentifier:@"toRecord" sender:self];
            } else {
                [self playOrStopSoundEntry:collectionView itemAtIndexPath:indexPath soundEntries:self.recordedSoundEntries soundRootDirectory:[APSoundEntry recordedFileDirectory]];
            }
            return;
        }
        case kSectionOther:
            return;
        default:
            NSAssert(NO, @"This line should not be reached");
            return;
    }

}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

}


- (void) playOrStopSoundEntry:(UICollectionView *) collectionView itemAtIndexPath:(NSIndexPath *)indexPath soundEntries:(NSArray *) soundEntries soundRootDirectory:(NSString *) rootDirectory{
    APSoundEntry *entry = [soundEntries objectAtIndex:indexPath.row];
    
    // Stop in case of the same entry
    if ([self.player isPlaying:entry]) {
        [self.player stopEntry];
        return;
    }
    [self.player setVolume:self.volumeSlider.value];
    [self.player play:entry rootDirectory:rootDirectory];
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
