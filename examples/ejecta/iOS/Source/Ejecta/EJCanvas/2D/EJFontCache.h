#import <Foundation/Foundation.h>
#import "EJFont.h"

#define EJ_FONT_CACHE_MAX_CONTENT_SCALE 32


// EJFontCache is a singleton and can be shared between 2D contexts

@interface EJFontCache : NSObject {
	NSMutableDictionary *fonts;
}

+ (EJFontCache *)instance;

- (void)clear;
- (EJFont *)fontWithDescriptor:(EJFontDescriptor *)desc contentScale:(float)contentScale;
- (EJFont *)outlineFontWithDescriptor:(EJFontDescriptor *)desc lineWidth:(float)lineWidth contentScale:(float)contentScale;


@end