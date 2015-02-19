#import "EJFontCache.h"

// An instance of EJFontCacheKey fully describes an internal Font in Ejecta:
// - descriptor (name and size)
// - solid or outlined
// - line width
// - content scale

@interface EJFontCacheKey : NSObject <NSCopying> {
	EJFontDescriptor *descriptor;
	float lineWidth;
	int normalizedContentScale;
	NSUInteger hash;
}

+ keyWithDescriptor:(EJFontDescriptor *)descriptor lineWidth:(float)lineWidth contentScale:(float)contentScale;

@property (readonly) int normalizedContentScale;

@end

static float kEJFontCacheKeyLineWidthNoneFilled = -1;

@implementation EJFontCacheKey
@synthesize normalizedContentScale;

+ (id)keyWithDescriptor:(EJFontDescriptor *)descriptor lineWidth:(float)lineWidth contentScale:(float)contentScale {

	// Find the next power of two for the normalized content scale
	int scale = 1;
	while(scale < contentScale && scale < EJ_FONT_CACHE_MAX_CONTENT_SCALE) {
		scale *= 2;
	}
	
	EJFontCacheKey *key = [[EJFontCacheKey alloc] init];
	key->descriptor = [descriptor retain];
	key->normalizedContentScale = scale;
	key->lineWidth = lineWidth;
	key->hash = [descriptor hash] + (scale * 673) + (int)(lineWidth * 487);
	
	return [key autorelease];
}

- (void)dealloc {
	[descriptor release];
	[super dealloc];
}

- (NSUInteger)hash {
	return hash;
}

- (BOOL)isEqual:(id)anObject {
	if( ![anObject isKindOfClass:[EJFontCacheKey class]] ) {
		return NO;
	}
	
	EJFontCacheKey *otherKey = (EJFontCacheKey *)anObject;
	return (
		otherKey->normalizedContentScale == normalizedContentScale &&
		otherKey->lineWidth == lineWidth &&
		[otherKey->descriptor isEqual:descriptor]
	);
}

- (id)copyWithZone:(NSZone *)zone {
	EJFontCacheKey *keyCopy = [[EJFontCacheKey allocWithZone:zone] init];
	keyCopy->descriptor = [descriptor retain];
	keyCopy->normalizedContentScale = normalizedContentScale;
	keyCopy->lineWidth = lineWidth;
	keyCopy->hash = hash;
	return keyCopy;
}

@end





@implementation EJFontCache

static EJFontCache *fontCache;

+ (EJFontCache *)instance {
	if( !fontCache ) {
		fontCache = [[[EJFontCache alloc] init] autorelease];
	}
    return fontCache;
}

- (id)init {
	if( self = [super init] ) {
		fonts = [NSMutableDictionary new];
		[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(didReceiveMemoryWarning)
			name:UIApplicationDidReceiveMemoryWarningNotification
			object:nil];
	}
	return self;
}

- (void)dealloc {
	fontCache = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[fonts release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
    [self clear];
}

- (void)clear {
	[fonts removeAllObjects];
}

- (EJFont *)fontWithDescriptor:(EJFontDescriptor *)desc contentScale:(float)contentScale {
	EJFontCacheKey *key = [EJFontCacheKey keyWithDescriptor:desc
		lineWidth:kEJFontCacheKeyLineWidthNoneFilled contentScale:contentScale];
	
	EJFont *font = fonts[key];
	if( !font ) {
		font = [[EJFont alloc] initWithDescriptor:desc fill:YES lineWidth:0 contentScale:key.normalizedContentScale];
		fonts[key] = font;
		[font autorelease];
	}
	return font;
}

- (EJFont *)outlineFontWithDescriptor:(EJFontDescriptor *)desc lineWidth:(float)lineWidth contentScale:(float)contentScale {
	EJFontCacheKey *key = [EJFontCacheKey keyWithDescriptor:desc
		lineWidth:lineWidth contentScale:contentScale];
	
	EJFont *font = fonts[key];
	if( !font ) {
		font = [[EJFont alloc] initWithDescriptor:desc fill:NO lineWidth:lineWidth contentScale:key.normalizedContentScale];
		fonts[key] = font;
		[font autorelease];
	}
	return font;
}

@end
