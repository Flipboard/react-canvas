#import "EJOpenALBuffer.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import "EJAppViewController.h"
#import "EJJavaScriptView.h"

@implementation EJOpenALBuffer
@synthesize bufferId;
@synthesize duration;

+ (id)cachedBufferWithPath:(NSString *)path {
	EJOpenALBuffer *buffer = [EJSharedOpenALManager instance].buffers[path];
	if( !buffer ) {
		buffer = [[[EJOpenALBuffer alloc] initWithPath:path] autorelease];
		[EJSharedOpenALManager instance].buffers[path] = buffer;
	}
	return buffer;
}

- (id)initWithPath:(NSString *)pathp {
	if( self = [super init] ) {
		path = [pathp retain];
		NSURL *url = [NSURL fileURLWithPath:pathp];
		void *data = [self getAudioDataWithURL:url];

		if( data ) {
			alGenBuffers( 1, &bufferId );
			alBufferData( bufferId, format, data, size, sampleRate );
			free(data);
		}
	}
	return self;
}

- (void)dealloc {
	[[EJSharedOpenALManager instance].buffers removeObjectForKey:path];
	[path release];
	
	if( bufferId ) {
		alDeleteBuffers(1, &bufferId);
	}
	[super dealloc];
}

- (void*)getAudioDataWithURL:(NSURL *)url {
	
	void *data = NULL;
	
	// Open the file
	ExtAudioFileRef	file = NULL;
	OSStatus error = ExtAudioFileOpenURL((CFURLRef)url, &file);
	if( error ) {
		NSLog(@"OpenALSource: ExtAudioFileOpenURL FAILED, Error = %d", (int)error);
		goto Exit; 
	}
	
	// Get the audio data format
	AudioStreamBasicDescription inputFormat;
	UInt32 propertySize = sizeof(inputFormat);
	error = ExtAudioFileGetProperty(file, kExtAudioFileProperty_FileDataFormat, &propertySize, &inputFormat);
	if( error ) {
		NSLog(@"OpenALSource: ExtAudioFileGetProperty(kExtAudioFileProperty_FileDataFormat) FAILED, Error = %d", (int)error);
		goto Exit;
	}
	if( inputFormat.mChannelsPerFrame > 2 ) { 
		NSLog(@"OpenALSource: Unsupported Format, channel count is greater than stereo"); 
		goto Exit;
	}
	

	// Set the client format to 16 bit signed integer (native-endian) data
	// Maintain the channel count and sample rate of the original source format
	AudioStreamBasicDescription	outputFormat = {
		.mSampleRate = inputFormat.mSampleRate,
		.mChannelsPerFrame = inputFormat.mChannelsPerFrame,
		.mFormatID = kAudioFormatLinearPCM,
		.mBytesPerPacket = 2 * inputFormat.mChannelsPerFrame,
		.mFramesPerPacket = 1,
		.mBytesPerFrame = 2 * inputFormat.mChannelsPerFrame,
		.mBitsPerChannel = 16,
		.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger
	};
	
	// Set the desired client (output) data format
	error = ExtAudioFileSetProperty(file, kExtAudioFileProperty_ClientDataFormat, sizeof(outputFormat), &outputFormat);
	if( error ) {
		NSLog(@"OpenALSource: ExtAudioFileSetProperty(kExtAudioFileProperty_ClientDataFormat) FAILED, Error = %d", (int)error);
		goto Exit; 
	}
	
	// Get the total frame count
	SInt64 frameCount = 0;
	propertySize = sizeof(frameCount);
	error = ExtAudioFileGetProperty(file, kExtAudioFileProperty_FileLengthFrames, &propertySize, &frameCount);
	if( error ) {
		NSLog(@"OpenALSource: ExtAudioFileGetProperty(kExtAudioFileProperty_FileLengthFrames) FAILED, Error = %d", (int)error);
		goto Exit; 
	}
	
	// Read all the data into memory
	UInt32 dataSize = (UInt32)frameCount * outputFormat.mBytesPerFrame;
	data = malloc(dataSize);

	AudioBufferList	bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0].mDataByteSize = dataSize;
	bufferList.mBuffers[0].mNumberChannels = outputFormat.mChannelsPerFrame;
	bufferList.mBuffers[0].mData = data;
	
	// Read the data into an AudioBufferList
	error = ExtAudioFileRead(file, (UInt32*)&frameCount, &bufferList);
	if( error == noErr ) {
		// success
		size = (ALsizei)dataSize;
		format = (outputFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
		sampleRate = (ALsizei)outputFormat.mSampleRate;
		
		duration = (float)frameCount / sampleRate;
	}
	else { 
		// failure
		free(data);
		data = NULL;
		NSLog(@"OpenALSource: ExtAudioFileRead FAILED, Error = %d", (int)error);
		goto Exit;
	}
	
Exit:
	// Dispose the ExtAudioFileRef, it is no longer needed
	if( file ) {
		ExtAudioFileDispose(file);
	}
	return data;
}

@end;
