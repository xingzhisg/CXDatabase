//
//  CXDatabase.m
//  CXDatabase
//
//  Created by Xingzhi Cheng on 12/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CXDatabase.h"

#import <objc/runtime.h>
#import <objc/message.h>

#import "NSObject+CXDatabase.h"
#import "CXDataTable.h"

@interface CXDatabase ()
@property(nonatomic, retain) NSMutableDictionary * tableDict;

@end

@implementation CXDatabase
@synthesize tableDict = _tableDict;

- (void) dealloc {
    self.tableDict = nil;
    [super dealloc];
}

- (id)initWithPath:(NSString*)aPath {
    self = [super initWithPath:aPath];
    if (self != nil) {
        self.tableDict = [NSMutableDictionary dictionary];
        
        if (![self open]) {
            NSLog(@"could not open the database field %@", aPath);
        }
    }
    return self;
}


- (CXDataTable *) tableForObject:(id)obj {    
    return [self tableForClass:[obj class]];
}

- (CXDataTable *) tableForClass:(Class)cls {

    if (![self open]) return nil;

    // by default we use the class name as the table name - but allow class-customized value;
    // for example subclasses may still wish to use the base_type object's table name;
    // However the class returns nil, we turn back to the default value - the class name;

    NSString * tableName = [cls cxTableName];   
    if ([tableName length] == 0)                  
        tableName = [NSString stringWithUTF8String:class_getName(cls)];
    
    // get the table corresponding to the class
    
    CXDataTable * table = [self.tableDict objectForKey:tableName];
    if (table == nil) {
        table = [CXDataTable tableWithManagedObject:cls inDatabase:self];
        [self.tableDict setObject:table forKey:tableName];
    }
    return table;
}

@end
