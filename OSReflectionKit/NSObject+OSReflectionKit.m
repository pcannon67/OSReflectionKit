//
//  NSObject+ACReflectionKit.m
//  Karmalot
//
//  Created by Alexandre on 04/02/13.
//  Copyright (c) 2013 iAOS Software. All rights reserved.
//
// This class uses ARC

#import "NSObject+OSReflectionKit.h"
#import "AZReflection.h"

@implementation NSObject (OSReflectionKit)

#pragma mark - Instanciation Methods

+ (id) object
{
    return [[self alloc] init];
}

+ (id) objectFromDictionary:(NSDictionary *) dictionary
{
    return [self reflectionMapWithDictionary:dictionary error:nil];
}

+ (NSArray *) objectsFromDicts:(NSArray *) dicts
{
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[dicts count]];
    for (NSDictionary *dict in dicts)
    {
        id obj = [self objectFromDictionary:dict];
        
        if(obj)
            [objects addObject:obj];
    }
    
    return [objects copy];
}

#pragma mark - Class Reflection

+ (NSArray *) propertyNames
{
    NSDictionary *dic = [self classProperties];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES selector:@selector(compare:)];
    NSArray *names = [[dic allKeys] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return names;
}

+ (NSArray *) simpleTypesPropertyNames
{
    NSArray *propertyNames = [self propertyNames];
    NSMutableArray *simpleTypesPropertyNames = [NSMutableArray arrayWithCapacity:[propertyNames count]];
    
    for (NSString *propertyName in propertyNames)
    {
        Class propertyClass = [self classForProperty:propertyName];
        if([propertyClass isSubclassOfClass:[NSArray class]] || [propertyClass isSubclassOfClass:[NSDictionary class]])
        {
            // Complex property... ignoring...
        }
        else
        {
            [simpleTypesPropertyNames addObject:propertyName];
        }
    }
    return [simpleTypesPropertyNames copy];
}

+ (NSUInteger) propertyCount
{
    return [[self propertyNames] count];
}

+ (NSArray*) arrayPropertiesOfType:(Class) klass
{
    NSArray* properties = [self propertyNames];
    NSMutableArray* arrayProperties = [NSMutableArray array];
    
    for (NSString* p in properties) {
        Class pClass = [self classForProperty:p];
        if ([pClass isSubclassOfClass:klass])
            [arrayProperties addObject:p];
    }
    
    return [arrayProperties copy];
}

#pragma mark - Instance Reflection

- (NSArray *) valuesForPropertyNames:(NSArray *) propertyNames
{
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:[propertyNames count]];
    
    for(NSString *property in propertyNames)
    {
        NSObject *value = nil;

        value = [self valueForKey:property];
        
        // Sets a NSNull object case the value is nil in order to assure the same amount of items than found in the properties array
        if(value == nil)
            value = [NSNull null];
        
        [values addObject:value];
    }
    
    return [values copy];
}

- (NSDictionary *) dictionary
{
    NSArray *propertyNames = [[self class] propertyNames];
    NSDictionary *_dic = [NSDictionary dictionaryWithObjects:[self valuesForPropertyNames:propertyNames] forKeys:propertyNames];
    
    return _dic;
}

- (NSDictionary *) dictionaryForNonNilProperties
{
    NSArray *propertyNames = [[self class] propertyNames];
    NSMutableDictionary *_dic = [NSMutableDictionary dictionaryWithCapacity:[propertyNames count]];
    for (NSString *property in propertyNames)
    {
        id value = [self valueForKey:property];
        if(value)
        {
            [_dic setObject:value forKey:property];
        }
    }
    
    return [_dic copy];
}

- (NSString *) fullDescription
{
    return [[self dictionary] description];
}

#pragma mark - NSCopying implementation

- (id)copyWithZone:(NSZone *)zone
{
    id object = [[self class] objectFromDictionary:[self dictionary]];
    
    return object;
}

#pragma mark - NSCoding implementation

- (void)encodeWithCoder:(NSCoder *)coder
{
    NSDictionary *dictionary = [self dictionary];
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [coder encodeObject:obj forKey:key];
    }];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [self init];
    if (self)
    {
        NSArray *properties = [[self class] propertyNames];
        
        for (NSString *property in properties)
        {
            id value = [decoder decodeObjectForKey:property];
            if(value)
            {
                [self setValue:value forKey:property];
            }
        }
    }
    
    return self;
}

@end