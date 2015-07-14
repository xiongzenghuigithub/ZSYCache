//
//  ZSYCacheTool.h
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/13.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZSYCacheTool : NSObject

//获取当前时间的秒数
+ (NSInteger)nowTimestamp;

//获取过期的时间
+ (NSInteger)expirateTimestampFromNowWithDuration:(NSInteger)duration;

+ (NSData *)archiverObjectToNSData:(id)object;
+ (id)unArchiverNSDataToObejct:(NSData *)data;

+ (NSString *)documentPath;
+ (NSString *)appendPathAfterDucument:(NSString *)childPath;

+ (void)checkFolderAtPath:(NSString *)path;
+ (BOOL)checkFileAtPath:(NSString *)path;
+ (void)removeFileAtPath:(NSString *)path;

@end
