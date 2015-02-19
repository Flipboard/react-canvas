#import "EJTexture.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>


#define EJ_FONT_TEXTURE_SIZE 1024
#define EJ_FONT_GLYPH_PADDING 2


typedef struct {
	float width;
	float ascent;
	float descent;
} EJTextMetrics;

typedef struct {
	float x, y, w, h;
	unsigned short textureIndex;
	float tx, ty, tw, th;
} EJFontGlyphInfo;

typedef struct {
	unsigned short textureIndex;
	CGGlyph glyph;
	float xpos;
	EJFontGlyphInfo *info;
} EJFontGlyphLayout;



@interface EJFontDescriptor : NSObject {
	NSString *name;
	float size;
	NSUInteger hash;
}
+ (id)descriptorWithName:(NSString *)name size:(float)size;

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) float size;

@end



@interface EJFontLayout : NSObject {
	NSData *glyphLayout;
	EJTextMetrics metrics;
	NSInteger glyphCount;
}

- (id)initWithGlyphLayout:(NSData *)layoutp glyphCount:(NSInteger)count metrics:(EJTextMetrics)metrics;
@property (readonly, nonatomic) EJFontGlyphLayout *layout;
@property (readonly, nonatomic) NSInteger glyphCount;
@property (readonly, nonatomic) EJTextMetrics metrics;

@end



int EJFontGlyphLayoutSortByTextureIndex(const void *a, const void *b);

@class EJCanvasContext2D;
@interface EJFont : NSObject {
	NSMutableArray *textures;
	float txLineX, txLineY, txLineH;
	BOOL useSingleGlyphTextures;
	
	// Font preferences
	float pointSize, ascent, descent, leading, contentScale, glyphPadding;
	BOOL fill;
	float lineWidth;
	
	// Font references
	CTFontRef ctMainFont;
	CGFontRef cgMainFont;
	
	// Core text variables for line layout
	CGGlyph *glyphsBuffer;
	CGPoint *positionsBuffer;
	
	NSCache *layoutCache;
}

- (id)initWithDescriptor:(EJFontDescriptor *)desc fill:(BOOL)fillp lineWidth:(float)lineWidthp contentScale:(float)contentScalep;
+ (void)loadFontAtPath:(NSString *)path;
- (void)drawString:(NSString *)string toContext:(EJCanvasContext2D *)context x:(float)x y:(float)y;
- (EJTextMetrics)measureString:(NSString *)string forContext:(EJCanvasContext2D *)context;

@end
