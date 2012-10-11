//
//  APICloudAdapter.m
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/10/10.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import "APiCloudAdapter.h"

@implementation APiCloudAdapter

+ (APiCloudAdapter*)sharedAdapter {
    static APiCloudAdapter* sharedAdapter_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAdapter_ = [[APiCloudAdapter alloc] init];
    });
    
    return sharedAdapter_;
}

+ (void) prepareiCloudAccess {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] != nil)
            NSLog(@"iCloud is available\n");
        else
            NSLog(@"This application requires iCloud, but it is not available.\n");
        });
}
@end
