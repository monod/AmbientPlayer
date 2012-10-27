//
//  APRecordViewController.h
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/09/08.
//  Copyright (c) 2012 Veronica Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "APLevelMeterView.h"
#import "APWaveFormView.h"
#import "APAppDelegate.h"
#import "APCustomSoundEntryModel.h"

@interface APRecordViewController : UIViewController<UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate> {
    CADisplayLink *_updateTimer;
    NSDateFormatter *_formatter;
    NSTimeInterval _duration;
}

-(IBAction)donePushed:(id)sender;
-(IBAction)recordPushed:(id)sender;
-(IBAction)thumbPickButtonPressed:(id)sender;
-(IBAction)locSaveButtonPressed:(id)sender;
- (IBAction)closeKeybord:(id)sender;

@property (nonatomic, strong) NSDate *sessionTime;

@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, strong) IBOutlet APLevelMeterView *levelMeter;
@property (nonatomic, strong) IBOutlet APWaveFormView *waveForm;
@property (nonatomic, strong) IBOutlet UILabel *elapsedTime;
@property (nonatomic, strong) IBOutlet UILabel *maxTime;

@property (nonatomic, strong) IBOutlet UIButton *thumbPickButton;
@property (nonatomic, strong) IBOutlet UIButton *locSaveButton;
@property (weak, nonatomic) IBOutlet UITextField *soundTitle;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) APCustomSoundEntryModel *addingSoundEntry;

@end
