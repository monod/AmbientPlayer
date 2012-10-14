//
//  APRecordViewController.m
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/09/08.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import "APRecordViewController.h"
#import "APSoundEntry.h"
#import "APiCloudAdapter.h"

#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>

@interface APRecordViewController () <AVAudioRecorderDelegate>
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSURL *lastRecordedFile;
@end

@implementation APRecordViewController

const int kMaxRecordSeconds = 120;
const int kMinRecordSeconds = 2;
typedef enum PlayState { kPlayStateStop, kPlayStateRecording } PlayState;

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
    
    self.sessionTime = [NSDate date];
    NSURL *recordedTmpFile = [NSURL fileURLWithPath:[self createTmpFilePathWithExt:@"m4a"]];
    
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
            label = @"STOP";
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
    [self.waveForm showBoundingBox:NO];
    NSLog(@"[REC][START]");
}

- (void)stopRecording {
    [self.recorder stop];
    _state = kPlayStateStop;
    [self updateButtonLabel];
    [self.waveForm showBoundingBox:YES];
    NSLog(@"[REC][STOP]");
    
    //新規録音済ファイルをiCloudに保存する処理
    [self moveRecordedFileToiCloud];
}

- (void) moveRecordedFileToiCloud {
    NSURL* fileURL = [self.recorder.url copy];
    NSString* fileName = fileURL.lastPathComponent;

    //iCloudが使えるかどうかを判定する処理
    if ([APiCloudAdapter isiCloudAvailable]){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileManager *fm = [NSFileManager defaultManager];
            NSURL *iCloudDocumentURL = [fm URLForUbiquityContainerIdentifier:nil];
            iCloudDocumentURL = [iCloudDocumentURL
                              URLByAppendingPathComponent:[APiCloudAdapter iCloudDocumentDirectory]
                              isDirectory:YES];
            iCloudDocumentURL =[iCloudDocumentURL URLByAppendingPathComponent:fileName];
            NSLog(@"[iCloud URL] %@", iCloudDocumentURL);
            
            NSError* error = nil;
            [fm setUbiquitous:YES itemAtURL:fileURL destinationURL:iCloudDocumentURL error:&error];
            
        });
    }
    
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
            [self stopRecording];
            break;
    }
}

-(IBAction)thumbPickButtonPressed:(id)sender {
    NSLog(@"BUTTON PRESSED");
    
    UIActionSheet * sheet;
    sheet = [[UIActionSheet alloc]
             initWithTitle:@""
             delegate:self
             cancelButtonTitle:@"Cancel"
             destructiveButtonTitle:nil
             otherButtonTitles:@"Photo Library", @"Camera", nil];
    [sheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIImagePickerControllerSourceType sourceType = 0;
    switch (buttonIndex) {
        case 0:
            sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        case 1:
            sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        default:
            NSLog(@"Image picker source index out of range");
            return;
    }
    
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        NSLog(@"Image picker source unavailable");
        return; // just ignore
    }

    UIImagePickerController * thumbPicker;
    thumbPicker = [[UIImagePickerController alloc] init];
    thumbPicker.sourceType = sourceType;
    thumbPicker.allowsEditing = YES;
    thumbPicker.delegate = self;
    thumbPicker.allowsEditing = YES;
    
    [self presentViewController:thumbPicker animated:YES completion:NULL];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    for (NSObject* key in info.allKeys) { // for debugging
        NSLog(@"%@ => %@", key, [info objectForKey:key]);
    }

    UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerEditedImage];
    NSLog(@"%f, %f", image.size.width, image.size.height); // for debugging
    [self dismissViewControllerAnimated:YES completion:NULL];
    NSData *pngImage = UIImagePNGRepresentation(image);
    NSString *thumbTmpFile = [self createTmpFilePathWithExt:@"png"];
    if (![pngImage writeToFile:thumbTmpFile atomically:YES]) {
        NSLog(@"Saving a thumbnail failed"); // TODO: display an error dialog
    }
    [self.thumbPickButton setImage:image forState:UIControlStateNormal];
}

-(IBAction)locSaveButtonPressed:(id)sender {
    NSLog(@"locSaveButtonPressed: stub"); // FIXME: Implement!
}

- (NSString *)createTmpFilePathWithExt:(NSString *)ext {
    return [[APSoundEntry recordedFileDirectory] stringByAppendingPathComponent: [NSString stringWithFormat:@"%@.%@", [_formatter stringFromDate:self.sessionTime], ext]];
}


#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    _state = kPlayStateStop;
    [self updateButtonLabel];
    [self.waveForm showBoundingBox:YES];
}

@end
