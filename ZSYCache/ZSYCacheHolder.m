//
//  ZSYCacheHolder.m
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/13.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#import "ZSYCacheHolder.h"
#import "ZSYCacheTool.h"
#import "ZSYCacheHeader.h"
#import "NSDictionary+ObjectiveSugar.h"

//static NSInteger LOCK_CONDITION_FREE                 = 1;
//static NSInteger LOCK_CONDITION_OPERATING            = 2;

static NSString *const ZSYCACHE_DEFAULT_HOLDER_NAME = @"ZsyCaheDefaultHolder";
static NSString *const ZSYCACHE_DEFAULT_HOLDER_FOLDER = @"ZsyCaheDefaultHolderFolder";

static NSInteger const ZSYCACHE_DEFAULT_ARCHIVER_TIME   = 10.f;
static NSInteger const ZSYCACHE_DEFAULT_CLEANING_TIME   = 10.f;

/**
 *  内存保存、本地保存
 *
 *      1. 内存保存： 直接使用传入的key，存入字典objects
 *      2. 本地保存： self.path/传入的key 作为本地文件路径
 */
@interface ZSYCacheHolder () {
    
}

@property (nonatomic, copy, readwrite) NSString *path;
@property (nonatomic, assign, readwrite)  NSInteger size;
@property (nonatomic, assign, readwrite)  BOOL isArchiving;
@property (nonatomic, strong, readwrite)  NSMutableDictionary *objects;//存储ZSYCacheObject.cacheData
@property (nonatomic, strong, readwrite)  NSMutableArray *keys;
@property (nonatomic, strong) NSConditionLock *conditionLock;
@property (nonatomic, strong) NSRecursiveLock *normalLock;
@property (nonatomic, strong) NSTimer *archiveringTimer;
@property (nonatomic, strong) NSTimer *cleaningTimer;
@property (nonatomic, strong) NSSet *runLoopModes;

//工具函数

- (void)startSchedule;

- (void)scheduleArchive;
- (void)startArchiverData;
- (void)doArchiverData;//必须多线程互斥访问
- (void)doArchiverDatas;

- (void)scheduleClean;
- (void)startCleanData;
- (void)doCleanData;//必须多线程互斥访问
- (void)doCleanDatas;
- (void)cleanExpirateObjects;

@end

@implementation ZSYCacheHolder

- (void)dealloc {
    _conditionLock = nil;
    _normalLock = nil;
    _normalLock = nil;
    [_archiveringTimer invalidate];
    _archiveringTimer = nil;
    [_cleaningTimer invalidate];
    _cleaningTimer = nil;
}

- (instancetype)init {
    self = [self initWithIdentifier:ZSYCACHE_DEFAULT_HOLDER_NAME];
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        _size = 0;
        _objects = [NSMutableDictionary dictionary];
        _keys = [NSMutableArray array];
        _isArchiving = NO;
//        _conditionLock = [[NSConditionLock alloc] initWithCondition:LOCK_CONDITION_FREE];
        _normalLock = [[NSRecursiveLock alloc] init];
        _path = [ZSYCacheTool appendPathAfterDucument:identifier];
        _runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
        [self startSchedule];
    }
    return self;
}

- (void)zsySetObject:(id)object
              ForKey:(NSString *)key
{
    [self zsySetObject:object ForKey:key Duration:0];
}

- (void)zsySetObject:(id)object
              ForKey:(NSString *)key
            Duration:(NSInteger)duration
{
    NSParameterAssert(object);
    NSParameterAssert(key);
    
    ZSYCacheObject *cacheObject = [[ZSYCacheObject alloc] initWithData:object Duration:duration];
    
    if (_isArchiving) {
        NSString *path = [self.path stringByAppendingPathComponent:key];
        [cacheObject.cacheObjectData writeToFile:path atomically:YES];
    } else {
        //如果处于 _isArchiving = YES时，会对objects保存的对象进行清理，会出现数据不同步
        [self.objects setValue:cacheObject.cacheObjectData forKey:key];
        self.size += cacheObject.cacheObjectDataSize;
    }
    
    //按照过期时间从小--》到大，重新排序keys数组
    //数组下标0++， 过期时间越来越晚
    [_normalLock lock];
    [self.keys removeObject:key];
    for (NSInteger i = (_keys.count - 1);i >= 0; i--) {
        NSString *lastKey = [_keys objectAtIndex:i];
        ZSYCacheObject *tmp = [self zsyGetObjectForKey:lastKey];
        if (tmp.cacheObjectExpirateTimestamp <= cacheObject.cacheObjectExpirateTimestamp) {
            if (i == (_keys.count - 1)) {
                [self.keys addObject:key];
            } else {
                [self.keys insertObject:key atIndex:(i+1)];
            }
            break;
        }
    }
    
    //说明当前object的过期时间最早，直接插入到数组0个位置
    if (![self.keys containsObject:key]) {
        [self.keys addObject:key];
    }
    
    [_normalLock unlock];
    
    //如果内存保存的数据超过规定大小，持久化到本地
    if ([self isShouldLoadToMemory]){
        [self doArchiverData];//注： 多线程调用方法
    }
}

- (ZSYCacheObject *)zsyGetObjectForKey:(NSString *)key {
    NSParameterAssert(key);
    ZSYCacheObject *object = [self cachedObjectForKey:key];
    
    if (!object) {
        return nil;
    }
    if (object.isCacheObjectExpirate) {
        return nil;
    }
    return object;
}

- (void)zsyRemoveObjectForKey:(NSString *)key {
    NSParameterAssert(key);
    //内存删除
    [_keys removeObject:key];
    if ([self.objects hasKey:key]) {
        [self.objects removeObjectForKey:key];
    }
    //本地删除
    NSString *path = [self.path stringByAppendingPathComponent:key];
    [ZSYCacheTool removeFileAtPath:path];
}

#pragma mark -

#pragma mark - schedule Archive Clean

- (NSThread *)archiveringThread {
    static NSThread *_archiveringThread = nil;
    static dispatch_once_t onceToken;
    __weak __typeof(self)weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        _archiveringThread = [[NSThread alloc] initWithTarget:strongSelf selector:@selector(archiveringThreadEntryPoint:) object:nil];
        [_archiveringThread start];
    });
    return _archiveringThread;
}

- (void)archiveringThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        NSThread *thread = [NSThread currentThread];
        [thread setName:@"ZSYCacheArchiveringThread"];
        NSRunLoop *loop = [NSRunLoop currentRunLoop];
        [loop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [loop run];
    }
}

- (NSThread *)cleaningThread {
    static NSThread *_cleaningThread = nil;
    static dispatch_once_t onceToken;
    __weak __typeof(self)weakSelf = self;
    dispatch_once(&onceToken, ^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        _cleaningThread = [[NSThread alloc] initWithTarget:strongSelf selector:@selector(cleaningThreadEntryPoint:) object:nil];
        [_cleaningThread start];
    });
    return _cleaningThread;
}

- (void)cleaningThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        NSThread *thread = [NSThread currentThread];
        [thread setName:@"ZSYCacheCleaningThread"];
        NSRunLoop *loop = [NSRunLoop currentRunLoop];
        [loop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [loop run];
    }
}

- (void)startSchedule {
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf scheduleArchive];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf scheduleClean];
    });
}

- (void)scheduleArchive {
    [self performSelector:@selector(startArchiverData)
                 onThread:[self archiveringThread]
               withObject:nil
            waitUntilDone:NO
                    modes:[self.runLoopModes allObjects]];
}

- (void)startArchiverData {
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    _archiveringTimer = [NSTimer timerWithTimeInterval:ZSYCACHE_DEFAULT_ARCHIVER_TIME
                                                target:self
                                              selector:@selector(doArchiverData)
                                              userInfo:nil
                                               repeats:YES];
    [runloop addTimer:_archiveringTimer forMode:NSDefaultRunLoopMode];
    while (YES) {
        [runloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2.f]];
    }
}

#pragma mark 归档
- (void)doArchiverData {
    [_normalLock lock];
    NSLog(@"...doArchiverData...\n");
    _isArchiving = YES;
    if (ZSYCACHE_ARCHIVING_THRESHOLD > 0 && \
        self.size > ZSYCACHE_ARCHIVING_THRESHOLD)
    {
        [ZSYCacheTool checkFolderAtPath:_path];
        NSMutableArray *copyKeys = [self.keys mutableCopy];//使用深拷贝一个新的
        while([copyKeys count] > 0) {
            
            if (self.size <= ZSYCACHE_ARCHIVING_THRESHOLD/2) {
                break;
            }
            
            //内存NSData归档到本地
            NSString *key = [copyKeys lastObject];//从key数组最右边，开始一个一个保存到本地，并从内存删除
            NSString *localFilePath = [self.path stringByAppendingPathComponent:key];
            NSData *cacheData = self.objects[key];
            [cacheData writeToFile:localFilePath atomically:YES];
            
            //修正内存长度
            self.size -= cacheData.length;
            [self.objects removeObjectForKey:key];
            [copyKeys removeLastObject];
        }
        _keys = copyKeys;
    }
    _isArchiving = NO;
    [_normalLock unlock];
}

- (void)doArchiverDatas {
    
}

- (void)scheduleClean {
    [self performSelector:@selector(startCleanData)
                 onThread:[self cleaningThread]
               withObject:nil
            waitUntilDone:NO
                    modes:[self.runLoopModes allObjects]];
}

- (void)startCleanData {
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    _cleaningTimer = [NSTimer timerWithTimeInterval:ZSYCACHE_DEFAULT_CLEANING_TIME
                                             target:self
                                           selector:@selector(doCleanData)
                                           userInfo:nil
                                            repeats:YES];
    [runloop addTimer:_cleaningTimer forMode:NSDefaultRunLoopMode];
    while (YES) {
        [runloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2.f]];
    }
}

#pragma mark 清除数据
- (void)doCleanData {
    NSLog(@"... doCleanData ... \n");
}

- (void)doCleanDatas {
    
}

- (void)cleanExpirateObjects {
    
}

#pragma mark Find CachedObejct
//内存或本地读取
- (ZSYCacheObject *)cachedObjectForKey:(NSString *)key {
    [_normalLock lock];
    if (![_keys containsObject:key]) {//1. 内存不存在key，读取文件data
        
        NSString *path = [self.path stringByAppendingPathComponent:key];
        if ([ZSYCacheTool checkFileAtPath:path]) {
            NSData *data = [[NSData alloc] initWithContentsOfFile:path];
            if (![self isShouldLoadToMemory]) {
                //读入内存
                self.size += data.length;
                [self.objects setValue:data forKey:key];
                //移除本地文件
                [ZSYCacheTool removeFileAtPath:path];
                [_normalLock unlock];
                return [[ZSYCacheObject alloc] initWithData:data];
            } else {
                [_normalLock unlock];
                return [[ZSYCacheObject alloc] initWithData:data];
            }
        } else {
            return nil;
        }
    } else {//2. 内存存在key，直接读取内存data
        [_normalLock unlock];
        return [[ZSYCacheObject alloc] initWithData:self.objects[key]];
    }
}

#pragma mark Is Over Max Memory Size
- (BOOL)isShouldLoadToMemory {
    BOOL flag =  (ZSYCACHE_ARCHIVING_THRESHOLD > 0 && \
                  self.size > ZSYCACHE_ARCHIVING_THRESHOLD && \
                  !_isArchiving);
    return flag;
}

@end
