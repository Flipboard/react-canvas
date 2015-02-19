#import <UIKit/UIKit.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <QuartzCore/QuartzCore.h>

@interface EAGLView : UIView

- (id)initWithFrame:(CGRect)frame contentScale:(float)contentScale retainedBacking:(BOOL)retainedBacking;

@end
