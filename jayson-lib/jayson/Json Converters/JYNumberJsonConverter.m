//
//  JYNumberJsonConverter.m
//  jayson-lib
//
//  Created by Hugo Crochetière on 2015-05-06.
//  Copyright (c) 2015 ldom66. All rights reserved.
//

#import "JYNumberJsonConverter.h"

@implementation JYNumberJsonConverter

NSString *const regex = @"^-?(0|[1-9]\\d*)(\\.\\d+)?([eE][+-]?\\d+)?$";

- (instancetype)initWithSerializer:(JYJsonSerializer *)serializer {
    if (self = [super init]) {
        self.jsonSerializer = serializer;
        return self;
    }
    return nil;
}

- (id)serialize:(id)obj errors:(NSArray **)errors {
    return obj;
}

- (id)deserialize:(NSString *)string errors:(NSArray **)errors {
    return [self deserialize:string withClass:[NSNumber class] errors:errors];
}

- (id)deserialize:(NSString *)string withClass:(Class)objectClass errors:(NSArray **)errors {
    if ([string isEqual:@"null"])
        return nil;
    if ([string isEqualToString:@"true"])
        return @YES;
    if ([string isEqualToString:@"false"])
        return @NO;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterNoStyle;
    return [formatter numberFromString:string];
}

- (id)deserializeArray:(NSString *)string withClass:(Class)objectClass errors:(NSArray **)errors {
    return nil;
}

- (id)deserializeDictionary:(NSString *)string withClass:(Class)objectClass errors:(NSArray **)errors {
    return nil;
}

- (BOOL)canConvert:(Class)objectClass errors:(NSArray **)errors {
    return [objectClass isSubclassOfClass:[NSNumber class]];
}

- (BOOL)canConvertJson:(NSString *)string errors:(NSArray **)errors {
    if ([string isEqualToString:@"true"] || [string isEqualToString:@"false"])
        return YES;
    NSPredicate *match = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [match evaluateWithObject:string];
}

@end
