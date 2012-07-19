//
//  CXDataTable.m
//  CXDatabase
//
//  Created by Xingzhi Cheng on 12/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CXDataTable.h"
#import "CXDatabase.h"
#import "NSObject+CXDatabase.h"

@interface CXDataTable ()
@property(nonatomic, retain) NSString * tableName;
@property(nonatomic, retain) NSArray * fields;
@property(nonatomic, retain) NSArray * indexFields;
@property(nonatomic, retain) NSString * primaryKey;
@property(nonatomic, assign) Class objClass;

- (void) createTableAndIndexIfNeeded;

// query commands;
- (NSString*) cmdForCreatingTableIfNotExists;
- (NSString*) cmdForCreatingIndexIfNotExists:(NSString*)fieldName;
- (NSString*) fieldStringWithParentheses;
- (NSString*) questionMarksWithParentheses;
@end


@implementation CXDataTable

@synthesize database = _database;
@synthesize tableName = _tableName;
@synthesize fields = _fields;
@synthesize indexFields = _indexFields;
@synthesize primaryKey = _primaryKey;
@synthesize objClass = _objClass;

+ (CXDataTable*) tableWithManagedObject:(Class)cls inDatabase:(CXDatabase*)database {
    return FMDBAutorelease([[self alloc] initWithManagedObject:cls inDatabase:database]);
}

- (void) dealloc {
    self.database = nil;
    self.tableName = nil;
    self.fields = nil;
    self.indexFields = nil;
    self.primaryKey = nil;
    
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (id) init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id) initWithManagedObject:(Class)cls inDatabase:(CXDatabase*)database {
    self = [super init];
    if (self != nil) {        
        NSAssert(database != nil, @"database must not be nil");
        
        self.database    = database;
        self.objClass    = cls;
        
        self.fields      = [cls cxFieldNamesSorted];
        self.tableName   = [cls cxTableName];
        self.indexFields = [cls cxFieldsToBeIndexed];
        self.primaryKey  = [cls cxPrimaryKey];
        
        NSAssert([self.fields count] > 0, @"table must contain at least 1 fields");

        [self createTableAndIndexIfNeeded];
    }
    return self;
}


- (BOOL) saveObject:(id)obj {
    if (![self.database open]) {
        NSLog(@"Cannot add object: database no opened");
        return false;   
    }
    
    NSDictionary * valueDict = [obj toValueDictionary];
    
    [self.database beginTransaction];
    
    int success = [self.database executeUpdate:[self cmdForInsertionForParameterDictionary] 
                       withParameterDictionary:valueDict];
    
    [self.database commit];
    
    return success;
}

- (BOOL) removeObject:(id)obj {
    if (![self.database open]) {
        NSLog(@"Cannot remove object: database no opened");
        return false;   
    }
    
    if ([self.primaryKey length] == 0) {
        NSLog(@"Cannot remove object: primary key is nil");
        return false;
    }
    
    NSDictionary * valueDict = [obj toValueDictionary];
    
    [self.database beginTransaction];
    
    NSString * cmd = [NSString stringWithFormat:@"delete from %@ where %@ = ?", self.tableName, self.primaryKey];
    int success = [self.database executeUpdate:cmd 
                          withArgumentsInArray:[NSArray arrayWithObject:[valueDict objectForKey:self.primaryKey]]];
    
    [self.database commit];
    
    return success;
}

- (FMResultSet*) find:(NSDictionary*)dictionary {
    FMResultSet * rs = [self.database executeQuery:[self cmdForQueryForParameterDictionary:dictionary]];
#if DEBUG
    NSLog(@"query done... %@", rs.statement);
#endif
    return rs;
}

- (FMResultSet*) findByCriteria:(NSString*) queryString {
    NSString * query = [NSString stringWithFormat:@"select * from %@ %@", self.tableName, queryString];
    FMResultSet * rs = [self.database executeQuery:query];
    return rs;
}

#pragma mark -
#pragma mark private functions


- (void) createTableAndIndexIfNeeded {
    [self.database setLogsErrors:YES];

    [self.database beginTransaction];

    [self.database executeUpdate:[self cmdForCreatingTableIfNotExists]];
    
    for (NSString * fieldName in self.indexFields ) {
        NSString * cmd = [self cmdForCreatingIndexIfNotExists:fieldName];
        [self.database executeUpdate:cmd];
    }
    
    [self.database commit];
}

- (NSString*) cmdForCreatingTableIfNotExists {
    NSDictionary * typeDict = [self.objClass cxManagedObjectFields];
    
	NSMutableString * s = [NSMutableString string];
    [s appendFormat:@"create table if not exists %@ (", self.tableName];
    
    for (NSString * field in self.fields) {
        NSString * fieldName = field;
        NSString * fieldType = [typeDict valueForKey:field];
		NSString * p = [fieldName isEqualToString:self.primaryKey] ? @" PRIMARY KEY ON CONFLICT REPLACE" : @"";
        [s appendFormat:@"%@ %@%@, ", fieldName, fieldType, p];
    }
    
    [s replaceCharactersInRange:NSMakeRange(s.length - 2, 2) withString:@")"];
    return s;
}

- (NSString*) cmdForCreatingIndexIfNotExists:(NSString*)fieldName {
    NSString * s = [NSString stringWithFormat:@"create index if not exists %@ on %@ (%@)", [self.class cxIndexNameForField:fieldName], self.tableName, fieldName];
    
    return s;
}

- (NSString*) fieldStringWithParentheses {
    NSMutableString * s = [NSMutableString string];
    [s appendFormat:@"("];
    for (NSString * field in self.fields) {
        NSString * fieldName = field;
        [s appendFormat:@"%@, ", fieldName];
    }
    if ([s hasSuffix:@", "]) [s deleteCharactersInRange:NSMakeRange(s.length - 2, 2)];
    [s appendString:@")"];
    return s;
}

- (NSString*) questionMarksWithParentheses {
    NSMutableString * s = [NSMutableString string];
    [s appendFormat:@"("];
    for (int i = 0; i < [self.fields count]; ++i) {
        [s appendString:@"?, "];
    }
    if ([s hasSuffix:@", "]) [s deleteCharactersInRange:NSMakeRange(s.length - 2, 2)];
    [s appendString:@")"];
    return s;
}

- (NSString*) colonFieldStringWithParentheses {
    NSMutableString * s = [NSMutableString string];
    [s appendFormat:@"("];
    for (NSString * field in self.fields) {
        NSString * fieldName = field;
        [s appendFormat:@":%@, ", fieldName];
    }
    if ([s hasSuffix:@", "]) [s deleteCharactersInRange:NSMakeRange(s.length - 2, 2)];
    [s appendString:@")"];
    return s;
}

- (NSString*) cmdForInsertionForArgumentArray {
    NSMutableString * s = [NSMutableString string];
	[s appendFormat:@"insert OR replace into %@ %@ values %@", self.tableName, [self fieldStringWithParentheses], [self questionMarksWithParentheses]];
    
    return s;
}

- (NSString*) cmdForInsertionForParameterDictionary {
    NSMutableString * s = [NSMutableString string];
    [s appendFormat:@"insert OR replace into %@ values %@", self.tableName, [self colonFieldStringWithParentheses]];
    return s;
}

- (NSString*) cmdForQueryForParameterDictionary:(NSDictionary*) dict {
    NSMutableString * s = [NSMutableString stringWithFormat:@"select * from %@ ", self.tableName];
    
    NSMutableString * w = [NSMutableString stringWithString:@""];
    NSArray * keys = [dict allKeys];
	if ([keys count] > 0) {
		[w appendString:@"where "];
		for (NSString* key in keys) [w appendFormat:@"%@ = %@ AND ", key, [dict valueForKey:key]];
		if ([w hasSuffix:@" AND "]) [w deleteCharactersInRange:NSMakeRange(w.length-5, 5)];
	}
    
    [s appendString:w];
    
//    NSLog(@"Query: %@", s);
    return s;
}


- (NSString*) cmdForRemove {
    NSString * cmd = [NSString stringWithFormat:@"delete from %@ where %@", self.tableName, self.primaryKey];
    return cmd;
}

@end
