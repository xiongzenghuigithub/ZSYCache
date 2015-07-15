//
//  ZSYCacheHeader.h
//  ZSYProject
//
//  Created by XiongZenghui on 15/7/10.
//  Copyright (c) 2015年 com.cn.zsy. All rights reserved.
//

#ifndef ZSYProject_ZSYCacheHeader_h
#define ZSYProject_ZSYCacheHeader_h

#import "ZSYCache.h"

#define     ZSYCACHE_DEFAULT_POOL_SIZE     20
#define     ZSYCACHE_DEFAULT_QUEUE_SIZE    10
#define     ZSYCACHE_DEFAULT_LIFE_DURATION 864000

// 把内存归档到磁盘的阈值，单位 byte
//#define     ZSYCACHE_ARCHIVING_THRESHOLD    500000  //50M
#define     ZSYCACHE_ARCHIVING_THRESHOLD    2000

#endif
