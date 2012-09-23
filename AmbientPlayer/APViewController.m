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

NSString * const PresetCellIdentifier = @"PresetCell";
NSString * const RecordedCellIdentifier = @"RecordedCell";
NSString * const AddCellIdentifier = @"Add";

const int kSectionPreset = 0;
const int kSectionRecorded = 1;
const int kSectionOther = 2;

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
                   [[APSoundEntry alloc] initWithTitle:@"Forest" withFileName:@"forest" andImageFileName:@"forest"],
                   [[APSoundEntry alloc] initWithTitle:@"Ocean" withFileName:@"ocean" andImageFileName:@"ocean"],
                   [[APSoundEntry alloc] initWithTitle:@"Rain" withFileName:@"rain" andImageFileName:@"rain"],
                   [[APSoundEntry alloc] initWithTitle:@"Seagull" withFileName:@"sea" andImageFileName:@"sea"],
                   [[APSoundEntry alloc] initWithTitle:@"Stream" withFileName:@"stream" andImageFileName:@"stream"],
                   [[APSoundEntry alloc] initWithTitle:@"Crickets" withFileName:@"crickets" andImageFileName:@"crickets"],
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

    self.player = [APCrossFadePlayer new];
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
    [self.tableView reloadData];
    [self setupAudioSession];
}

- (NSArray *)findRecordedSoundEntries {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
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
    self.tableView.frame = contentFrame;
    self.bannerView.frame = bannerFrame;
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionPreset:
        {
            return [self setUpSoundSelectViewCell:tableView cellForRowAtIndexPath:indexPath cellIdentifier:PresetCellIdentifier soundEntriesArray:self.preset];
        }
        case kSectionRecorded:
        {
            return [self setUpSoundSelectViewCell:tableView cellForRowAtIndexPath:indexPath cellIdentifier:RecordedCellIdentifier soundEntriesArray:self.recordedSoundEntries];
        }
        case kSectionOther:
        {
            // TODO 今は、「追加」のセルだけを作っているけど、追加した音声も作るようにする
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AddCellIdentifier];
            if(!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AddCellIdentifier];
            }
            cell.textLabel.text = @"Add...";
            cell.textLabel.textColor = [UIColor whiteColor];
            return cell;
        }
        default:
            NSAssert(NO, @"This line should not be reached");
            return nil;
    }
}

- (APSoundSelectViewCell *)setUpSoundSelectViewCell:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath cellIdentifier:(NSString *)identifier soundEntriesArray:(NSArray *) soundEntriesArray {
    APSoundEntry *entry = [soundEntriesArray objectAtIndex:indexPath.row];
    APSoundSelectViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[APSoundSelectViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        [cell.slider addTarget:self action:@selector(onSliderChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    cell.title.text = entry.title;
    if ([indexPath compare:[tableView indexPathForSelectedRow]] == NSOrderedSame) {
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case kSectionPreset:
            return self.preset.count;
        case kSectionRecorded:
            return [self.recordedSoundEntries count];
        case kSectionOther:
            return 1;
        default:
            NSAssert(NO, @"This line should not be reached");
            return 0;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionPreset:
        {
            [self playOrStopSoundEntry:tableView rowAtIndexPath:indexPath soundEntries:self.preset soundRootDirectory:nil];
            return;
        }
        case kSectionRecorded:
        {
            [self playOrStopSoundEntry:tableView rowAtIndexPath:indexPath soundEntries:self.recordedSoundEntries soundRootDirectory:NSTemporaryDirectory()];
//            NSString *fileName = ((APSoundEntry *)[self.recordedSoundEntries objectAtIndex:indexPath.row]).fileName;
//            NSString *dirName = NSTemporaryDirectory();
//            self.player.currentSoundFileName = [dirName stringByAppendingPathComponent:fileName];
//            [self.player play];
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

- (void) playOrStopSoundEntry:(UITableView *) tableView rowAtIndexPath:(NSIndexPath *)indexPath soundEntries:(NSArray *) soundEntries soundRootDirectory:(NSString *) rootDirectory{
    APSoundEntry *entry = [soundEntries objectAtIndex:indexPath.row];
    
    // Stop in case of the same entry
    if ([self.player isPlaying:entry]) {
        [self.player stopEntry];
        [self saveVolume:tableView atIndex:indexPath soundEntries:soundEntries];
        return;
    }
    
    // Slider
    APSoundSelectViewCell *cell = (APSoundSelectViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    UISlider *slider = (UISlider *)cell.slider;
    slider.value =  entry.volume;
    slider.hidden = NO;
    
    [self.player play:entry rootDirectory:rootDirectory];
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionPreset:
        {
            //save volume value
            [self saveVolume:tableView atIndex:indexPath soundEntries:self.preset];
            
            break;
        }
        case kSectionRecorded:
            //save volume value
            [self saveVolume:tableView atIndex:indexPath soundEntries:self.recordedSoundEntries];
            
            break;
        case kSectionOther:
            break;
        default:
            NSAssert(NO, @"This line should not be reached");
            return;
    }
}

- (void) saveVolume:(UITableView *)tableView atIndex:(NSIndexPath *) indexPath soundEntries:(NSArray *) soundEntries{
    // Slider
    APSoundSelectViewCell *cell = (APSoundSelectViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    UISlider *slider = (UISlider *)cell.slider;
    slider.hidden = YES;
    APSoundEntry *entry = [soundEntries objectAtIndex:indexPath.row];
    entry.volume = slider.value;
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
