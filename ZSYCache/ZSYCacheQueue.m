//
//  ZSYCacheQueue.m
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/10.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#import "ZSYCacheQueue.h"
#import "ZSYCacheHeader.h"
#import "ZSYCacheHolder.h"
#import "ZSYCacheTool.h"

@interface ZSYCacheQueue ()

@property (nonatomic, strong, readwrite) NSMutableArray *keysQueue;
@property (nonatomic, strong, readwrite) ZSYCacheHolder *holder;
@property (nonatomic, assign, readwrite) NSInteger offset;

@end

@implementation ZSYCacheQueue

- (void)dealloc {
    [self _clearCompeltionBlocks];
}

- (instancetype)initWithHolder:(ZSYCacheHolder *)holder {
    self = [super init];
    if (self) {
        _holder = holder;
        _size = ZSYCACHE_DEFAULT_QUEUE_SIZE;
        _offset = 0;
        _keysQueue = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name Size:(NSInteger)size {
    self = [super init];
    if (self) {
        _name = name;
        _size = size;
        _offset = 0;
        _keysQueue = [NSMutableArray array];
    }
    return self;
}

- (void)zsyPushObj:(id)obj {
    self.offset++;
    [self _cleanExpirateObjects];
    
    NSString *key = [NSString stringWithFormat:@"QUEUE_%@_%ld", self.name, self.offset];
    [_holder zsySetObject:obj ForKey:key Duration:0];
    
    if (_keysQueue.count >= _size) {
        NSString *popKey = _keysQueue.firstObject;
        ZSYCacheObject *cachedObject = [_holder zsyGetObjectForKey:key];
        if (_onPop) {
            _onPop([cachedObject cacheObjectValue]);
        }
        [_holder zsyRemoveObjectForKey:popKey];//本地移除
        [_keysQueue removeObject:popKey];//内存key数组移除
    }
    [_keysQueue addObject:key];
}

- (id)zsyPopObj {
    if (_keysQueue.count < 1) {
        return nil;
    }
    NSString *firstKey = _keysQueue.firstObject;
    ZSYCacheObject *cacheObject = [_holder zsyGetObjectForKey:firstKey];
    [_keysQueue removeObject:firstKey];
    [_holder zsyRemoveObjectForKey:firstKey];
    return [cacheObject cacheObjectValue];
}

#pragma mark - private

- (void)_cleanExpirateObjects {
    if (_keysQueue.count < 1) {
        return;
    }
    
    for (int i = 0; i < (_keysQueue.count - 1); i++) {//count-1，是因为最后加入的时刚入队的，肯定不会超时
        NSString *cachedObjectKey = [_keysQueue objectAtIndex:i];
        ZSYCacheObject *cachedObject = [_holder zsyGetObjectForKey:cachedObjectKey];
        if ([cachedObject isCacheObjectExpirate]) {
            if (_onExpirate) {
                _onExpirate([cachedObject cacheObjectValue]);
            }
            [_keysQueue removeObject:cachedObjectKey];
            [_holder zsyRemoveObjectForKey:cachedObjectKey];
        }
    }
}

- (void)_clearCompeltionBlocks {
    _onPop = nil;
    _onExpirate = nil;
}

@end
