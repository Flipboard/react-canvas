#import "EJClassLoader.h"
#import "EJBindingBase.h"
#import "EJJavaScriptView.h"

typedef struct {
	Class class;
	EJJavaScriptView *scriptView;
} EJClassWithScriptView;

JSValueRef EJGetNativeClass(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception) {
	CFStringRef className = JSStringCopyCFString( kCFAllocatorDefault, propertyNameJS );
	EJJavaScriptView *scriptView = JSObjectGetPrivate(object);
	
	JSObjectRef obj = NULL;
	NSString *fullClassName = [@EJ_BINDING_CLASS_PREFIX stringByAppendingString:(NSString *)className];
	Class class = NSClassFromString(fullClassName);
	
	if( class && [class isSubclassOfClass:EJBindingBase.class] ) {
		
		// Pack the class together with the scriptView into a struct, so it can
		// be put in the constructor's private data
		EJClassWithScriptView *classWithScriptView = malloc(sizeof(EJClassWithScriptView));
		classWithScriptView->class = class;
		classWithScriptView->scriptView = scriptView;
		
		obj = JSObjectMake( ctx, scriptView.classLoader.jsConstructorClass, (void *)classWithScriptView );
	}
	
	CFRelease(className);
	return obj ? obj : scriptView->jsUndefined;
}

JSObjectRef EJCallAsConstructor(JSContextRef ctx, JSObjectRef constructor, size_t argc, const JSValueRef argv[], JSValueRef* exception) {
	
	// Unpack the class and scriptView from the constructor's private data
	EJClassWithScriptView *classWithScriptView = (EJClassWithScriptView *)JSObjectGetPrivate(constructor);
	Class class = classWithScriptView->class;
	EJJavaScriptView *scriptView = classWithScriptView->scriptView;
	
	// Init the native class and create the JSObject with it
	EJBindingBase *instance = [(EJBindingBase *)[class alloc] initWithContext:ctx argc:argc argv:argv];
	JSObjectRef obj = [class createJSObjectWithContext:ctx scriptView:scriptView instance:instance];
	[instance release];
	
	return obj;
}

void EJConstructorFinalize(JSObjectRef object) {
	EJClassWithScriptView *classWithScriptView = (EJClassWithScriptView *)JSObjectGetPrivate(object);
	free(classWithScriptView);
}

bool EJConstructorHasInstance(JSContextRef ctx, JSObjectRef constructor, JSValueRef possibleInstance, JSValueRef* exception) {

	// Unpack the class and instance from private data
	EJClassWithScriptView *classWithScriptView = (EJClassWithScriptView *)JSObjectGetPrivate(constructor);
	id instance = JSValueGetPrivate(possibleInstance);
	
	if( !classWithScriptView || !instance ) {
		return false;
	}
	
	return [instance isKindOfClass:classWithScriptView->class];
}


@implementation EJClassLoader
@synthesize jsConstructorClass;

- (id)initWithScriptView:(EJJavaScriptView *)scriptView name:(NSString *)name {
	if( self = [super init] ) {
		JSGlobalContextRef context = scriptView.jsGlobalContext;
		
		// Create the constructor class
		JSClassDefinition constructorClassDef = kJSClassDefinitionEmpty;
		constructorClassDef.callAsConstructor = EJCallAsConstructor;
		constructorClassDef.hasInstance = EJConstructorHasInstance;
		constructorClassDef.finalize = EJConstructorFinalize;
		jsConstructorClass = JSClassCreate(&constructorClassDef);
		
		// Create the collection class and attach it to the global context with
		// the given name
		JSClassDefinition loaderClassDef = kJSClassDefinitionEmpty;
		loaderClassDef.getProperty = EJGetNativeClass;
		JSClassRef loaderClass = JSClassCreate(&loaderClassDef);
		
		JSObjectRef global = JSContextGetGlobalObject(context);
		
		JSObjectRef loader = JSObjectMake(context, loaderClass, scriptView);
		JSStringRef jsName = JSStringCreateWithUTF8CString(name.UTF8String);
		JSObjectSetProperty(
			context, global, jsName, loader,
			(kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly),
			NULL
		);
		JSStringRelease(jsName);
		
		
		// Create Class cache dict
		classCache = [[NSMutableDictionary alloc] initWithCapacity:16];
	}
	return self;
}

- (void)dealloc {
	[classCache release];
	JSClassRelease(jsConstructorClass);
	[super dealloc];
}

- (EJLoadedJSClass *)getJSClass:(id)class {
	// Try the cache first
	EJLoadedJSClass *loadedClass = classCache[class];
	if( loadedClass ) {
		return loadedClass;
	}
	
	// Still here? Load and insert into cache
	loadedClass = [self loadJSClass:class];
	classCache[class] = loadedClass;
	
	return loadedClass;
}

- (EJLoadedJSClass *)loadJSClass:(id)class {
	// Gather all class methods that return C callbacks for this class or it's parents
	NSMutableArray *methods = [[NSMutableArray alloc] init];
	NSMutableArray *properties = [[NSMutableArray alloc] init];
	NSMutableDictionary *constantValues = [[NSMutableDictionary alloc] init];
		
	// Traverse this class and all its super classes
	Class base = EJBindingBase.class;
	for( Class sc = class; sc != base && [sc isSubclassOfClass:base]; sc = sc.superclass ) {
	
		// Traverse all class methods for this class; i.e. all classes that are defined with the
		// EJ_BIND_FUNCTION, EJ_BIND_GET or EJ_BIND_SET macros
		u_int count;
		Method *methodList = class_copyMethodList(object_getClass(sc), &count);
		for (int i = 0; i < count ; i++) {
			SEL selector = method_getName(methodList[i]);
			NSString *name = NSStringFromSelector(selector);
			
			if( [name hasPrefix:@"_ptr_to_func_"] ) {
				[methods addObject:[name substringFromIndex:sizeof("_ptr_to_func_")-1] ];
			}
			else if( [name hasPrefix:@"_ptr_to_get_"] ) {
				// We only look for getters - a property that has a setter, but no getter will be ignored
				[properties addObject:[name substringFromIndex:sizeof("_ptr_to_get_")-1] ];
			}
			else if( [name hasPrefix:@"_const_"] ) {
				NSObject *constant = [class performSelector:NSSelectorFromString(name)];
				[constantValues setObject:constant forKey:[name substringFromIndex:sizeof("_const_")-1]];
			}
		}
		free(methodList);
	}
	
	
	// Set up the JSStaticValue struct array
	JSStaticValue *values = calloc( properties.count + 1, sizeof(JSStaticValue) );
	for( int i = 0; i < properties.count; i++ ) {
		NSString *name = properties[i];
		
		values[i].name = name.UTF8String;
		values[i].attributes = kJSPropertyAttributeDontDelete;
		
		SEL get = NSSelectorFromString([@"_ptr_to_get_" stringByAppendingString:name]);
		values[i].getProperty = (JSObjectGetPropertyCallback)[class performSelector:get];
		
		// Property has a setter? Otherwise mark as read only
		SEL set = NSSelectorFromString([@"_ptr_to_set_"stringByAppendingString:name]);
		if( [class respondsToSelector:set] ) {
			values[i].setProperty = (JSObjectSetPropertyCallback)[class performSelector:set];
		}
		else {
			values[i].attributes |= kJSPropertyAttributeReadOnly;
		}
	}
	
	// Set up the JSStaticFunction struct array
	JSStaticFunction *functions = calloc( methods.count + 1, sizeof(JSStaticFunction) );
	for( int i = 0; i < methods.count; i++ ) {
		NSString *name = methods[i];
				
		functions[i].name = name.UTF8String;
		functions[i].attributes = kJSPropertyAttributeDontDelete;
		
		SEL call = NSSelectorFromString([@"_ptr_to_func_" stringByAppendingString:name]);
		functions[i].callAsFunction = (JSObjectCallAsFunctionCallback)[class performSelector:call];
	}
	
	JSClassDefinition classDef = kJSClassDefinitionEmpty;
	classDef.className = class_getName(class) + sizeof(EJ_BINDING_CLASS_PREFIX)-1;
	classDef.finalize = EJBindingBaseFinalize;
	classDef.staticValues = values;
	classDef.staticFunctions = functions;
	JSClassRef jsClass = JSClassCreate(&classDef);
	
	free( values );
	free( functions );
	
	[properties release];
	[methods release];
	
	EJLoadedJSClass *loadedClass = [[EJLoadedJSClass alloc] initWithJSClass:jsClass constantValues:constantValues];
	
	// The JSClass and constantValues dict are now retained by the loadedClass instance
	JSClassRelease(jsClass);
	[constantValues release];
	
	return [loadedClass autorelease];
}

@end


@implementation EJLoadedJSClass
@synthesize jsClass, constantValues;

- (id)initWithJSClass:(JSClassRef)jsClassp constantValues:(NSDictionary *)constantValuesp {
	if( self = [super init] ) {
		jsClass = JSClassRetain(jsClassp);
		constantValues = [constantValuesp retain];
	}
	return self;
}

- (void)dealloc {
	JSClassRelease(jsClass);
	[constantValues release];
	[super dealloc];
}

@end


