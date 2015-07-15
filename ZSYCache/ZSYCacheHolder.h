//
//  ZSYCacheHolder.h
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/13.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZSYCacheObject.h"

@interface ZSYCacheHolder : NSObject

@property (nonatomic, assign, readonly)  NSInteger memorySize;
@property (nonatomic, strong, readonly)  NSMutableDictionary *objects;
@property (nonatomic, strong, readonly)  NSMutableArray *keys;


- (instancetype)initWithIdentifier:(NSString *)identifier;

- (void)zsySetObject:(id)object ForKey:(NSString *)key;
- (void)zsySetObject:(id)object ForKey:(NSString *)key Duration:(NSInteger)duration;
- (ZSYCacheObject *)zsyGetObjectForKey:(NSString *)key;
- (void)zsyRemoveObjectForKey:(NSString *)key;



@end
