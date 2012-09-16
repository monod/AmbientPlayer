//
//  APRecordViewController.h
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/09/08.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APRecordViewController : UIViewController
-(IBAction)donePushed:(id)sender;
-(IBAction)recordPushed:(id)sender;

@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@end
