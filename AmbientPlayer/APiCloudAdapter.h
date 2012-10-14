//
//  APICloudAdapter.h
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/10/10.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APiCloudAdapter : NSObject
+ (APiCloudAdapter *) sharedAdapter;
+ (void) prepareiCloudAccess;
+ (BOOL) isiCloudAvailable;
+ (NSString *) iCloudDocumentDirectory;
+ (void) uploadLocalFileToiCloud:(NSURL*) localFileURL;
@end
