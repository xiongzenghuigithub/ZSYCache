//
//  ZSYCacheObject.h
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/13.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const ZSYCACHE_DEFAULT_EXPIRATE_TIMESTAMP_KEY;
FOUNDATION_EXPORT NSString *const ZSYCACHE_DEFAULT_DATA_KEY;

@interface ZSYCacheObject : NSObject

//指定存储NSData【返回临时创建的】
- (instancetype)initWithData:(NSData *)data;

//指定存储id对象
- (instancetype)initWithData:(id)aData Duration:(NSInteger)duration;//秒为单位

- (BOOL)isCacheObjectExpirate;
- (NSData *)cacheObjectData;
- (NSInteger)cacheObjectDataSize;
- (id)cacheObjectValue;
- (NSInteger)cacheObjectExpirateTimestamp;  //返回0，表示没有设置超时时间
- (void)updateCacheObjectLifeDuration:(NSInteger)duration;

@end
