/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef JSManagedValue_h
#define JSManagedValue_h

#import <JavaScriptCore/JSBase.h>

#if JSC_OBJC_API_ENABLED

@class JSValue;
@class JSContext;

/*!
@interface
@discussion JSManagedValue represents a "conditionally retained" JSValue. 
 "Conditionally retained" means that as long as either the JSManagedValue's 
 JavaScript value is reachable through the JavaScript object graph
 or the JSManagedValue object is reachable through the external Objective-C 
 object graph as reported to the JSVirtualMachine using 
 addManagedReference:withOwner:, the corresponding JavaScript value will 
 be retained. However, if neither of these conditions are true, the 
 corresponding JSValue will be released and set to nil.

 The primary use case for JSManagedValue is for safely referencing JSValues 
 from the Objective-C heap. It is incorrect to store a JSValue into an 
 Objective-C heap object, as this can very easily create a reference cycle, 
 keeping the entire JSContext alive.
*/ 
NS_CLASS_AVAILABLE(10_9, 7_0)
@interface JSManagedValue : NSObject

/*!
@method
@abstract Create a JSManagedValue from a JSValue.
@param value
@result The new JSManagedValue.
*/
+ (JSManagedValue *)managedValueWithValue:(JSValue *)value;

/*!
@method
@abstract Create a JSManagedValue.
@param value
@result The new JSManagedValue.
*/
- (instancetype)initWithValue:(JSValue *)value;

/*!
@property
@abstract Get the JSValue from the JSManagedValue.
@result The corresponding JSValue for this JSManagedValue or 
 nil if the JSValue has been collected.
*/
@property (readonly, strong) JSValue *value;

@end

#endif // JSC_OBJC_API_ENABLED

#endif // JSManagedValue_h
