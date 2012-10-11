//
//  APiCloudSoundDocument.m
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/10/10.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import "APiCloudSoundDocument.h"

@implementation APiCloudSoundDocument

- (void) setSoundData:(NSData *)newSoundData {
    NSData * oldData = self.soundData;
    self.soundData = [newSoundData copy];
    
    //取り消し操作を登録する。
    [self.undoManager setActionName:@"Sound Change"];
    [self.undoManager registerUndoWithTarget:self selector:@selector(setSoundData:) object:oldData];
}

//ファイルの書き出し用メソッド。実際の書き出しは、UIDocumentクラスがやってくれるので、ここではNSDataを渡すところまで。
- (id) contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    if (!self.soundData) {
        //ない場合は、空のデータを設定する
        self.soundData = [[NSData alloc] init];
    }
    return self.soundData;
}

//ファイルの読み込みメソッド。書き出しと同じで、引数で貰ったcontentsからデータを読み込むだけ
- (BOOL) loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    if ([contents length] > 0) {
        self.soundData = contents;
    } else {
        self.soundData = [[NSData alloc] init];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:
                          @selector(documentContentsDidChange:)])
        [self.delegate documentContentsDidChange:self];
    
    return YES;
}


@end
