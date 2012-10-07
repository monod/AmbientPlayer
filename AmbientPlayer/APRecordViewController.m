//
//  APRecordViewController.m
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/09/08.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import "APRecordViewController.h"
#import "APSoundEntry.h"

#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>

@interface APRecordViewController () <AVAudioRecorderDelegate>
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSURL *lastRecordedFile;
@end

@implementation APRecordViewController

const int kMaxRecordSeconds = 120;
const int kMinRecordSeconds = 2;
typedef enum PlayState { kPlayStateStop, kPlayStateRecording, kPlayStatePause } PlayState;

PlayState _state;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Update timer for level meter
    _updateTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerUpdate:)];
    
    _formatter = [[NSDateFormatter alloc] init];
    _formatter.dateFormat = @"HHmmss_yyyyMMdd";
    
    int m = kMaxRecordSeconds / 60;
    int s = kMaxRecordSeconds % 60;
    self.maxTime.text = [NSString stringWithFormat:@"%02d:%02d.0", m, s];
    self.waveForm.duration = kMaxRecordSeconds;
    self.waveForm.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
}

- (void)viewWillAppear:(BOOL)animated {
    [_updateTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [super viewWillAppear:animated];
    [self setupAudioSession];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_updateTimer removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)timerUpdate:(CADisplayLink *)sender {
    if (self.recorder) {
        [self.recorder updateMeters];
        float v0 = [self.recorder averagePowerForChannel:0];
        float v1 = [self.recorder averagePowerForChannel:1];
        [self.levelMeter updateValuesWith:v0 and:v1];
        
        if (self.recorder.isRecording) {
            _duration = self.recorder.currentTime;
            NSTimeInterval time = MIN(kMaxRecordSeconds, _duration);
            int m = (int)time / 60;
            double s = time - m * 60;
            self.elapsedTime.text = [NSString stringWithFormat:@"%02d:%04.1f", m, s];
            [self.waveForm addSampleAt:time withValue:v0];
        }
    }
}

- (void)setupAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError* error = nil;
    [session setCategory: AVAudioSessionCategoryPlayAndRecord error: &error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    [session setActive: YES error: &error];
    if (error) {
        NSLog(@"%@", error);
    }
    
    NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];
    
    //[recordSetting setValue: [NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    
    NSURL *recordedTmpFile = [NSURL fileURLWithPath:[[APSoundEntry recordedFileDirectory] stringByAppendingPathComponent: [NSString stringWithFormat:@"%@.%@", [_formatter stringFromDate:[NSDate date]], @"m4a"]]];
    
    self.recorder = [[AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:&error];
    if (error) {
        NSLog(@"Failed to create AVAudioRecorder %@", error);
        return;
    }
    self.recorder.meteringEnabled = YES;
    [self.recorder setDelegate:self];
    [self.recorder prepareToRecord];
    
    _duration = 0;
    _state = kPlayStateStop;
    [self updateButtonLabel];
}

- (void)updateButtonLabel {
    NSString *label = nil;
    switch (_state) {
        case kPlayStateStop:
            label = @"REC";
            break;
        case kPlayStateRecording:
            label = @"PAUSE";
            break;
        case kPlayStatePause:
            label = @"RESUME";
            break;
    }
    if (label) {
        [self.recordButton setTitle:label forState:UIControlStateNormal];
    }
}

- (void)startRecording {
    [self.recorder recordForDuration:(NSTimeInterval)kMaxRecordSeconds];
    _state = kPlayStateRecording;
    [self updateButtonLabel];
    NSLog(@"[REC][START]");
}

- (void)pauseRecording {
    [self.recorder pause];
    _state = kPlayStatePause;
    [self updateButtonLabel];
    NSLog(@"[REC][PAUSE]");
}

- (void)resumeRecording {
    [self.recorder record];
    _state = kPlayStateRecording;
    [self updateButtonLabel];
    NSLog(@"[REC][RESUME]");
}

- (void)stopRecording {
    [self.recorder stop];
    _state = kPlayStateStop;
    [self updateButtonLabel];
    NSLog(@"[REC][STOP]");
}

-(IBAction)donePushed:(id)sender {
    [self stopRecording];
    NSLog(@"[REC][DONE] %4.1f", _duration);
    if (_duration < kMinRecordSeconds) {
        [self.recorder deleteRecording];
        NSLog(@"[REC][DELETE] File deleted");
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)recordPushed:(id)sender {
    switch (_state) {
        case kPlayStateStop:
            [self.waveForm resetSample];
            [self startRecording];
            break;
        case kPlayStateRecording:
            [self pauseRecording];
            break;
        case kPlayStatePause:
            [self resumeRecording];
            break;
    }
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    _state = kPlayStateStop;
    [self updateButtonLabel];
}

@end
