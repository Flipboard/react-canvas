#import <Foundation/Foundation.h>

@interface EJAppViewController : UIViewController {
	BOOL landscapeMode;
	NSString *path;
}

- (id)initWithScriptAtPath:(NSString *)pathp;

@end
