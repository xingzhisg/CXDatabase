//
//  NSObject+CXDatabase.h
//  CXDatabase
//
//  Created by Xingzhi Cheng on 12/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CXDatabase;
@class FMResultSet;

@interface NSObject (CXDatabase)

+ (NSDictionary *) cxManagedObjectFields;  // a property-name and property-type (sqlite3) mapping, such as
                                           // {
                                           //       @"title" : "TEXT",
                                           //       @"image" : "BLOB",
                                           // }
                                           // by default, the object's all properties will be listed;

+ (NSArray *) cxFieldNamesSorted;          // a list of fields sorted alphabetically
+ (NSArray *) cxFieldsToBeIndexed;         // fields ( NSString * ) that will be indexed; default - nil;
+ (NSString*) cxIndexNameForField:(NSString*)fieldName;
+ (NSString*) cxTableName;                 // by default we use the class name; but allow customization - for example for subclasses.
+ (NSString*) cxPrimaryKey;                // the primary key (unique), default - nil;


#pragma mark Object Serialization and Deserialization;

// deserialize
+ (id) parsedFromResultDictionary:(NSDictionary*)dictionary;

// serialize
- (NSDictionary*) toValueDictionary;


#pragma mark update

// save or update
- (BOOL) saveToDatabase:(CXDatabase*)database;

// remove
- (BOOL) removeFromDatabase:(CXDatabase*)database;


#pragma mark query

+ (int) rowCountInDatabase:(CXDatabase*)database;

+ (FMResultSet*) find:(id)query inDatabase:(CXDatabase*)database;

+ (id) findOne:(id)query inDatabase:(CXDatabase*)database;

@end
