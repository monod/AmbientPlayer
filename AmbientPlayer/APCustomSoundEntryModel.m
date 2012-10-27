//
//  APCustomSoundEntryModel.m
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/10/27.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import "APCustomSoundEntryModel.h"


@implementation APCustomSoundEntryModel

@dynamic sound_file;
@dynamic image_file;
@dynamic latitude;
@dynamic longitude;
@dynamic name;

- (BOOL) soundRecorded
{
    if (self.sound_file != nil) {
        return YES;
    } else {
        return NO;
    }
}

@end
