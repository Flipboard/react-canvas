#import "EJConvertColorRGBA.h"

static const EJColorRGBA ColorNames[] = {
	{.hex = 0xff000000}, // invaid
	{.hex = 0xfffff8f0}, // aliceblue
	{.hex = 0xffd7ebfa}, // antiquewhite
	{.hex = 0xffffff00}, // aqua
	{.hex = 0xffd4ff7f}, // aquamarine
	{.hex = 0xfffffff0}, // azure
	{.hex = 0xffdcf5f5}, // beige
	{.hex = 0xffc4e4ff}, // bisque
	{.hex = 0xff000000}, // black
	{.hex = 0xffcdebff}, // blanchedalmond
	{.hex = 0xffff0000}, // blue
	{.hex = 0xffe22b8a}, // blueviolet
	{.hex = 0xff2a2aa5}, // brown
	{.hex = 0xff87b8de}, // burlywood
	{.hex = 0xffa09e5f}, // cadetblue
	{.hex = 0xff00ff7f}, // chartreuse
	{.hex = 0xff1e69d2}, // chocolate
	{.hex = 0xff507fff}, // coral
	{.hex = 0xffed9564}, // cornflowerblue
	{.hex = 0xffdcf8ff}, // cornsilk
	{.hex = 0xff3c14dc}, // crimson
	{.hex = 0xffffff00}, // cyan
	{.hex = 0xff8b0000}, // darkblue
	{.hex = 0xff8b8b00}, // darkcyan
	{.hex = 0xff0b86b8}, // darkgoldenrod
	{.hex = 0xffa9a9a9}, // darkgray
	{.hex = 0xffa9a9a9}, // darkgrey
	{.hex = 0xff006400}, // darkgreen
	{.hex = 0xff6bb7bd}, // darkkhaki
	{.hex = 0xff8b008b}, // darkmagenta
	{.hex = 0xff2f6b55}, // darkolivegreen
	{.hex = 0xff008cff}, // darkorange
	{.hex = 0xffcc3299}, // darkorchid
	{.hex = 0xff00008b}, // darkred
	{.hex = 0xff7a96e9}, // darksalmon
	{.hex = 0xff8fbc8f}, // darkseagreen
	{.hex = 0xff8b3d48}, // darkslateblue
	{.hex = 0xff4f4f2f}, // darkslategray
	{.hex = 0xff4f4f2f}, // darkslategrey
	{.hex = 0xffd1ce00}, // darkturquoise
	{.hex = 0xffd30094}, // darkviolet
	{.hex = 0xff9314ff}, // deeppink
	{.hex = 0xffffbf00}, // deepskyblue
	{.hex = 0xff696969}, // dimgray
	{.hex = 0xff696969}, // dimgrey
	{.hex = 0xffff901e}, // dodgerblue
	{.hex = 0xff2222b2}, // firebrick
	{.hex = 0xfff0faff}, // floralwhite
	{.hex = 0xff228b22}, // forestgreen
	{.hex = 0xffff00ff}, // fuchsia
	{.hex = 0xffdcdcdc}, // gainsboro
	{.hex = 0xfffff8f8}, // ghostwhite
	{.hex = 0xff00d7ff}, // gold
	{.hex = 0xff20a5da}, // goldenrod
	{.hex = 0xff808080}, // gray
	{.hex = 0xff808080}, // grey
	{.hex = 0xff008000}, // green
	{.hex = 0xff2fffad}, // greenyellow
	{.hex = 0xfff0fff0}, // honeydew
	{.hex = 0xffb469ff}, // hotpink
	{.hex = 0xff5c5ccd}, // indianred
	{.hex = 0xff82004b}, // indigo
	{.hex = 0xfff0ffff}, // ivory
	{.hex = 0xff8ce6f0}, // khaki
	{.hex = 0xfffae6e6}, // lavender
	{.hex = 0xfff5f0ff}, // lavenderblush
	{.hex = 0xff00fc7c}, // lawngreen
	{.hex = 0xffcdfaff}, // lemonchiffon
	{.hex = 0xffe6d8ad}, // lightblue
	{.hex = 0xff8080f0}, // lightcoral
	{.hex = 0xffffffe0}, // lightcyan
	{.hex = 0xffd2fafa}, // lightgoldenrodyellow
	{.hex = 0xffd3d3d3}, // lightgray
	{.hex = 0xffd3d3d3}, // lightgrey
	{.hex = 0xff90ee90}, // lightgreen
	{.hex = 0xffc1b6ff}, // lightpink
	{.hex = 0xff7aa0ff}, // lightsalmon
	{.hex = 0xffaab220}, // lightseagreen
	{.hex = 0xffface87}, // lightskyblue
	{.hex = 0xff998877}, // lightslategray
	{.hex = 0xff998877}, // lightslategrey
	{.hex = 0xffdec4b0}, // lightsteelblue
	{.hex = 0xffe0ffff}, // lightyellow
	{.hex = 0xff00ff00}, // lime
	{.hex = 0xff32cd32}, // limegreen
	{.hex = 0xffe6f0fa}, // linen
	{.hex = 0xffff00ff}, // magenta
	{.hex = 0xff000080}, // maroon
	{.hex = 0xffaacd66}, // mediumaquamarine
	{.hex = 0xffcd0000}, // mediumblue
	{.hex = 0xffd355ba}, // mediumorchid
	{.hex = 0xffd87093}, // mediumpurple
	{.hex = 0xff71b33c}, // mediumseagreen
	{.hex = 0xffee687b}, // mediumslateblue
	{.hex = 0xff9afa00}, // mediumspringgreen
	{.hex = 0xffccd148}, // mediumturquoise
	{.hex = 0xff8515c7}, // mediumvioletred
	{.hex = 0xff701919}, // midnightblue
	{.hex = 0xfffafff5}, // mintcream
	{.hex = 0xffe1e4ff}, // mistyrose
	{.hex = 0xffb5e4ff}, // moccasin
	{.hex = 0xffaddeff}, // navajowhite
	{.hex = 0xff800000}, // navy
	{.hex = 0xffe6f5fd}, // oldlace
	{.hex = 0xff008080}, // olive
	{.hex = 0xff238e6b}, // olivedrab
	{.hex = 0xff00a5ff}, // orange
	{.hex = 0xff0045ff}, // orangered
	{.hex = 0xffd670da}, // orchid
	{.hex = 0xffaae8ee}, // palegoldenrod
	{.hex = 0xff98fb98}, // palegreen
	{.hex = 0xffeeeeaf}, // paleturquoise
	{.hex = 0xff9370d8}, // palevioletred
	{.hex = 0xffd5efff}, // papayawhip
	{.hex = 0xffb9daff}, // peachpuff
	{.hex = 0xff3f85cd}, // peru
	{.hex = 0xffcbc0ff}, // pink
	{.hex = 0xffdda0dd}, // plum
	{.hex = 0xffe6e0b0}, // powderblue
	{.hex = 0xff800080}, // purple
	{.hex = 0xff0000ff}, // red
	{.hex = 0xff8f8fbc}, // rosybrown
	{.hex = 0xffe16941}, // royalblue
	{.hex = 0xff13458b}, // saddlebrown
	{.hex = 0xff7280fa}, // salmon
	{.hex = 0xff60a4f4}, // sandybrown
	{.hex = 0xff578b2e}, // seagreen
	{.hex = 0xffeef5ff}, // seashell
	{.hex = 0xff2d52a0}, // sienna
	{.hex = 0xffc0c0c0}, // silver
	{.hex = 0xffebce87}, // skyblue
	{.hex = 0xffcd5a6a}, // slateblue
	{.hex = 0xff908070}, // slategray
	{.hex = 0xff908070}, // slategrey
	{.hex = 0xfffafaff}, // snow
	{.hex = 0xff7fff00}, // springgreen
	{.hex = 0xffb48246}, // steelblue
	{.hex = 0xff8cb4d2}, // tan
	{.hex = 0xff808000}, // teal
	{.hex = 0xffd8bfd8}, // thistle
	{.hex = 0xff4763ff}, // tomato
	{.hex = 0xffd0e040}, // turquoise
	{.hex = 0xffee82ee}, // violet
	{.hex = 0xffb3def5}, // wheat
	{.hex = 0xffffffff}, // white
	{.hex = 0xfff5f5f5}, // whitesmoke
	{.hex = 0xff00ffff}, // yellow
	{.hex = 0xff32cd9a}, // yellowgreen
	{.hex = 0x00000000}  // transparent
};

// This is a bit wild. ColorHashForString returns a hash of the input string in the range
// of [0 -- 544] (the smallest range I could find with such a simple hash function). This
// hash can then be used as an index into the ColorHashesToColorNames table, which in turn
// points to the actual color in the ColorNames array. It's totally over the top, considering
// that nobody actually uses those names anymore.
// Looking up color names from an NSDictionary takes 4 times as long, but it's still next
// to nothing (~0.02ms). At least I learned a few things about perfect hashes today :)

static const unsigned char ColorHashesToColorNames[544] = {
	0,0,0,0,0,57,0,0,0,58,84,0,145,0,0,0,0,0,53,0,2,0,9,86,41,0,0,0,0,0,0,0,0,0,24,0,0,0,0,0,0,0,75,0,0,0,0,0,0,0,109,
	0,0,0,124,0,0,0,113,26,0,0,0,0,87,0,0,0,71,0,0,0,85,0,0,0,0,72,0,118,0,0,0,0,0,0,115,45,0,0,0,0,0,0,82,0,0,65,0,92,0,
	0,112,0,6,96,0,0,0,143,22,0,51,0,0,0,0,0,98,142,0,73,0,0,0,122,61,0,138,0,0,0,0,0,0,131,0,18,0,0,0,62,0,0,140,0,0,46,0,0,0,
	0,0,0,95,43,0,0,0,136,0,8,0,0,0,81,0,40,0,0,0,55,0,0,0,0,0,20,0,0,105,0,0,0,0,49,0,0,0,0,10,0,0,0,0,0,0,0,30,0,80,
	0,0,47,146,0,0,0,103,0,133,0,0,0,148,0,0,144,0,0,0,0,0,5,0,0,0,0,63,0,132,21,0,27,0,0,0,0,0,25,0,0,0,0,0,0,0,36,116,0,0,
	0,0,0,97,54,102,0,0,123,0,0,34,0,0,0,60,0,0,0,0,83,0,0,0,0,0,0,0,0,0,0,50,0,0,0,0,0,15,0,0,7,76,0,90,0,0,0,0,0,0,
	0,0,14,0,129,0,0,3,0,0,0,0,0,0,0,0,120,0,0,0,107,38,104,4,147,0,0,0,0,0,0,0,0,0,0,0,0,0,69,28,0,0,0,0,13,0,0,79,0,0,
	0,126,0,0,0,0,0,0,0,0,94,0,0,106,33,0,0,0,0,0,0,0,64,0,0,0,110,0,0,0,0,0,0,0,0,0,0,52,0,48,0,0,0,101,0,0,0,0,0,1,
	0,0,99,0,141,135,23,0,0,114,0,0,89,0,0,0,0,0,121,0,39,67,127,0,17,0,0,68,130,0,44,0,139,119,0,0,111,0,0,0,0,0,0,31,66,
	0,0,117,91,0,0,0,32,0,0,0,0,0,0,0,42,0,0,35,0,77,0,0,70,37,78,0,56,0,0,0,0,128,0,0,0,0,74,0,100,0,29,0,11,0,0,0,0,0,0,
	0,59,0,0,0,108,0,0,0,0,0,0,0,0,0,134,0,0,0,0,0,137,0,0,93,0,0,0,0,0,0,0,16,0,0,0,0,125,12,88,0,0,0,19,0,0,0,0
};

static inline unsigned int ColorHashForString( const JSChar *s, size_t length ) {
	unsigned int h = 0;
	for( size_t i = 0; i < length; i++ ) {
		h = (h << 2) ^ h ^ (tolower(s[i]) * 42348311);
	}
	return (h % 544);
};

static EJColorRGBA HSLAtoColorRGBA(float h, float s, float l, float a) {
	h = fmodf(h, 1); // wrap around
	s = MAX(0,MIN(s,1));
	l = MAX(0,MIN(l,1));
	a = MAX(0,MIN(a,1));
	
	float r = l; // default to gray
	float g = l;
	float b = l;
	float v = (l <= 0.5) ? (l * (1.0 + s)) : (l + s - l * s);
	
	if( v > 0 ) {
		float m = l + l - v;
		float sv = (v - m ) / v;
		h *= 6.0;
		int sextant = (int)h;
		float fract = h - sextant;
		float vsf = v * sv * fract;
		float mid1 = m + vsf;
		float mid2 = v - vsf;

		switch( sextant ) {
			case 0: r = v; g = mid1; b = m; break;
			case 1: r = mid2; g = v; b = m; break;
			case 2: r = m; g = v; b = mid1; break;
			case 3: r = m; g = mid2; b = v; break;
			case 4: r = mid1; g = m; b = v; break;
			case 5: r = v; g = m; b = mid2; break;
		}
	}
	EJColorRGBA color = {.rgba = {
		.r = r * 255.0f,
		.g = g * 255.0f,
		.b = b * 255.0f,
		.a = a * 255.0f
	}};
	return color;
}

EJColorRGBA JSValueToColorRGBA(JSContextRef ctx, JSValueRef value) {
	EJColorRGBA c = {.hex = 0xff000000};
	
	JSStringRef jsString = JSValueToStringCopy( ctx, value, NULL );
	if( !jsString ) { return c; }
	
	size_t length = JSStringGetLength( jsString );
	if( length < 3 ) { return c; }
	
	const JSChar *jsc = JSStringGetCharactersPtr(jsString);
	char str[] = "ffffff";
	
	// #f0f format
	if( jsc[0] == '#' && length == 4 ) {
		str[0] = str[1] = jsc[3];
		str[2] = str[3] = jsc[2];
		str[4] = str[5] = jsc[1];
		c.hex = 0xff000000 | (unsigned int)strtol( str, NULL, 16 );
	}
	
	// #ff00ff format
	else if( jsc[0] == '#' && length == 7 ) {
		str[0] = jsc[5];
		str[1] = jsc[6];
		str[2] = jsc[3];
		str[3] = jsc[4];
		str[4] = jsc[1];
		str[5] = jsc[2];
		c.hex = 0xff000000 | (unsigned int)strtol( str, NULL, 16 );
	}
	
	// rgb(255,0,255) or rgba(255,0,255,0.5) format
	else if( (jsc[0] == 'r' || jsc[0] == 'R') && (jsc[1] == 'g' || jsc[1] == 'G') ) {
		int component = 0;
		for( int i = 4; i < length-1 && component < 4; i++ ) {
			if( component == 3 ) {
				// If we have an alpha component, copy the rest of the wide
				// string into a char array and use atof() to parse it.
				char alpha[8] = { 0,0,0,0, 0,0,0,0 };
				for( int j = 0; i + j < length-1 && j < 7; j++ ) {
					alpha[j] = jsc[i+j];
				}
				c.components[component] = atof(alpha) * 255.0f;
				component++;
			}
			else if( isdigit(jsc[i]) ) {
				c.components[component] = c.components[component] * 10 + (jsc[i] - '0'); 
			}
			else if( jsc[i] == ',' || jsc[i] == ')' ) {
				component++;
			}
		}
	}
	
	// hsl(120,100%,50%) or hsla(120,100%,50%,0.5) format
	else if( (jsc[0] == 'h' || jsc[0] == 'H') && (jsc[1] == 's' || jsc[1] == 'S') ) {
		bool skipDigits = false;
		float hsla[4] = {0,0,0,1};
		int component = 0;
		for( int i = 4; i < length-1 && component < 4; i++ ) {
			if( component == 3 ) {
				// If we have an alpha component, copy the rest of the wide
				// string into a char array and use atof() to parse it.
				char alpha[8] = { 0,0,0,0, 0,0,0,0 };
				for( int j = 0; i + j < length-1 && j < 7; j++ ) {
					alpha[j] = jsc[i+j];
				}
				hsla[component] = atof(alpha);
				component++;
			}
			else if( isdigit(jsc[i]) && !skipDigits ) {
				hsla[component] = hsla[component] * 10 + (jsc[i] - '0');
			}
			else if( jsc[i] == '.' ) {
				skipDigits = true;
			}
			else if( jsc[i] == ',' || jsc[i] == ')' ) {
				skipDigits = false;
				component++;
			}
		}
		c = HSLAtoColorRGBA(hsla[0]/360.0f, hsla[1]/100.0f, hsla[2]/100.0f, hsla[3]);
	}
	
	// try color name
	else {
		unsigned int hash = ColorHashForString( jsc, length );
		c = ColorNames[ColorHashesToColorNames[hash]];
	}
	
	JSStringRelease(jsString);
	return c;
}

JSValueRef ColorRGBAToJSValue( JSContextRef ctx, EJColorRGBA c ) {
	static char buffer[32];
	sprintf(buffer, "rgba(%d,%d,%d,%.3f)", c.rgba.r, c.rgba.g, c.rgba.b, (float)c.rgba.a/255.0f );
	
	JSStringRef src = JSStringCreateWithUTF8CString( buffer );
	JSValueRef ret = JSValueMakeString(ctx, src);
	JSStringRelease(src);
	return ret;
}

