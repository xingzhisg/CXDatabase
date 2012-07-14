//
//  CXDataTable.h
//  Miu Ptt
//
//  Created by Xingzhi Cheng on 12/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CXDatabase;
@class FMResultSet;

@interface CXDataTable : NSObject

@property(nonatomic, assign) CXDatabase * database;

+ (CXDataTable*) tableWithManagedObject:(Class)cls inDatabase:(CXDatabase*)database;

- (id) initWithManagedObject:(Class)cls inDatabase:(CXDatabase*)database;

- (BOOL) saveObject:(id)obj;
- (BOOL) removeObject:(id)obj;

- (FMResultSet*) find:(NSDictionary*) dictionary;
- (FMResultSet*) findByCriteria:(NSString*) queryString;

@end
