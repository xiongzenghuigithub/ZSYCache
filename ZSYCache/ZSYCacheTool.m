//
//  ZSYCacheTool.m
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/13.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#import "ZSYCacheTool.h"

@implementation ZSYCacheTool

+ (NSInteger)nowTimestamp {
    NSInteger time = (NSInteger)ceil([[NSDate date] timeIntervalSince1970]);
    return time;
}

+ (NSInteger)expirateTimestampFromNowWithDuration:(NSInteger)duration {
    NSInteger time = [self nowTimestamp] + duration;
    return time;
}

+ (NSData *)archiverObjectToNSData:(id)object {
    NSParameterAssert(object);
    NSData *data = nil;
    data = [NSKeyedArchiver archivedDataWithRootObject:object];
    return data;
}

+ (id)unArchiverNSDataToObejct:(NSData *)data {
    NSParameterAssert(data);
    id obj = nil;
    obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return obj;
}

+ (NSString *)documentPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

+ (NSString *)appendPathAfterDucument:(NSString *)childPath {
    NSString *doc = [self documentPath];
    NSString *full = [doc stringByAppendingPathComponent:childPath];
    return full;
}

+ (void)checkFolderAtPath:(NSString *)path {
    NSParameterAssert(path);
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BOOL isDir = NO;
    BOOL isExist = [manager fileExistsAtPath:path isDirectory:&isDir];
    
    
    if (isExist) {
        if (!isDir) {
            [manager removeItemAtPath:path error:nil];
        } else {
            return;
        }
    }
    
    if (!isExist) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (BOOL)checkFileAtPath:(NSString *)path {
    NSParameterAssert(path);
    NSFileManager *manager = [NSFileManager defaultManager];
    return [manager fileExistsAtPath:path];
}

+ (void)removeFileAtPath:(NSString *)path {
    NSParameterAssert(path);
    NSFileManager *manager = [NSFileManager defaultManager];
    if([manager fileExistsAtPath:path]) {
        [manager removeItemAtPath:path error:nil];
    }
}

@end
