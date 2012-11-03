//
//  APSoundCellBackView.h
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/10/08.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APSoundCellBackView : UIView

@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UIButton *doneButton;
@property (nonatomic, weak) IBOutlet UIButton *deleteButton;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;
@property (nonatomic, weak) IBOutlet UITextView *description;

@end
