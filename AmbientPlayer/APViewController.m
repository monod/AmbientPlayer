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

NSString * const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString * const BannerViewActionDidFinish = @"BannerViewActionDidFinish";

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

-(void)initPreset {
    self.preset = [NSArray arrayWithObjects:
                   [[APSoundEntry alloc] initPresetWithTitle:@"Forest" withFileName:@"forest" andImageFileName:@"forest"],
                   [[APSoundEntry alloc] initPresetWithTitle:@"Ocean" withFileName:@"ocean" andImageFileName:@"ocean"],
                   [[APSoundEntry alloc] initPresetWithTitle:@"Rain" withFileName:@"rain" andImageFileName:@"rain"],
                   [[APSoundEntry alloc] initPresetWithTitle:@"Sea" withFileName:@"sea" andImageFileName:@"sea"],
                   [[APSoundEntry alloc] initPresetWithTitle:@"Stream" withFileName:@"stream" andImageFileName:@"stream"],
                   [[APSoundEntry alloc] initPresetWithTitle:@"Crickets" withFileName:@"crickets" andImageFileName:@"crickets"],
                   nil];
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.recordedFiles = [self findRecordedFiles];
    [self.tableView reloadData];
    [self setupAudioSession];
}

- (NSArray *)findRecordedFiles {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.caf'"];
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
            APSoundEntry *entry = [self.preset objectAtIndex:indexPath.row];
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
            }
            cell.textLabel.text = entry.title;

            UISlider *slider = [[UISlider alloc] init];
            slider.minimumValue = 0.0;
            slider.maximumValue = 1.0;
            slider.value = 1.0;
            slider.hidden = YES;
            [slider addTarget:self action:@selector(onSliderChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = slider;
            
            if (entry.imageFileName) {
                NSString *path = [[NSBundle mainBundle] pathForResource:entry.imageFileName ofType:@"jpg"];
                UIImage *img = [UIImage imageWithContentsOfFile:path];
                cell.imageView.image = img;
            } else {
                cell.imageView.image = nil;
            }
            return cell;
        }
        case kSectionRecorded:
        {
            NSString *soundFile = [self.recordedFiles objectAtIndex:indexPath.row];
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
            }
            cell.textLabel.text = soundFile;
            cell.imageView.image = nil;
            return cell;
        }
        case kSectionOther:
        {
            // TODO 今は、「追加」のセルだけを作っているけど、追加した音声も作るようにする
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            if(!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
            }
            cell.textLabel.text = @"追加";
            return cell;
        }
        default:
            NSAssert(NO, @"This line should not be reached");
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionPreset:
        {
            APSoundEntry *entry = [self.preset objectAtIndex:indexPath.row];

            // Slider
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            UISlider *slider = (UISlider *)cell.accessoryView;
            slider.value =  entry.volume;
            slider.hidden = NO;
            
            [self.player setCurrentSoundName:entry.fileName];
            [self.player setVolume:entry.volume];
            [self.player play];
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

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionPreset:
        {
            // Slider
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            UISlider *slider = (UISlider *)cell.accessoryView;
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
