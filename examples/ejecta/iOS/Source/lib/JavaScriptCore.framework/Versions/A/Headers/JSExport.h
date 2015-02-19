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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

#import <JavaScriptCore/JavaScriptCore.h>

#if JSC_OBJC_API_ENABLED

/*!
@protocol
@abstract JSExport provides a declarative way to export Objective-C instance methods,
 class methods, and properties to JavaScript code.

@discussion When a JavaScript value is created from an instance of an Objective-C class
 for which no copying conversion is specified a JavaScript wrapper object will
 be created.

 In JavaScript, inheritance is supported via a chain of prototype objects, and
 for each Objective-C class (and per JSContext) an object appropriate for use
 as a prototype will be provided. For the class NSObject the prototype object
 will be the JavaScript context's Object Prototype. For all other Objective-C
 classes a Prototype object will be created. The Prototype object for a given
 Objective-C class will have its internal [Prototype] property set to point to
 the Prototype object of the Objective-C class's superclass. As such the
 prototype chain for a JavaScript wrapper object will reflect the wrapped
 Objective-C type's inheritance hierarchy.

 In addition to the Prototype object a JavaScript Constructor object will also
 be produced for each Objective-C class. The Constructor object has a property
 named 'prototype' that references the Prototype object, and the Prototype
 object has a property named 'constructor' that references the Constructor.
 The Constructor object is not callable.

 By default no methods or properties of the Objective-C class will be exposed
 to JavaScript; however methods and properties may explicitly be exported.
 For each protocol that a class conforms to, if the protocol incorporates the
 protocol JSExport, then the protocol will be interpreted as a list of methods
 and properties to be exported to JavaScript.

 For each instance method being exported a corresponding JavaScript function
 will be assigned as a property of the Prototype object. For each Objective-C
 property being exported a JavaScript accessor property will be created on the
 Prototype. For each class method exported a JavaScript function will be
 created on the Constructor object. For example:

<pre>
@textblock
    @protocol MyClassJavaScriptMethods <JSExport>
    - (void)foo;
    @end

    @interface MyClass : NSObject <MyClassJavaScriptMethods>
    - (void)foo;
    - (void)bar;
    @end
@/textblock
</pre>

 Data properties that are created on the prototype or constructor objects have
 the attributes: <code>writable:true</code>, <code>enumerable:false</code>, <code>configurable:true</code>. 
 Accessor properties have the attributes: <code>enumerable:false</code> and <code>configurable:true</code>.

 If an instance of <code>MyClass</code> is converted to a JavaScript value, the resulting
 wrapper object will (via its prototype) export the method <code>foo</code> to JavaScript,
 since the class conforms to the <code>MyClassJavaScriptMethods</code> protocol, and this
 protocol incorporates <code>JSExport</code>. <code>bar</code> will not be exported.

 Properties, arguments, and return values of the following types are
 supported:

 Primitive numbers: signed values of up to 32-bits are converted in a manner
    consistent with valueWithInt32/toInt32, unsigned values of up to 32-bits
    are converted in a manner consistent with valueWithUInt32/toUInt32, all
    other numeric values are converted consistently with valueWithDouble/
    toDouble.

 BOOL: values are converted consistently with valueWithBool/toBool.

 id: values are converted consistently with valueWithObject/toObject.

 Objective-C Class: - where the type is a pointer to a specified Objective-C
    class, conversion is consistent with valueWithObjectOfClass/toObject.

 struct types: C struct types are supported, where JSValue provides support
    for the given type. Support is built in for CGPoint, NSRange, CGRect, and
    CGSize.

 block types: Blocks can only be passed if they had been converted 
    successfully by valueWithObject/toObject previously.

 For any interface that conforms to JSExport the normal copying conversion for
 built in types will be inhibited - so, for example, if an instance that
 derives from NSString but conforms to JSExport is passed to valueWithObject:
 then a wrapper object for the Objective-C object will be returned rather than
 a JavaScript string primitive.
*/
@protocol JSExport
@end

/*!
@define
@abstract Rename a selector when it's exported to JavaScript.
@discussion When a selector that takes one or more arguments is converted to a JavaScript
 property name, by default a property name will be generated by performing the
 following conversion:

  - All colons are removed from the selector

  - Any lowercase letter that had followed a colon will be capitalized.

 Under the default conversion a selector <code>doFoo:withBar:</code> will be exported as
 <code>doFooWithBar</code>. The default conversion may be overriden using the JSExportAs
 macro, for example to export a method <code>doFoo:withBar:</code> as <code>doFoo</code>:

<pre>
@textblock
    @protocol MyClassJavaScriptMethods <JSExport>
    JSExportAs(doFoo,
    - (void)doFoo:(id)foo withBar:(id)bar
    );
    @end
@/textblock
</pre>

 Note that the JSExport macro may only be applied to a selector that takes one
 or more argument.
*/
#define JSExportAs(PropertyName, Selector) \
    @optional Selector __JS_EXPORT_AS__##PropertyName:(id)argument; @required Selector

#endif
