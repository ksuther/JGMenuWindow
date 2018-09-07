//
//  NSColor+JGAdditions.m
//  Chatology
//
//  Created by Klemens Strasser on 07.09.18.
//  Copyright © 2018 Flexibits Inc. All rights reserved.
//

#import "NSColor+JGAdditions.h"

@implementation NSColor (JGAdditions)

+ (instancetype)jg_rowHighlightColor
{
    if (@available(macOS 10.14, *)) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"AppleHighlightColor"]) {
            return [NSColor controlAccentColor];
        } else {
            return [NSColor colorWithSRGBRed:.082352941 green:.537254902 blue:0.976470588 alpha:1.0];
        }
    } else {
        return [NSColor colorWithSRGBRed:.26 green:.59 blue:1.0 alpha:1.0];
    }
}

@end
