//
//  Post.m
//  CXDatabaseDemo
//
//  Created by Xingzhi Cheng on 13/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Post.h"
#import "NSObject+CXDatabase.h"
#import <objc/runtime.h>

@implementation Post
@synthesize title, image, createDate, idx, rating, isRecommended, pageViews, price;

+ (Post*) randomPostWithID:(int)idx {
    static int c = 0;
    c++;
    
    Post * p = [[self alloc] init];
    p.title = [NSString stringWithFormat:@"title %d", idx];
    p.image = nil;
    p.createDate = [NSDate date];
    p.idx = idx;
    p.rating = (c+5686) / 1000.;
    p.isRecommended = c % 2;
    p.pageViews = (1234 + c) * 10;
    p.price = idx + c/10.;
    
    return [p autorelease];
}

+ (NSString*) cxPrimaryKey{
    return @"createDate";
}


- (void) printMethodSignatures {
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        fprintf(stdout, "%s %s\n", property_getName(property), property_getAttributes(property));
    }
    
    NSLog(@"%@", [[self class] cxManagedObjectFields]);
    
    NSLog(@"\n\n%@", [self toValueDictionary]);
}

- (NSString*) toString {
    NSString * s = [NSString stringWithFormat:@"title: %@; image: %@; create:%@ index: %d; rating: %lf; isRecommended: %d; pageViews: %lld; price: %f", self.title, self.image, self.createDate, self.idx, self.rating, self.isRecommended, self.pageViews, self.price];
    return s;
}
@end
