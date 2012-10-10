//
//  APiCloudSoundDocument.h
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/10/10.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol APiCloudSoundDocumentDelegate;

@interface APiCloudSoundDocument : UIDocument

@property (copy, nonatomic) NSData * soundData;
@property (weak, nonatomic) id<APiCloudSoundDocumentDelegate> delegate;

@end

@protocol APiCloudSoundDocumentDelegate <NSObject>

- (void) documentContentsDidChange:(APiCloudSoundDocument *) soundDocument;

@end
