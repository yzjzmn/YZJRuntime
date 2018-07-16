//
//  NSMutableArray+Safe.m
//  parkplus
//
//  Created by zhidao on 2017/5/8.
//  Copyright © 2017年 zhikun. All rights reserved.
//

#import "NSMutableArray+Safe.h"
#import "NSObject+Swizzled.h"

@implementation NSMutableArray (Safe)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id obj = [[self alloc] init];
        [obj swizzleMethod:@selector(addObject:) withMethod:@selector(safeAddObject:)];        
        [obj swizzleMethod:@selector(objectAtIndex:) withMethod:@selector(safeObjectAtIndex:)];
        [obj swizzleMethod:@selector(removeObjectAtIndex:) withMethod:@selector(safeRemoveObjectAtIndex:)];
    });
}

- (void)safeAddObject:(id)anObject
{
    if (anObject) {
        [self safeAddObject:anObject];
    }else{
        NSAssert(anObject != nil, @"safeAddObject obj is nil");
    }
}

- (id)safeObjectAtIndex:(NSInteger)index
{
    if(index<[self count]){
        return [self safeObjectAtIndex:index];
    }else{
        NSAssert(index < [self count], @"safeObjectAtIndex index is Out of bounds");
    }
    return nil;
}

- (void)safeRemoveObjectAtIndex:(NSInteger)index
{
    if(index < [self count]){
        return [self safeRemoveObjectAtIndex:index];
    }else{
        NSAssert(index < [self count], @"safeRemoveObjectAtIndex index is Out of bounds");
    }
}

@end
