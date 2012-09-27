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

@interface APViewController () <ADBannerViewDelegate>

@property (nonatomic, strong) AVAudioSession* session;
@property (nonatomic, strong) APCrossFadePlayer *player;
@property (nonatomic, copy) NSArray *preset;
@property (nonatomic, strong) ADBannerView *bannerView;
@property (nonatomic, strong) NSArray *recordedFiles;

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
        self.bannerView = [ADBannerView new];
        self.bannerView.delegate = self;
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
                   [[APSoundEntry alloc] initPresetWithTitle:@"Forest" withFileName:@"forest" andImageFileName:@"forest"],
                   [[APSoundEntry alloc] initPresetWithTitle:@"Ocean" withFileName:@"ocean" andImageFileName:@"ocean"],
                   [[APSoundEntry alloc] initPresetWithTitle:@"Rain" withFileName:@"rain" andImageFileName:@"rain"],
                   [[APSoundEntry alloc] initPresetWithTitle:@"Seagull" withFileName:@"sea" andImageFileName:@"sea"],
                   [[APSoundEntry alloc] initPresetWithTitle:@"Stream" withFileName:@"stream" andImageFileName:@"stream"],
                   [[APSoundEntry alloc] initPresetWithTitle:@"Crickets" withFileName:@"crickets" andImageFileName:@"crickets"],
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
    
    // CollectionView configuration
    [self.collectionView registerClass:[APSoundSelectViewCell class] forCellWithReuseIdentifier:SoundCellIdentifier];
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    layout.minimumInteritemSpacing = 2;
    layout.minimumLineSpacing = 2;
    
    self.player = [APCrossFadePlayer new];
    
    self.volumeView = [[MPVolumeView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100) ];
    self.volumeView.showsVolumeSlider = NO;
    [self.view addSubview:self.volumeView];
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
    self.recordedFiles = [self findRecordedFiles];
    [self.collectionView reloadData];
    [self setupAudioSession];
}

- (NSArray *)findRecordedFiles {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.m4a'"];
    return [dirContents filteredArrayUsingPredicate:fltr];
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
    self.collectionView.frame = contentFrame;
    self.bannerView.frame = bannerFrame;
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 3;
}
/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case kSectionPreset:
            return @"Preset";
        case kSectionRecorded:
            return @"Recorded";
        case kSectionOther:
            return @"Other";
        default:
            return nil;
    }
}
*/
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionPreset:
        {
            APSoundEntry *entry = [self.preset objectAtIndex:indexPath.row];
            APSoundSelectViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SoundCellIdentifier forIndexPath:indexPath];

            [cell.slider addTarget:self action:@selector(onSliderChanged:) forControlEvents:UIControlEventValueChanged];
            cell.title.text = entry.title;
            if ([indexPath compare:[collectionView indexPathForCell:cell]] == NSOrderedSame) {
                cell.selected = YES;
            } else {
                cell.selected = NO;
            }
            
            if (entry.imageFileName) {
                NSString *path = [[NSBundle mainBundle] pathForResource:entry.imageFileName ofType:@"jpg"];
                UIImage *img = [UIImage imageWithContentsOfFile:path];
                cell.preview.image = img;
            } else {
                cell.preview.image = nil;
            }
            return cell;
        }
        case kSectionRecorded:
        {
            NSString *soundFile = [self.recordedFiles objectAtIndex:indexPath.row];
            APSoundSelectViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SoundCellIdentifier forIndexPath:indexPath];
            cell.title.text = soundFile;
            cell.preview.image = nil;
            return cell;
        }
        case kSectionOther:
        {
            // TODO 今は、「追加」のセルだけを作っているけど、追加した音声も作るようにする
            APSoundSelectViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SoundCellIdentifier forIndexPath:indexPath];
            cell.title.text = @"Add...";
            cell.preview.image = nil;
            return cell;
        }
        default:
            NSAssert(NO, @"This line should not be reached");
            return nil;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (section) {
        case kSectionPreset:
            return self.preset.count;
        case kSectionRecorded:
            return [self.recordedFiles count];
        case kSectionOther:
            return 1;
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
    switch (indexPath.section) {
        case kSectionPreset:
        {
            APSoundEntry *entry = [self.preset objectAtIndex:indexPath.row];

            // Stop in case of the same entry
            if ([self.player isPlaying:entry]) {
                [self.player stopEntry];
                return;
            }

            // Slider
            APSoundSelectViewCell *cell = (APSoundSelectViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
            UISlider *slider = (UISlider *)cell.slider;
            slider.value =  entry.volume;
            slider.hidden = NO;
            
            [self.player play:entry];
            return;
        }
        case kSectionRecorded:
        {
            NSString *fileName = [self.recordedFiles objectAtIndex:indexPath.row];
            self.player.currentSoundFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
            [self.player play];
            return;
        }
        case kSectionOther:
            // 「追加」のセルだった場合、録音用画面を呼び出すようにする
            [self.player stop];
            [self performSegueWithIdentifier:@"toRecord" sender:self];
            return;
        default:
            NSAssert(NO, @"This line should not be reached");
            return;
    }

}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionPreset:
        {
            // Slider
            APSoundSelectViewCell *cell = (APSoundSelectViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
            UISlider *slider = (UISlider *)cell.slider;
            slider.hidden = YES;
            APSoundEntry *entry = [self.preset objectAtIndex:indexPath.row];
            entry.volume = slider.value;
            
            break;
        }
        case kSectionRecorded:
            break;
        case kSectionOther:
            break;
        default:
            NSAssert(NO, @"This line should not be reached");
            return;
    }
}

- (void)onSliderChanged:(UISlider *)slider {
    NSLog(@"val = %f", slider.value);
    [self.player setVolume:slider.value];
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
