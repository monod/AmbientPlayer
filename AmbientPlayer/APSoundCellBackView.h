//
//  APSoundCellBackView.h
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/10/08.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APSoundCellBackView : UIView

@property (nonatomic, strong) IBOutlet UILabel *title;
@property (nonatomic, strong) IBOutlet UILabel *description;
@property (nonatomic, strong) IBOutlet UIButton *doneButton;
@property (nonatomic, strong) IBOutlet UIButton *deleteButton;

@end
