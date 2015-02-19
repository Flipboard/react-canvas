# Ejecta

Ejecta is a fast, open source JavaScript, Canvas & Audio implementation for iOS. Think of it as a Browser that can only display a Canvas element.

More info & Documentation: http://impactjs.com/ejecta

Ejecta is published under the [MIT Open Source License](http://opensource.org/licenses/mit-license.php).


## Recent Breaking Changes


 - 2013-07-10 - All events now supply a proper `event` object to their callbacks. The `keypress` event for `EJBindingKeyInput` provides the char to callbacks as property of the event object: `input.onkeypress = function(event) { console.log(event.char); }`

 - 2013-04-15 - The GameCenter's `softAuthenticate` now calls the callback function with an error if the auth was skipped, instead of doing nothing. Also, `softAuthenticate` will now always try to auth when called for the very first time after installation.

 - 2013-03-15 - `canvas.scaleMode` was removed in favor of the `canvas.style` property. To scale and position your canvas independently from its internal resolution, use the style's `width`, `height`, `top` and `left` properties. I.e. to always scale to fullscreen: `canvas.style.width = window.innerWidth; canvas.style.height = window.innerHeight`. Appending `px` suffixes is ok.


## WebGL Support

Recently WebGL support has been merged into the main branch. A huge thanks goes to @vikerman - he did most of the grunt work of the WebGL implementation. To have the WebGL alongside Canvas2D, I modified the old 2D implementation to use OpenGL ES2 instead of ES1, just like WebGL itself. 

Unlike with the Canvas2D, if you want to have a WebGL Canvas in retina resolution, you have to manually double the internal resiolution and shrink down the displayed size again through the `style`. I.e.

```javascript
canvas.width = window.innerWidth * window.devicePixelRatio;
canvas.height = window.innerHeight * window.devicePixelRatio;
canvas.style.width = window.innerWidth + 'px';
canvas.style.height = window.innerHeight + 'px';
```


## Three.js on iOS with Ejecta 

Ejecta always creates the screen Canvas element for you. You have to hand this Canvas element over to Three.js instead of letting it create its own.

```javascript
renderer = new THREE.WebGLRenderer( {canvas: document.getElementById('canvas')} );
```


## How to use

1. Create a folder called `App` within this XCode project
2. Copy your canvas application into the `App` folder
3. Ensure you have at least 1 file named `index.js`
4. Build the XCode project

For an example application, copy `./index.js` into the `App` folder. An example App folder with the Three.js [Walt CubeMap demo](http://mrdoob.github.com/three.js/examples/webgl_materials_cubemap.html) can be found here:

http://phoboslab.org/files/Ejecta-ThreeJS-CubeMap.zip
