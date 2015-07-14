//
//  NSString+ObjectiveSugar.m
//  SampleProject
//
//  Created by Neil on 05/12/2012.
//  Copyright (c) 2012 @supermarin | supermar.in. All rights reserved.
//

#import "NSString+ObjectiveSugar.h"
#import "NSArray+ObjectiveSugar.h"

static NSString *const UNDERSCORE = @"_";
static NSString *const SPACE = @" ";
static NSString *const EMPTY_STRING = @"";

NSString *NSStringWithFormat(NSString *formatString, ...) {
    va_list args;
    va_start(args, formatString);

    NSString *string = [[NSString alloc] initWithFormat:formatString arguments:args];

    va_end(args);

#if defined(__has_feature) && __has_feature(objc_arc)
    return string;
#else
    return [string autorelease];
#endif
}


@implementation NSString(Additions)

- (NSArray *)split {
    NSArray *result = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [result select:^BOOL(NSString *string) {
        return string.length > 0;
    }];
}

- (NSArray *)split:(NSString *)delimiter {
    return [self componentsSeparatedByString:delimiter];
}

- (NSString *)camelCase {
    NSString *spaced = [self stringByReplacingOccurrencesOfString:UNDERSCORE withString:SPACE];
    NSString *capitalized = [spaced capitalizedString];

    return [capitalized stringByReplacingOccurrencesOfString:SPACE withString:EMPTY_STRING];
}

- (NSString *)lowerCamelCase {
    NSString *upperCamelCase = [self camelCase];
    NSString *firstLetter = [upperCamelCase substringToIndex:1];
    return [upperCamelCase stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstLetter.lowercaseString];
}

- (BOOL)containsString:(NSString *) string {
    NSRange range = [self rangeOfString:string options:NSCaseInsensitiveSearch];
    return range.location != NSNotFound;
}

- (NSString *)strip {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)su_delete:(id)input {
        
    if ([input isKindOfClass:[NSString class]]) {
        return [self stringByReplacingOccurrencesOfString:input withString:@""];
    }
    
    if ([input conformsToProtocol:@protocol(NSFastEnumeration)]) {
        if ([input isKindOfClass:[NSDictionary class]]) input = [input allObjects];
        
        id result = [self copy];
        for (id term in input) {
            result = [result stringByReplacingOccurrencesOfString:term withString:@""];
        }
        return result;
    }
    
    return self;
}

@end
