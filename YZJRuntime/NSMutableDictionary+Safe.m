//
//  NSMutableDictionary+Safe.m
//  YZJRuntime
//
//  Created by zhidao on 2017/5/10.
//  Copyright © 2017年 yzj. All rights reserved.
//

#import "NSMutableDictionary+Safe.h"
#import "NSObject+Swizzled.h"

@implementation NSMutableDictionary (Safe)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id obj = [[self alloc] init];
        [obj swizzleMethod:@selector(setObject:forKey:) withMethod:@selector(safeSetObject:forKey:)];
    });
}


- (void)safeSetObject:(id)anObject forKey:(id)key
{
    if (anObject) {
        [self safeSetObject:anObject forKey:key];
    } else {
        NSAssert(anObject != nil, @"NSMutableDictionary safeSetObject obj is nil");
    }
}

@end
