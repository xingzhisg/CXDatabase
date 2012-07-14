//
//  CXDatabase.h
//  CXDatabase
//
//  Created by Xingzhi Cheng on 12/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "CXDataTable.h"
#import "NSObject+CXDatabase.h"

@class CXDataTable;

@interface CXDatabase : FMDatabase {

}

- (CXDataTable *) tableForObject:(id)obj;
- (CXDataTable *) tableForClass:(Class)cls;

@end
