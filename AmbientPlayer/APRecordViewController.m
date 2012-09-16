//
//  APRecordViewController.m
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/09/08.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import "APRecordViewController.h"

#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>

@interface APRecordViewController () <AVAudioRecorderDelegate>
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSURL *lastRecordedFile;
@end

@implementation APRecordViewController

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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(NSURL *)startRecording {
    NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    NSURL *recordedTmpFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"caf"]]];
    NSLog(@"Using File called: %@",recordedTmpFile);
    
    NSError *error = nil;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:&error];
    if (error) {
        NSLog(@"Failed to create AVAudioRecorder %@", error);
        return nil;
    }
    [self.recorder setDelegate:self];
    [self.recorder prepareToRecord];
    [self.recorder record];
    //[self.recorder recordForDuration:(NSTimeInterval) 10]
    return recordedTmpFile;
}

-(IBAction)donePushed:(id)sender {
    if (self.recorder.isRecording) {
        [self.recorder stop];

    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)recordPushed:(id)sender {
    if (self.recorder.isRecording) {
        [self.recordButton setTitle:@"録音開始" forState:UIControlStateNormal];
        [self.recorder stop];
    } else {
        [self.recordButton setTitle:@"録音終了" forState:UIControlStateNormal];
        self.lastRecordedFile = [self startRecording];
    }
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
}

@end
