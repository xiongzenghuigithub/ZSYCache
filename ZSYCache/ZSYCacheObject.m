//
//  ZSYCacheObject.m
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/13.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#import "ZSYCacheObject.h"
#import "ZSYCacheHeader.h"
#import "ZSYCacheTool.h"
#import "NSDictionary+ObjectiveSugar.h"

NSString *const ZSYCACHE_DEFAULT_EXPIRATE_TIMESTAMP_KEY = @"zsyExpirateTimestamp";
NSString *const ZSYCACHE_DEFAULT_DATA_KEY = @"zsyCacheData";

@interface ZSYCacheObject ()

@property (nonatomic, strong) NSMutableDictionary *options;
@property (nonatomic, strong) NSData *data;

@end

@implementation ZSYCacheObject

- (instancetype)initWithData:(NSData *)aData {
    self = [super init];
    if (self) {
        _data = aData;
    }
    return self;
}

- (instancetype)initWithData:(id)aData Duration:(NSInteger)duration {
    NSParameterAssert(aData);
    self = [super init];
    if (self) {
        duration = (duration > 0) ? duration : ZSYCACHE_DEFAULT_LIFE_DURATION;
        //获取 超时时间+当前起始时间=最终超时的时间
        NSNumber *durationNumber = @([ZSYCacheTool expirateTimestampFromNowWithDuration:duration]);
        _data = [ZSYCacheTool archiverObjectToNSData:@{
                                                       ZSYCACHE_DEFAULT_DATA_KEY:aData,
                                                       ZSYCACHE_DEFAULT_EXPIRATE_TIMESTAMP_KEY:durationNumber,
                                                       }];
    }
    return self;
}

- (NSData *)cacheObjectData {
    return _data;
}

- (NSInteger)cacheObjectDataSize {
    return _data.length;
}

- (id)cacheObjectValue {
    if (self.options) {
        self.options = [ZSYCacheTool unArchiverNSDataToObejct:self.data];
    }
    if (![self.options hasKey:ZSYCACHE_DEFAULT_DATA_KEY]) {
        return nil;
    }
        
    return _options[ZSYCACHE_DEFAULT_DATA_KEY];
}

- (BOOL)isCacheObjectExpirate {
    if (!self.options) {
        self.options = [ZSYCacheTool unArchiverNSDataToObejct:self.data];
    }
    NSInteger expirateTime = [self.options[ZSYCACHE_DEFAULT_EXPIRATE_TIMESTAMP_KEY] integerValue];
    NSInteger nowTime = [ZSYCacheTool nowTimestamp];
    if (expirateTime < nowTime) {
        NSLog(@"self.options = %@ , 已经超时\n", self.options);
        return YES;
    } else {
        return NO;
    }
}

- (NSInteger)cacheObjectExpirateTimestamp {
    if (!self.options) {
        self.options = [ZSYCacheTool unArchiverNSDataToObejct:self.data];
    }
    NSInteger duration = 0;
    if ([_options hasKey:ZSYCACHE_DEFAULT_EXPIRATE_TIMESTAMP_KEY]) {
        duration = [[_options objectForKey:ZSYCACHE_DEFAULT_EXPIRATE_TIMESTAMP_KEY] integerValue];
        return [ZSYCacheTool expirateTimestampFromNowWithDuration:duration];
    } else {
        duration = 0;
        return 0;
    }
}

- (void)updateCacheObjectLifeDuration:(NSInteger)duration {
    if (self.options) {
        self.options = [ZSYCacheTool unArchiverNSDataToObejct:self.data];
    }
    NSNumber *num = @([ZSYCacheTool expirateTimestampFromNowWithDuration:duration]);
    [_options setValue:num forKey:ZSYCACHE_DEFAULT_EXPIRATE_TIMESTAMP_KEY];
}

@end
