//
//  NSObject+CXDatabase.m
//  CXDatabase
//
//  Created by Xingzhi Cheng on 12/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  property list extraction credited to orange80@stackoverflow
//  check http://stackoverflow.com/a/8380836/547214 for how to get a full list of properties for a class


#import "NSObject+CXDatabase.h"
#import <objc/runtime.h>

#import "CXDatabase.h"
#import "FMDatabaseAdditions.h"

@implementation NSObject (CXDatabase)

//////////////////////////////////////////////////
//  private: property type extraction and conversion
//////////////////////////////////////////////////

static const char * getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    //printf("attributes=%s\n", attributes);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T' && attribute[1] != '@') {
            // it's a C primitive type:
            /* 
             if you want a list of what will be returned for these primitives, search online for
             "objective-c" "Property Attribute Description Examples"
             apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.            
             */
            return (const char *)[[NSData dataWithBytes:(attribute + 1) length:strlen(attribute) - 1] bytes];
        }        
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            // it's an ObjC id type:
            return "id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@') {
            // it's another ObjC object type:
            return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
        }
    }
    return "";
}


+ (NSString*) sqliteTypeForObjcType:(NSString*)objcType defaultType:(NSString*)defaultType {
    static NSDictionary * objc2sqliteTypeMap = nil;
    
    if (objc2sqliteTypeMap == nil) {
        // NULL, INTEGER, REAL, TEXT, BLOB
        objc2sqliteTypeMap = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"INTEGER", @"c", 
                              @"INTEGER", @"i",
                              @"INTEGER", @"l", 
                              @"INTEGER", @"s", 
                              @"INTEGER", @"I", 
                              @"INTEGER", @"q",
                              @"INTEGER", @"NSDate", 
                              @"REAL", @"d", 
                              @"REAL", @"f", 
                              @"TEXT", @"NSString", 
                              @"BLOB",  @"UIImage", 
                              nil];
    }
    NSString * type = [objc2sqliteTypeMap valueForKey:objcType];
    
    if (type == nil) return defaultType;
    return type;
}

+ (NSString*) sqliteTypeForObjcType:(NSString*)objcType {
    return [self sqliteTypeForObjcType:objcType defaultType:@"BLOB"];
}

//////////////////////////////////////////////////
//  data base category - class methods
//////////////////////////////////////////////////

+ (NSDictionary *) cxManagedObjectFields {
    // by default, the object's all properties will be listed
    // to override, provide a property-name : property-type(sqlite3) map such as
    // {
    //       @"title" : "TEXT",
    //       @"image" : "BLOB",
    // }
    
    static NSDictionary * managedObjectFields = nil;
    
    if (managedObjectFields != nil) return managedObjectFields;
    
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            NSString *propertyType = [self sqliteTypeForObjcType:[NSString stringWithUTF8String:propType]];
            [results setObject:propertyType forKey:propertyName];
        }
    }
    free(properties);
    
    // returning a copy here to make sure the dictionary is immutable
    managedObjectFields = [[NSDictionary dictionaryWithDictionary:results] retain];
    
    return managedObjectFields;
}

+ (NSArray *) cxFieldNamesSorted {
    static NSArray * fields = nil;
    
    if (fields != nil) return fields;
    
    NSMutableArray * array = [NSMutableArray arrayWithArray:[[self cxManagedObjectFields] allKeys]];
    [array sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    fields = [[NSArray arrayWithArray:array] retain];
    
    return fields;
}

+ (NSString *) cxTableName {           
    // by default we use the class name;
    return [NSString stringWithUTF8String:class_getName(self)];
}

+ (NSString *) cxPrimaryKey {             
    // the primary key (unique), nil by default
    return nil;
}

+ (NSArray *) cxFieldsToBeIndexed{         
    // fields ( NSString * ) that will be indexed; nil by default
    return nil;
}

+ (NSString*) cxIndexNameForField:(NSString*)fieldName {
    return [NSString stringWithFormat:@"%@_auto_index", fieldName];
}

//////////////////////////////////////////////////
//  object builder
//////////////////////////////////////////////////

+ (id) parsedFromResultDictionary:(NSDictionary*)dictionary {
    id obj = [[self alloc] init];
    
    NSArray * keys = [[self class] cxFieldNamesSorted];
    for (NSString * key in keys) {
        
        objc_property_t property = class_getProperty([self class], [key UTF8String]);
        NSString * propertyType = [NSString stringWithUTF8String:getPropertyType(property)];
        
        NSString * sqliteType = [[self class] sqliteTypeForObjcType:propertyType];
        
        // default setter used
        // change implementation if user-defined setter was used;
        SEL s = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [[key substringToIndex:1] uppercaseString], [key substringFromIndex:1]]);
        if (![obj respondsToSelector:s]) continue;
        
        NSMethodSignature * sig = [obj methodSignatureForSelector:s];
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setSelector:s];
        
        if ([propertyType isEqualToString:@"NSDate"]) {
            id v = [dictionary objectForKey:key];
            if ([v isEqual:[NSNull null]]) continue;
            NSDate * date = [NSDate dateWithTimeIntervalSince1970:[v doubleValue]];
            [invocation setArgument:&date atIndex:2];
        }
        else if ([sqliteType isEqualToString:@"BLOB"] || [sqliteType isEqualToString:@"TEXT"]) {
            id v = [dictionary objectForKey:key];
            if ([v isEqual:[NSNull null]]) continue;
            [invocation setArgument:([v isEqual:[NSNull null]] ? nil : &v) atIndex:2];
        }
        else if ([sqliteType isEqualToString:@"INTEGER"]) {
            long long v = [[dictionary objectForKey:key] longLongValue];
            [invocation setArgument:&v atIndex:2];
        }
        else if ([sqliteType isEqualToString:@"REAL"]) {
            //NSString * t = [NSString stringWithUTF8String:[[dictionary objectForKey:key] objCType]];
            
            NSMethodSignature * sig = [self instanceMethodSignatureForSelector:NSSelectorFromString(key)];
            if ([sig methodReturnLength] == 4) {
                float v;
                v = [[dictionary objectForKey:key] floatValue];
                [invocation setArgument:&v atIndex:2];
            }
            else {
                double v = [[dictionary objectForKey:key] doubleValue];
                [invocation setArgument:&v atIndex:2];
            }
        }
        
        [invocation invokeWithTarget:obj];
    }
    
    return FMDBAutorelease(obj);
}

//////////////////////////////////////////////////
//  data base category - instance methods
//////////////////////////////////////////////////

- (BOOL) saveToDatabase:(CXDatabase*)database {
    return [[database tableForObject:self] saveObject:self];
}

- (BOOL) removeFromDatabase:(CXDatabase *)database {
    return [[database tableForObject:self] removeObject:self];
}

- (NSDictionary*) toValueDictionary {
    NSMutableDictionary * values = [NSMutableDictionary dictionary];
    
    NSArray * keys = [[self class] cxFieldNamesSorted];
    for (NSString * key in keys) {
        
        // check field type
        
        objc_property_t property = class_getProperty([self class], [key UTF8String]);
        NSString * propertyType = [NSString stringWithUTF8String:getPropertyType(property)];
        
        NSString * sqliteType = [[self class] sqliteTypeForObjcType:propertyType];
        
        // invoke the property getter (default);
        // if user-defined getter is used - modify for implementation
        
        SEL s = NSSelectorFromString(key);
        NSMethodSignature * sig = [self methodSignatureForSelector:s];
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setSelector:s];
        [invocation invokeWithTarget:self];
        
        if ([sqliteType isEqualToString:@"BLOB"] || [sqliteType isEqualToString:@"TEXT"] || [propertyType isEqualToString:@"NSDate"]) {
            id result;
            [invocation getReturnValue:&result];
            
            [values setObject:(result ? result : [NSNull null]) forKey:key];
        }
        else if ([sqliteType isEqualToString:@"INTEGER"]) {
            long long k = 0;
            [invocation getReturnValue:&k];
            NSNumber * num = [NSNumber numberWithLongLong:k];
            [values setObject:num forKey:key];
        }
        else if ([sqliteType isEqualToString:@"REAL"]) {
            int length = [sig methodReturnLength];
            if (length == 4) {
                float f;
                [invocation getReturnValue:&f];
                NSNumber * num = [NSNumber numberWithFloat:f];
                [values setObject:num forKey:key];
            } else {
                double f;
                [invocation getReturnValue:&f];
                NSNumber * num = [NSNumber numberWithDouble:f];
                [values setObject:num forKey:key];
            }
        }
    }
    return values;
}

+ (FMResultSet*) find:(id)query inDatabase:(CXDatabase*)database{
    
    if ([query isKindOfClass:[NSDictionary class]])
        return [[database tableForClass:self] find:query];    
    else if ([query isKindOfClass:[NSString class]])
        return [[database tableForClass:self] findByCriteria:query];
    
    NSAssert([query isKindOfClass:[NSDictionary class]] || [query isKindOfClass:[NSString class]], @" the only supported format of query is using dictionary or query string");
    
    return nil;
}

+ (id) findOne:(id)query inDatabase:(CXDatabase*)database {
    FMResultSet * rs = [self find:query inDatabase:database];
    
    if ([rs next]) {
        NSDictionary * dict = [rs resultDictionary];
        
        return [self parsedFromResultDictionary:dict];
    }
    return nil;
}

+ (int) rowCountInDatabase:(CXDatabase*)database {
    NSString * q = [NSString stringWithFormat:@"select count(*) from %@", [self cxTableName]];
    int count = [database intForQuery:q];
    
    return count;
}

@end
