#import <Foundation/Foundation.h>

#import <OpenAL/al.h>
#import <OpenAL/alc.h>

@interface EJSharedOpenALManager : NSObject {
	ALCcontext *context;
	ALCdevice *device;
	NSMutableDictionary *buffers;
}

+ (EJSharedOpenALManager *)instance;
@property (readonly, nonatomic) NSMutableDictionary *buffers;

@end
