//
//  ZSYCache.h
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/10.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZSYCacheHolder.h"

@interface ZSYCache : NSObject

@property (nonatomic, copy , readonly) NSString *name;
@property (nonatomic, strong, readonly) NSMutableDictionary *queues;
@property (nonatomic, strong, readonly) NSMutableDictionary *pools;
@property (nonatomic, strong, readonly) ZSYCacheHolder *holder;

+ (instancetype)sharedCache;

- (instancetype)initWithIdentifier:(NSString *)identifier;

- (void)addQueue:(NSString *)queueName Size:(NSInteger)size;
- (void)addPool:(NSString *)poolName Size:(NSInteger)size;

- (void)zsyPushObject:(id)obj ToQueue:(NSString *)queueName;
- (id)zsyPopFromQueue:(NSString *)queueName;
- (NSArray *)objectsInQueue:(NSString *)queueName;

- (NSInteger)memorySize;

- (void)save;
- (void)load;

+ (void)save;
+ (void)load;

@end
