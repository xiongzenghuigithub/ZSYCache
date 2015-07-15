//
//  ViewController.m
//  ZSYCache
//
//  Created by XiongZenghui on 15/7/14.
//  Copyright (c) 2015年 XiongZenghui. All rights reserved.
//

#import "ViewController.h"
#import "ZSYCacheHeader.h"
#import "ZSYCacheTool.h"
#import "Person.h"

@interface ViewController ()
@property (nonatomic, strong) ZSYCache *cache;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *PATH = NSHomeDirectory();
    NSLog(@"%@", PATH);
    
    _cache = [[ZSYCache alloc] initWithIdentifier:@"demoCache"];
    [_cache addQueue:@"demoCacheQueue" Size:0];//默认长度=10
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeContactAdd];
    btn.frame = CGRectMake(20, 200, 60, 40);
    [self.view addSubview:btn];
    
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)btnClick {
    Person *p = [[Person alloc] init];
    [_cache zsyPushObject:p ToQueue:@"demoCacheQueue"];
    
}

@end
