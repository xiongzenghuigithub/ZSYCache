//
//  ZSYCache.m
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/10.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#import "ZSYCache.h"
#import "ZSYCacheHeader.h"
#import "ZSYCacheQueue.h"
#import "ZSYCacheObject.h"
#import "NSDictionary+ObjectiveSugar.h"

static NSString *const ZSYCACHE_DEFAULT_CACHE_NAME      = @"ZSYDefaultCache";
static NSString *const ZSYCACHE_DEFAULT_QUEUE_NAME      = @"ZSYDefaultCacheQueue";
static NSString *const ZSYCACHE_DEFAULT_POOL_NAME       = @"ZSYDefaultCachePool";

@interface ZSYCache ()

@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSMutableDictionary *queues;
@property (nonatomic, strong, readwrite) NSMutableDictionary *pools;
@property (nonatomic, strong, readwrite) NSMutableDictionary *options;
@property (nonatomic, strong, readwrite) ZSYCacheHolder *holder;
@property (nonatomic, assign) BOOL isLoaded;

@end

@implementation ZSYCache

+ (instancetype)sharedCache {
    static ZSYCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[ZSYCache alloc] init];
        if (cache.isLoaded) {
            [cache load];
        }
    });
    return cache;
}

//默认的Cache实例化
- (instancetype)init {
    self = [super init];
    if (self) {
        _name = ZSYCACHE_DEFAULT_CACHE_NAME;
        _queues = [NSMutableDictionary dictionary];
        _pools = [NSMutableDictionary dictionary];
        _options = [NSMutableDictionary dictionary];
        _holder = [[ZSYCacheHolder alloc] initWithIdentifier:_name];
        [self addQueue:nil Size:0];
        [self addPool:nil Size:0];
    }
    return self;
}

//指定名字的Cache实例化
- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        _name = [identifier copy];
        _pools = [NSMutableDictionary dictionary];
        _queues = [NSMutableDictionary dictionary];
        _options = [NSMutableDictionary dictionary];
        _holder = [[ZSYCacheHolder alloc] initWithIdentifier:_name];
        [self addQueue:nil Size:0];
        [self addPool:nil Size:0];
    }
    return self;
}

- (void)addQueue:(NSString *)queueName Size:(NSInteger)size  {
    if (!queueName || [queueName isEqualToString:@""]) {
        queueName = ZSYCACHE_DEFAULT_QUEUE_NAME;
    }
    if ([self.queues hasKey:queueName]) {
        return;
    }
    ZSYCacheQueue *queue = [[ZSYCacheQueue alloc] initWithHolder:_holder];
    queue.name  = queueName;
    if (size > 0) {
        queue.size = size;
    }
    [self.queues setObject:queue forKey:queueName];
}

- (void)addPool:(NSString *)poolName Size:(NSInteger)size {
    if (!poolName || [poolName isEqualToString:@""]) {
        poolName = ZSYCACHE_DEFAULT_POOL_NAME;
    }
    if ([self.pools hasKey:poolName]) {
        return;
    }
    //实例化Pool
    //...
}

- (void)zsyPushObject:(id)obj ToQueue:(NSString *)queueName {
    if (!queueName || [queueName isEqualToString:@""]) {
        queueName = ZSYCACHE_DEFAULT_QUEUE_NAME;
    }
    ZSYCacheQueue *queue = self.queues[queueName];
    [queue zsyPushObj:obj];
}

- (id)zsyPopFromQueue:(NSString *)queueName {
    if (!queueName || [queueName isEqualToString:@""]) {
        queueName = ZSYCACHE_DEFAULT_QUEUE_NAME;
    }
    ZSYCacheQueue *queue = self.queues[queueName];
    id pop = [queue zsyPopObj];
    return pop;
}

- (NSArray *)objectsInQueue:(NSString *)queueName {
    if (!queueName || [queueName isEqualToString:@""]) {
        queueName = ZSYCACHE_DEFAULT_QUEUE_NAME;
    }
    ZSYCacheQueue *queue = self.queues[queueName];
    NSMutableArray *cacheList = [NSMutableArray array];
    for (int i = 0; i < [queue.keysQueue count]; i++) {
        NSString *key = queue.keysQueue[i];
        ZSYCacheObject *cacheObj = [_holder zsyGetObjectForKey:key];
        if (cacheObj.cacheObjectValue) {
            [cacheList addObject:cacheObj.cacheObjectValue];
        }
    }
    return cacheList;
}

- (void)save {
    
}

- (void)load {
    
}

+ (void)save {
    
}

+ (void)load {
    
}

- (NSInteger)memorySize {
    return self.holder.size;
}

@end
