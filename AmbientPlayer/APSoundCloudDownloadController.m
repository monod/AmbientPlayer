//
//  APSoundCloudDownloadController.m
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2013/12/03.
//  Copyright (c) 2013年 Veronica Software. All rights reserved.
//

#import "APSoundCloudDownloadController.h"

@interface APSoundCloudDownloadController ()

@end

@implementation APSoundCloudDownloadController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelBtnPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneBtnPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
