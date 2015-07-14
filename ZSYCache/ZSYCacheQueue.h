//
//  ZSYCacheQueue.h
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/10.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZSYCacheHolder;

@interface ZSYCacheQueue : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, strong, readonly) NSMutableArray *keysQueue;

@property (nonatomic, copy) void (^onPop)(id popedObject);
@property (nonatomic, copy) void (^onExpirate)(id popedObject);

- (instancetype)initWithHolder:(ZSYCacheHolder *)holder;
- (instancetype)initWithName:(NSString *)name Size:(NSInteger)size;


//key入队
- (void)zsyPushObj:(id)obj;

//对象出队
- (id)zsyPopObj;


@end
