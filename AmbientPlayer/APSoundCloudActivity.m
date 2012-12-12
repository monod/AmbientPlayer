//
//  APSoundCloudActivity.m
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/12/11.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import "APSoundCloudActivity.h"
#import "APSoundEntry.h"
#import "SCUI.h"
#import "APCustomSoundEntryModel.h"
#import "APAppDelegate.h"

@implementation APSoundCloudActivity

- (NSString *)activityType {
    return @"SoundCloud";
}

- (NSString *)activityTitle {
    return @"SoundCloud";
}

- (UIImage *)activityImage {
    UIImage *icon = [UIImage imageNamed:@"scshareicon.png"];
    return icon;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    //NSLog(@"prepareWithActivityItems");
    NSUInteger u = [activityItems indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isMemberOfClass:[APSoundEntry class]]) {
            return YES;
        }

        return NO;
    }];

    if (u != NSNotFound) {
        self.soundEntry = [activityItems objectAtIndex:u];
    } else {
        //何もしない
    }

}

- (void)performActivity {
    NSLog(@"Do the actual share logic here");
    //activityViewControllerが呼ばれる場合は、こっちのメソッドは呼ばれない。

    [self activityDidFinish:YES];
}

- (UIViewController *)activityViewController
{
    NSLog(@"%s",__FUNCTION__);
    APSoundEntry *entry = self.soundEntry;

    NSURL *trackURL = [entry getRecordedFileURL];

    SCShareViewController *shareViewController;
    SCSharingViewControllerComletionHandler handler;

    handler = ^(NSDictionary *trackInfo, NSError *error) {
        if (SC_CANCELED(error)) {
            NSLog(@"Canceled!");
            [self activityDidFinish:NO];
        } else if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
            [self activityDidFinish:NO];
        } else {
            NSLog(@"Uploaded track: %@", trackInfo);
            NSString *soundCloudURL = [trackInfo objectForKey:@"permalink_url"];
            NSLog(@"soundCloudURL: %@", soundCloudURL);

            //ビュー用のモデル情報を更新
            [entry finishUploadingSoundCloud:soundCloudURL];

            //CoreData用のモデル情報を更新
            [APCustomSoundEntryModel finishUploadingSoundCloud:entry.moID soundCloudURL:soundCloudURL inManagedObjectContext:[APAppDelegate sharedManagedObjectContext]];

            [self activityDidFinish:YES];
        }
    };
    shareViewController = [SCShareViewController
            shareViewControllerWithFileURL:trackURL
                         completionHandler:handler];
    [shareViewController setTitle:entry.title];
    [shareViewController setPrivate:NO];
    [shareViewController setDownloadable:YES];
    [shareViewController setTags:[NSArray arrayWithObjects:@"AmbientPlayer", nil]];

    UIImage *image = [entry getRecordedImage];

    [shareViewController setCoverImage:[entry getRecordedImage]];

    return shareViewController;

}

@end
