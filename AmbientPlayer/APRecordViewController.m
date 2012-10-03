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
@property (nonatomic, assign) BOOL isRecording;
@end

@implementation APRecordViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.isRecording = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Update timer for level meter
    _updateTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerUpdate:)];
    [_updateTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    _formatter = [[NSDateFormatter alloc] init];
    _formatter.dateFormat = @"yyyyMMdd_HHmmss";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupAudioSession];
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
            int m = (int)self.recorder.currentTime / 60;
            double s = self.recorder.currentTime - m * 60;
           self.elapsedTime.text = [NSString stringWithFormat:@"%02d:%04.1f", m, s];
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
}

-(NSURL *)startRecording {
    NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];
    
    //[recordSetting setValue: [NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    
    NSURL *recordedTmpFile = [NSURL fileURLWithPath:[[APSoundEntry recordedFileDirectory] stringByAppendingPathComponent: [NSString stringWithFormat:@"%@.%@", [_formatter stringFromDate:[NSDate date]], @"m4a"]]];
    
    NSError *error = nil;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:&error];
    if (error) {
        NSLog(@"Failed to create AVAudioRecorder %@", error);
        return nil;
    }
    self.recorder.meteringEnabled = YES;
    [self.recorder setDelegate:self];
//    [self.recorder prepareToRecord];
    [self.recorder record];
    //[self.recorder recordForDuration:(NSTimeInterval) 10]
    
    [self.recordButton setTitle:@"録音終了" forState:UIControlStateNormal];
    self.isRecording = YES;

    return recordedTmpFile;
}

-(void)stopRecording {
    [self.recordButton setTitle:@"録音開始" forState:UIControlStateNormal];
    [self.recorder stop];
    self.isRecording = NO;
}

-(IBAction)donePushed:(id)sender {
    if (self.isRecording) {
        [self stopRecording];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)recordPushed:(id)sender {
    if (self.isRecording) {
        [self stopRecording];
    } else {
        self.lastRecordedFile = [self startRecording];
    }
}

#pragma mark - AVAudioRecorderDelegate

//- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
//    
//}

@end
