//
//  ViewController.m
//  YZJRuntime
//
//  Created by zhidao on 2017/5/9.
//  Copyright © 2017年 yzj. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>

// 为获取class的protocol准备
@protocol AProtocol
- (void)aProtocolMethod;
@end

// 为获取class的相关信息
@interface A : NSObject {
    NSString *strA;
}
@property (nonatomic, assign) NSUInteger uintA;
@end
@implementation A
@end

// 为为class添加方法准备
void aNewMethod() {
    NSLog(@"aNewMethod");
}
void aReplaceMethod() {
    NSLog(@"aReplaceMethod");
}


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSMutableArray *dataArr = [NSMutableArray arrayWithObjects:@"AA", @"BB", @"CC", nil];
    
    //一个简单的数组越界的兼容
    [dataArr removeObjectAtIndex:10];

    [dataArr addObject:nil];

    id objc = [dataArr objectAtIndex:4];
    
    
    //研究Class类的结构
    
    // 代码
    [self exampleA];
    [self exampleB];
    [self exampleC];
    [self exampleD];
    
}

- (void)exampleA
{
    //相关使用场景1（class一些基础信息获取）:

    // 获取类名
    const char *a = class_getName([A class]);
    NSLog(@"类名:%s", a);  // a
    // 获取父类
    Class aSuper = class_getSuperclass([A class]);
    NSLog(@"%s", class_getName(aSuper));  // b
    // 判断是否是元类
    BOOL aIfMeta = class_isMetaClass([A class]);
    BOOL aMetaIfMeta = class_isMetaClass(objc_getMetaClass("A"));
    NSLog(@"%i  %i", aIfMeta, aMetaIfMeta);   // c
    // 类大小
    size_t aSize = class_getInstanceSize([A class]);
    NSLog(@"%zu", aSize);  // d
    // 获取和设置类版本号
    class_setVersion([A class], 1);
    NSLog(@"%d", class_getVersion([A class]));  // e
    // 获取工程中所有的class，包括系统class
    unsigned int count3;
    int classNum = objc_getClassList(NULL, count3);
    NSLog(@"%d", classNum);    // f
    // 获取工程中所有的class的数量
    objc_copyClassList(&count3);
    NSLog(@"%d", classNum);    // g
    Class aClass;
    // 获取name为"A"的class
    aClass = objc_getClass("A");
    NSLog(@"%s", class_getName(aClass));    // h
    // 获取name为"A"的class，比getClass少了一次检查
    aClass = objc_lookUpClass("A");
    NSLog(@"%s", class_getName(aClass));    // i
    // 获取name为"A"的class，找不到会crash
    aClass = objc_getRequiredClass("A");
    NSLog(@"%s", class_getName(aClass));    // j
    // 获取name为"A"的class元类
    Class aMetaClass = objc_getMetaClass("A");
    NSLog(@"%d", class_isMetaClass(aMetaClass));    // k
    // 查看输出日志
}

- (void)exampleB
{
    //相关使用场景2（class中的ivar和property）
    
    // 代码
    // 获取类实例成员变量，只能取到本类的，父类的访问不到
    Ivar aInstanceIvar = class_getInstanceVariable([A class], "strA");
    NSLog(@"%s", ivar_getName(aInstanceIvar));    // a
    // 获取类成员变量，相当于class_getInstanceVariable(cls->isa, name)，感觉除非给metaClass添加成员，否则不会获取到东西
    Ivar aClassIvar = class_getClassVariable([A class], "strA");
    NSLog(@"%s", ivar_getName(aClassIvar));    // b
    // 往A类添加成员变量不会成功的。因为class_addIvar不能给现有的类添加成员变量，也不能给metaClass添加成员变量，那怎么添加，且往后看
    if (class_addIvar([A class], "intA", sizeof(int), log2(sizeof(int)), @encode(int))) {
        NSLog(@"绑定成员变量成功");    // c
    }
    // 获取类中的ivar列表，count为ivar总数
    unsigned int count;
    Ivar *ivars = class_copyIvarList([A class], &count);
    NSLog(@"%i", count);    // d
    // 获取某个名为"uIntA"的属性
    objc_property_t aPro = class_getProperty([A class], "uintA");
    NSLog(@"%s", property_getName(aPro));    // e
    // 获取类的全部属性
    class_copyPropertyList([A class], &count);
    NSLog(@"%i", count);    // f
    // 创建objc_property_attribute_t，然后动态添加属性
    objc_property_attribute_t type = { "T", [[NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([NSString class])] UTF8String] }; //type
    objc_property_attribute_t ownership0 = { "C", "" }; // C = copy
    objc_property_attribute_t ownership = { "N", "" }; //N = nonatomic
    objc_property_attribute_t backingivar  = { "V", [[NSString stringWithFormat:@"_%@", @"aNewProperty"] UTF8String] };  //variable name
    objc_property_attribute_t attrs[] = { type, ownership0, ownership, backingivar };
    if(class_addProperty([A class], "aNewProperty", attrs, 4)) {
        // 只会增加属性，不会自动生成set，get方法
        NSLog(@"绑定属性成功");    // g
    }
    // 创建objc_property_attribute_t，然后替换属性
    objc_property_attribute_t typeNew = { "T", [[NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([NSString class])] UTF8String] }; //type
    objc_property_attribute_t ownership0New = { "C", "" }; // C = copy
    objc_property_attribute_t ownershipNew = { "N", "" }; //N = nonatomic
    objc_property_attribute_t backingivarNew  = { "V", [[NSString stringWithFormat:@"_%@", @"uintA"] UTF8String] };  //variable name
    objc_property_attribute_t attrsNew[] = { typeNew, ownership0New, ownershipNew, backingivarNew };
    class_replaceProperty([A class], "uintA", attrsNew, 4);
    // 这有个很大的坑。替换属性指的是替换objc_property_attribute_t，而不是替换name。如果替换的属性class里面不存在，则会动态添加这个属性
    objc_property_t pro = class_getProperty([A class], "uintA");
    NSLog(@"123456   %s", property_getAttributes(pro));    // h
    // class_getIvarLayout、class_setIvarLayout、class_getWeakIvarLayout、class_setWeakIvarLayout用来设定和获取成员变量的weak、strong。
    // 输出
}

- (void)exampleC
{
    //相关使用场景3（class中的method）
    
    
    // 代码
    // 动态添加方法
    class_addMethod([A class], @selector(aNewMethod), (IMP)aNewMethod, "v");
    // 向元类动态添加类方法
    class_addMethod(objc_getMetaClass("A"), @selector(aNewMethod), (IMP)aNewMethod, "v");
    // 获取类实例方法
    Method aMethod = class_getInstanceMethod([A class], @selector(aNewMethod));
    // 获取元类中类方法
    Method aClassMethod = class_getClassMethod([A class], @selector(aNewMethod));
    NSLog(@"%s", method_getName(aMethod));    // a
    NSLog(@"%s", method_getName(aClassMethod));    // b
    // 获取类中的method列表
    unsigned int count1;
    Method *method = class_copyMethodList([A class], &count1);
    // 多了一个方法，打印看出.cxx_destruct，只在arc下有，析构函数
    NSLog(@"%i", count1);    // c
    NSLog(@"%s", method_getName(method[2]));    // d
    // 替换方法，其实是替换IMP
    class_replaceMethod([A class], @selector(aNewMethod), (IMP)aReplaceMethod, "v");
    // 调用aNewMethod，其实是调用了aReplaceMethod
    [[A new] performSelector:@selector(aNewMethod)];    // aReplaceMethod会输出 e
    // 获取类中某个SEL的IMP
    IMP aNewMethodIMP = class_getMethodImplementation([A class], @selector(aNewMethod));
    aNewMethodIMP();    // 会调用aReplaceMethod的输出 f
    // 获取类中某个SEL的IMP
    IMP aNewMethodIMP_stret = class_getMethodImplementation_stret([A class], @selector(aNewMethod));
    aNewMethodIMP_stret();    // 会调用aReplaceMethod的输出 g
    // 判断A类中有没有一个SEL
    if(class_respondsToSelector([A class], @selector(aNewMethod))) {
        NSLog(@"存在这个方法");    // h
    }
}

- (void)exampleD
{
    //相关使用场景4（动态创建类）
    
    // 代码
    
    // 动态创建一个类和其元类
    Class aNewClass = objc_allocateClassPair([NSObject class], "aNewClass", 0);
    // 添加成员变量
    if (class_addIvar(aNewClass, "intA", sizeof(int), log2(sizeof(int)), @encode(int))) {
        NSLog(@"绑定成员变量成功");    // a
    }
    // 注册这个类，之后才能用
    objc_registerClassPair(aNewClass);
    // 销毁这个类和元类
    objc_disposeClassPair(aNewClass);
    
    // 输出
    
    // 代码
    // 添加protocol到class
    if(class_addProtocol([A class], @protocol(AProtocol))) {
        NSLog(@"绑定Protocol成功");    // a
    }
    // 查看类是不是遵循protocol
    if(class_conformsToProtocol([A class], @protocol(AProtocol))) {
        NSLog(@"A遵循AProtocol");    // b
    }
    // 获取类中的protocol
    unsigned int count2;
    Protocol *__unsafe_unretained  *aProtocol = class_copyProtocolList([A class], &count2);
    NSLog(@"%s", protocol_getName(aProtocol[0]));    // c
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
