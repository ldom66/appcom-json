//
//  JYObjectJsonConverter.m
//  jayson-lib
//
//  Created by Dominic Lacaille on 2015-05-12.
//  Copyright (c) 2015 ldom66. All rights reserved.
//

#import "JYObjectJsonConverter.h"
#import <objc/runtime.h>

@implementation JYObjectJsonConverter

- (instancetype)initWithSerializer:(JYJsonSerializer *)serializer {
    if (self = [super init]) {
        self.jsonSerializer = serializer;
        return self;
    }
    return nil;
}

- (NSString *)toString:(id)obj {
    return [self.jsonSerializer.jsonFormatter serialize:obj];
}

- (id)fromString:(NSString *)string {
    // This converter should not be used for deserializing when the Class is unknown.
    return nil;
}

- (id)fromString:(NSString *)string withClass:(Class)objectClass {
    // These characters are whitespaces that we should ignore.
    char const IgnoredChars[] = {' ', '\r', '\n', '\t'};
    BOOL escaped = NO;
    BOOL isKey = YES; // True if we are currently parsing the key.
    BOOL inString = NO; // True if the character is currently part of a string.
    int arrayCounter = 0; // Deals with nested arrays.
    int objCounter = 0; // Deals with nested objects.
    id result = [[objectClass alloc] init];
    NSString *key = [NSMutableString new];
    NSMutableString *builder = [NSMutableString new];
    for (int i=1; i<[string length] - 1; i++)
    {
        // TODO: parse strings with \n
        char c = [string characterAtIndex:i];
        // If we find an unescaped " we reverse inString. We should not escape " if we are not in a string.
        if ((!inString || !escaped) && c == '\"')
            inString = !inString;
        // If we find [ or ] and we are not in a string, update array counter.
        if (!inString && (c == '[' || c == ']'))
            arrayCounter += c == '[' ? 1 : -1;
        // If we find { or } and we are not in a string, update array counter.
        if (!inString && (c == '{' || c == '}'))
            objCounter += c == '{' ? 1 : -1;
        // If we find : and we are not in a string, save the key.
        if (!inString && isKey && c == ':')
        {
            // We are not parsing the key anymore.
            isKey = NO;
            // Deserialize string key.
            key = [self.jsonSerializer deserializeObject:[NSString stringWithString:builder] withClass:[NSString class]];
            builder = [NSMutableString new];
            continue;
        }
        // Reset escaped state.
        if (escaped)
            escaped = NO;
        // Escape characters with \ before them (eg: \" or \n)
        if (inString && c == '\\')
            escaped = YES;
        // If we are not in a string, we should escape whitespaces.
        if (!inString)
        {
            for (int j=0; j<sizeof IgnoredChars; j++)
                if (IgnoredChars[j] == c)
                    continue;
        }
        // If we are not in a string, an array or a dictionary, not parsing the key and we find a comma we deserialize the string and add it as value.
        if (!inString && !isKey && arrayCounter == 0 && objCounter == 0 && c == ',')
        {
            [self setObjectProperty:result withProperty:key value:[NSString stringWithString:builder]];
            builder = [NSMutableString new];
            isKey = YES;
            // We should not add the comma to the next object.
            continue;
        }
        // We add the current character to the string.
        [builder appendFormat:@"%c", c];
    }
    // In the end we are left with a string and no comma. We should add the deserialized string to the array.
    [self setObjectProperty:result withProperty:key value:[NSString stringWithString:builder]];
    // Return the completed array.
    return result;
}

- (void)setObjectProperty:(id)object withProperty:(NSString *)propertyName value:(NSString *)json {
    unsigned int pCount;
    // Get all the object properties.
    objc_property_t *properties = class_copyPropertyList([object class], &pCount);
    for (int i=0; i<pCount; i++)
    {
        objc_property_t property = properties[i];
        // Get the property name.
        NSString *propName = [NSString stringWithUTF8String:property_getName(property)];
        if ([propName isEqualToString:propertyName])
        {
            // We found the property we need to set.
            NSString* propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
            // Get the attributes in order to get the property class.
            NSArray* splitPropertyAttributes = [propertyAttributes componentsSeparatedByString:@"\""];
            if ([splitPropertyAttributes count] >= 2)
            {
                // Parse the class string to a Class type.
                Class propClass = NSClassFromString([splitPropertyAttributes objectAtIndex:1]);
                // Deserialize with Class and set the property value.
                id newValue = [self.jsonSerializer deserializeObject:json withClass:propClass];
                [object setValue:newValue forKey:propName];
            }
        }
    }
    // Free unmanaged object properties.
    free(properties);
}

- (BOOL)canConvert:(Class)objectClass {
    return [objectClass isSubclassOfClass:[NSObject class]];
}

- (BOOL)canConvertJson:(NSString *)string {
    // This converter should not be used for deserializing when the Class is unknown.
    return false;
}

@end
