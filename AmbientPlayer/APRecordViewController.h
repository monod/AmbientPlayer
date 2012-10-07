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

@interface APRecordViewController : UIViewController {
    CADisplayLink *_updateTimer;
    NSDateFormatter *_formatter;
    NSTimeInterval _duration;
}

-(IBAction)donePushed:(id)sender;
-(IBAction)recordPushed:(id)sender;

@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, strong) IBOutlet APLevelMeterView *levelMeter;
@property (nonatomic, strong) IBOutlet APWaveFormView *waveForm;
@property (nonatomic, strong) IBOutlet UILabel *elapsedTime;
@property (nonatomic, strong) IBOutlet UILabel *maxTime;
@end
