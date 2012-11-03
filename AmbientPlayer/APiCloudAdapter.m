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

//このメソッドを呼ぶ前に、少なくとも一回はprepareiCloudAccessが呼ばれている必要がある。
//呼ばれていなかった場合処理が遅くなるが、動作はする。
+ (BOOL)isiCloudAvailable {
    return ([[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] != nil);
}

+ (NSString*) iCloudDocumentDirectory {
    return @"Documents";
}

+ (void) moveLocalFileToiCloud:(NSURL*) localFileURL {
    [APiCloudAdapter updateLocalFileInfoWithiCloud:YES localFileURL:localFileURL];
}

+ (void) copyLocalFileToiCloud:(NSURL *)localFileURL {
    //まずは、localFileURLのファイルをTEMPORARYフォルダに移動
    
    if ([APiCloudAdapter isiCloudAvailable]){
        NSURL *tmpFileURL = [APiCloudAdapter copyLocalFileToTemporaryDirectory:localFileURL];
        if (tmpFileURL) {
            //TMPフォルダのファイルをicloudにmoveする
            [APiCloudAdapter moveLocalFileToiCloud:tmpFileURL];
        }
    }
    
}

+ (NSURL *) copyLocalFileToTemporaryDirectory:(NSURL *)localFileURL {
    if (!localFileURL) {
        return nil;
    }
    NSString * fileName = localFileURL.lastPathComponent;
    NSURL *baseURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *tempFileURL = [baseURL URLByAppendingPathComponent:fileName];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError* error = nil;
    if ([fm copyItemAtURL:localFileURL toURL:tempFileURL error:&error]) {
        return tempFileURL;
    }
    if (error) {
        NSLog(@"%@", error);
    }
    
    return nil;
}

+ (void) removeCorrespondingFileFromiCloud:(NSURL*) localFileURL {
    
    if ([APiCloudAdapter isiCloudAvailable]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *iCloudDocumentURL = [APiCloudAdapter buildCorrespoindingiCloudFileURL:localFileURL];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSError* error = nil;
            [fm removeItemAtURL:iCloudDocumentURL error:&error];
            
            if (error) {
                NSLog(@"%@", error);
            }
        });
    }
}

//YES のときは、ローカルからiCloudへ、NOのときは、iCloudからローカルへ
+ (void) updateLocalFileInfoWithiCloud:(BOOL)flg localFileURL:(NSURL*)localFileURL {
    //iCloudが使えるかどうかを判定する処理
    if ([APiCloudAdapter isiCloudAvailable]){
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *iCloudDocumentURL = [APiCloudAdapter buildCorrespoindingiCloudFileURL:localFileURL];
                
            NSFileManager *fm = [NSFileManager defaultManager];
            NSError* error = nil;
            [fm setUbiquitous:flg itemAtURL:localFileURL destinationURL:iCloudDocumentURL error:&error];
                
        });
    }
    
}

+ (NSURL *) buildCorrespoindingiCloudFileURL:(NSURL*) localFileURL {
    NSString* fileName = localFileURL.lastPathComponent;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *iCloudDocumentURL = [fm URLForUbiquityContainerIdentifier:nil];
    iCloudDocumentURL = [iCloudDocumentURL
                         URLByAppendingPathComponent:[APiCloudAdapter iCloudDocumentDirectory]
                         isDirectory:YES];
    iCloudDocumentURL =[iCloudDocumentURL URLByAppendingPathComponent:fileName];
    NSLog(@"[iCloud URL] %@", iCloudDocumentURL);
    
    return iCloudDocumentURL;
}
@end
