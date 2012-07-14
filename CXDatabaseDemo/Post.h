//
//  Post.h
//  CXDatabaseDemo
//
//  Created by Xingzhi Cheng on 13/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Post : NSObject

@property(nonatomic, retain) NSString * title;
@property(nonatomic, retain) UIImage * image;
@property(nonatomic, retain) NSDate * createDate;
@property(nonatomic, readwrite) double rating;
@property(nonatomic, readwrite) int idx;
@property(nonatomic, readwrite) BOOL isRecommended;
@property(nonatomic, readwrite) long long pageViews;
@property(nonatomic, readwrite) float price;

+ (Post*) randomPostWithID:(int)idx;

- (void) printMethodSignatures;

- (NSString*) toString;
@end
