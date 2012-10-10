//
//  APICloudAdapter.h
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/10/10.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APICloudAdapter : NSObject
+ (APICloudAdapter *) sharedAdapter;
+ (void) prepareiCloudAccess;
@end
