#ifdef VERTEX_SHADER
    vec2 GetLightMapCoordinates() {
        vec2 lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        return clamp((lmCoord - 0.03125) * 1.06667, 0.0, 1.0);
    }
    vec3 GetSunVector() {
        const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
        #ifdef OVERWORLD
            float ang = fract(timeAngle - 0.25);
            ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
            return normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
        #elif defined END
            float ang = 0.0;
            return normalize((gbufferModelView * vec4(vec3(0.0, sunRotationData * 2000.0), 1.0)).xyz);
        #else
            return vec3(0.0);
        #endif
    }
#endif

int min1(int x) {
    return min(x, 1);
}
float min1(float x) {
    return min(x, 1.0);
}
int max0(int x) {
    return max(x, 0);
}
float max0(float x) {
    return max(x, 0.0);
}
vec2 max0(vec2 x) {
    return max(x, vec2(0.0));
}
vec3 max0(vec3 x) {
    return max(x, vec3(0.0));
}
vec4 max0(vec4 x) {
    return max(x, vec4(0.0));
}
int clamp01(int x) {
    return clamp(x, 0, 1);
}
float clamp01(float x) {
    return clamp(x, 0.0, 1.0);
}
vec2 clamp01(vec2 x) {
    return clamp(x, vec2(0.0), vec2(1.0));
}
vec3 clamp01(vec3 x) {
    return clamp(x, vec3(0.0), vec3(1.0));
}
vec4 clamp01(vec4 x) {
    return clamp(x, vec4(0.0), vec4(1.0));
}

int pow2(int x) {
    return x * x;
}
float pow2(float x) {
    return x * x;
}
vec2 pow2(vec2 x) {
    return x * x;
}
vec3 pow2(vec3 x) {
    return x * x;
}
vec4 pow2(vec4 x) {
    return x * x;
}

int pow3(int x) {
    return pow2(x) * x;
}
float pow3(float x) {
    return pow2(x) * x;
}
vec2 pow3(vec2 x) {
    return pow2(x) * x;
}
vec3 pow3(vec3 x) {
    return pow2(x) * x;
}
vec4 pow3(vec4 x) {
    return pow2(x) * x;
}

int pow4(int x) {
    return pow2(x) * pow2(x);
}
float pow4(float x) {
    return pow2(x) * pow2(x);
}
vec2 pow4(vec2 x) {
    return pow2(x) * pow2(x);
}
vec3 pow4(vec3 x) {
    return pow2(x) * pow2(x);
}
vec4 pow4(vec4 x) {
    return pow2(x) * pow2(x);
}

int pow5(int x) {
    return pow3(x) * pow2(x);
}
float pow5(float x) {
    return pow3(x) * pow2(x);
}
vec2 pow5(vec2 x) {
    return pow3(x) * pow2(x);
}
vec3 pow5(vec3 x) {
    return pow3(x) * pow2(x);
}
vec4 pow5(vec4 x) {
    return pow3(x) * pow2(x);
}

int pow6(int x) {
    return pow3(x) * pow3(x);
}
float pow6(float x) {
    return pow3(x) * pow3(x);
}
vec2 pow6(vec2 x) {
    return pow3(x) * pow3(x);
}
vec3 pow6(vec3 x) {
    return pow3(x) * pow3(x);
}
vec4 pow6(vec4 x) {
    return pow3(x) * pow3(x);
}

float pow1_5(float x) { // Faster pow(x, 1.5) approximation (that isn't accurate at all) if x is between 0 and 1
    return x - x * pow2(1.0 - x); // Thanks to SixthSurge
}
vec2 pow1_5(vec2 x) {
    return x - x * pow2(1.0 - x);
}
vec3 pow1_5(vec3 x) {
    return x - x * pow2(1.0 - x);
}
vec4 pow1_5(vec4 x) {
    return x - x * pow2(1.0 - x);
}

float sqrt1(float x) { // Faster sqrt() approximation (that isn't accurate at all) if x is between 0 and 1
    return x * (2.0 - x); // Thanks to Builderb0y
}
vec2 sqrt1(vec2 x) {
    return x * (2.0 - x);
}
vec3 sqrt1(vec3 x) {
    return x * (2.0 - x);
}
vec4 sqrt1(vec4 x) {
    return x * (2.0 - x);
}
float sqrt2(float x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec2 sqrt2(vec2 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec3 sqrt2(vec3 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec4 sqrt2(vec4 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
float sqrt3(float x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec2 sqrt3(vec2 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec3 sqrt3(vec3 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec4 sqrt3(vec4 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
float sqrt4(float x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec2 sqrt4(vec2 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec3 sqrt4(vec3 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}
vec4 sqrt4(vec4 x) {
    x = 1.0 - x;
    x *= x;
    x *= x;
    x *= x;
    x *= x;
    return 1.0 - x;
}

float smoothstep1(float x) {
    return x * x * (3.0 - 2.0 * x);
}
vec2 smoothstep1(vec2 x) {
    return x * x * (3.0 - 2.0 * x);
}
vec3 smoothstep1(vec3 x) {
    return x * x * (3.0 - 2.0 * x);
}
vec4 smoothstep1(vec4 x) {
    return x * x * (3.0 - 2.0 * x);
}

#define rcp(x) (1.0 / (x))

float maxOf(vec2 v) { return max(v.x, v.y); }
float maxOf(vec3 v) { return max(v.x, max(v.y, v.z)); }
float maxOf(vec4 v) { return max(v.x, max(v.y, max(v.z, v.w))); }
float minOf(vec2 v) { return min(v.x, v.y); }
float minOf(vec3 v) { return min(v.x, min(v.y, v.z)); }
float minOf(vec4 v) { return min(v.x, min(v.y, min(v.z, v.w))); }

// Smoothing function used by smoothstep
// Zero derivative at zero and one
float cubic_smooth(float x) {
	return pow2(x) * (3.0 - 2.0 * x);
}

// Remaps center +/- 0.5 * width to zero and center to 1, with the same smoothing function as
// smoothstep
float pulse(float x, float center, float width) {
    x = abs(x - center) / width;
    return x > 1.0 ? 0.0 : 1.0 - cubic_smooth(x);
}

float pulse(float x, float center, float width, const float period) {
	x = (x - center + 0.5 * period) / period;
	x = fract(x) * period - (0.5 * period);

	return pulse(x, 0.0, width);
}

float GetLuminance(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

vec3 DoLuminanceCorrection(vec3 color) {
    return color / GetLuminance(color);
}

float GetBiasFactor(float NdotLM) {
    float NdotLM2 = NdotLM * NdotLM;
    return 1.25 * (1.0 - NdotLM2 * NdotLM2) / NdotLM;
}

float GetHorizonFactor(float XdotU) {
    #ifdef SUN_MOON_HORIZON
        float horizon = clamp((XdotU + 0.1) * 10.0, 0.0, 1.0);
        horizon *= horizon;
        return horizon * horizon * (3.0 - 2.0 * horizon);
    #else
        float horizon = min(XdotU + 1.0, 1.0);
        horizon *= horizon;
        horizon *= horizon;
        return horizon * horizon;
    #endif
}

bool CheckForColor(vec3 albedo, vec3 check) { // Thanks to Builderb0y
    vec3 dif = albedo - check * 0.003921568;
    return dif == clamp(dif, vec3(-0.001), vec3(0.001));
}

bool CheckForStick(vec3 albedo) {
    return CheckForColor(albedo, vec3(40, 30, 11)) ||
            CheckForColor(albedo, vec3(73, 54, 21)) ||
            CheckForColor(albedo, vec3(104, 78, 30)) ||
            CheckForColor(albedo, vec3(137, 103, 39));
}

float GetMaxColorDif(vec3 color) {
    vec3 dif = abs(vec3(color.r - color.g, color.g - color.b, color.r - color.b));
    return max(dif.r, max(dif.g, dif.b));
}

vec3 RgbFrom256(int r, int g, int b) {
    return vec3(float(r)/256.0 ,float(g)/256.0 ,float(b)/256.0);
}

// Inspired by Inigo Quilez
// https://iquilezles.org/articles/palettes/
vec3 getRainbowColor(vec2 coord, float speed) {
    const vec3 rainbowColor = vec3(0.0, pi * 0.67, pi * 1.33);

    float t = frameTimeCounter * speed;
    t += sin(t) * (coord.x) + cos(t) * coord.y;

    return vec3(0.5) + vec3(0.5) * sin(rainbowColor + t);
}

vec3 saturateColors(vec3 col, float saturationMult) {
    float brightness = max(max(col.r, col.g), col.b);
    return (col - brightness) * saturationMult + brightness;
}

float Noise3D(vec3 p) {
    p.z = fract(p.z) * 128.0;
    float iz = floor(p.z);
    float fz = fract(p.z);
    vec2 a_off = vec2(23.0, 29.0) * (iz) / 128.0;
    vec2 b_off = vec2(23.0, 29.0) * (iz + 1.0) / 128.0;
    float a = texture2D(noisetex, p.xy + a_off).r;
    float b = texture2D(noisetex, p.xy + b_off).r;
    return mix(a, b, fz);
}

float fuzzyOr(float a, float b) {
    return clamp01(a + b - (a * b));
}

// Previous frame reprojection from Chocapic13
vec2 Reprojection(vec3 pos, vec3 cameraOffset) {
    pos = pos * 2.0 - 1.0;

    vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0);
    viewPosPrev /= viewPosPrev.w;
    viewPosPrev = gbufferModelViewInverse * viewPosPrev;

    vec4 previousPosition = viewPosPrev + vec4(cameraOffset, 0.0);
    previousPosition = gbufferPreviousModelView * previousPosition;
    previousPosition = gbufferPreviousProjection * previousPosition;
    return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
}

bool isViewMoving() {
    if (cameraPosition == previousCameraPosition) {
        mat3 previousModelView = mat3(gbufferPreviousModelView);
        mat3 currentModelView = mat3(gbufferModelView);

        for (int i = 0; i < 3; i++) {
            if(!all(lessThan(abs(previousModelView[i] - currentModelView[i]), vec3(0.001)))) return true;
        }
        return false;
    }
    return true;
}

vec3 changeColorFunction(vec3 color, float strength, vec3 changeColor, float uniformValue) {
    float luminanceColor = GetLuminance(color);
    color = mix(color, mix(color, vec3(luminanceColor), 0.88), uniformValue);
    return color *= mix(vec3(1.0), changeColor * luminanceColor * strength, uniformValue);
}

float isLightningActive() {
    float lightning = 0.0;
    #ifdef IS_IRIS
        lightning = lightningBoltPosition.w;
    #else
        lightning = lightningFlashOptifine * rainFactor * inRainy;
    #endif
    return lightning;
}

vec3 getLightningPos(vec3 playerPos, vec3 lightningBoltPosition, bool pointLight) {
    vec3 lightningPos = vec3(0.0);
    if (pointLight){
        lightningPos = lightningBoltPosition - playerPos;
    } else {
        // i like to offset the y of lightningBoltPosition to be ~100 blocks higher to give the effect of the light coming off the entire bolt, not just the point it hits.
        lightningPos = vec3(lightningBoltPosition.x, max(playerPos.y, lightningBoltPosition.y) + 2, lightningBoltPosition.z) - playerPos ;
    }
    return lightningPos;
}

vec2 lightningFlashEffect(vec3 lightningPos, vec3 normal, float lightDistance, float gradient, int subsurfaceMode) { // Thanks to Xonk!
    // point light, max distance is ~500 blocks (the maximum entity render distance), change lightDistance to change the reach
    float lightningLight = max(1.0 - length(lightningPos) / lightDistance, 0.0);

    // the light above ^^^ is a linear curve. me no likey. here's an exponential one instead.
    float lightningLightX = exp((1.0 - lightningLight) * -15.0);
    float lightningLightY = lightningLightX;
    if (subsurfaceMode == 1) lightningLightX *= exp((1.0 - lightningLightX) * -1.0) * 0.75; // make grass and others not as intense

    // good old NdotL
    // float NdotL = clamp(dot(lightningPos, -normal), 0.0, 1.0);
    float NdotL = clamp01(dot(normalize(lightningPos), normal));
    if (gradient > 0.0) NdotL = (NdotL * (1.0 - gradient)) + gradient;

    return vec2(lightningLightX * NdotL, lightningLightY);
}

float getBloodMoon(int moonPhase, float sunVisibility) {
    float visibility = 1.0 - sunVisibility;
    #if BLOOD_MOON == 0
        visibility = 0.0;
    #elif BLOOD_MOON == 1
        visibility -= moonPhase;
    #endif
    return clamp01(visibility);
}

void redstoneIPBR(inout vec3 color, inout float emission) {
    #ifdef REDSTONE_IPBR
        if (color.r * REDSTONE_IPBR_R > max(color.b * 1.15 * REDSTONE_IPBR_B, color.g * 3.5 * REDSTONE_IPBR_G) * 0.97) {
            emission = (4.5 - 2.25 * color.g) * 0.97 * REDSTONE_IPBR_I;
            color.rgb *= color.rgb;
        }
    #endif
}

float getTwinklingStars(vec2 coord, float speed){
    return clamp01((texture2D(noisetex, coord + frameTimeCounter * 0.0003 * speed).r - 0.5) * 10.0 + 0.5);
}

float GetStarNoise(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
}

float getStarEdgeFactor(vec2 fractPart, float starShape, float softness) {
    vec2 squareToCircle = fractPart - 0.5;
    float distFromCenter = length(squareToCircle);
    float maxComponent = max(abs(squareToCircle.x), abs(squareToCircle.y));
    
    // Interpolate between square and circle
    float shapeFactor = mix(maxComponent, distFromCenter, starShape);
    
    // Adjust the edge transition
    float edgeWidth = 0.05 + softness * 0.5;
    return smoothstep(0.5, 0.5 - edgeWidth, shapeFactor);
}

vec3 GetStarColor(vec2 starCoord, vec3 baseColor, vec3 starColor1, vec3 starColor2, vec3 starColor3, float starColorVariation) {   
    if (starColorVariation > 0.0) {
        int starColorDecider = int(mod((starCoord.x + starCoord.y) * 1000.0, 3.0));
        vec3 chosenColor = (starColorDecider == 0) ? starColor1 : 
                           (starColorDecider == 1) ? starColor2 : starColor3;
        
        baseColor = mix(chosenColor, vec3(GetStarNoise(starCoord)), (1.0 - starColorVariation) * 0.5);
    }    
    return baseColor;
}

vec3 movingCheckerboard(vec2 texCoord, float gridSize, float lineWidth, vec2 moveSpeed, vec3 lineColor) {
    vec2 checkerPixel = fract((texCoord + frameTimeCounter * moveSpeed) * viewSize / gridSize);

    vec2 lineThreshold = vec2(lineWidth / gridSize);
    if (any(lessThan(checkerPixel, lineThreshold)) || any(greaterThan(checkerPixel, 1.0 - lineThreshold))) {
        return lineColor;
    }
    return vec3(0.0);
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 hex2rgb(uint hex) {
    return vec3(
        float((hex >> 16) & 0xFFu) / 255.0,
        float((hex >> 8) & 0xFFu) / 255.0,
        float(hex & 0xFFu) / 255.0
    );
}

mat2 rotate(float angle)
{
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

float DoAutomaticEmission(inout bool noSmoothLighting, inout bool noDirectionalShading, vec3 color, float lmCoord, int blockLightEmission){
    noSmoothLighting = true, noDirectionalShading = true;

    float lightLevel = max(float(lmCoord > 0.99), blockLightEmission / 15.0);

    float baseEmission = pow3(GetLuminance(color)) * pow1_5(lightLevel);

    return max(0.0, (baseEmission - 0.1) * 2.5);
}

float hash1(uint n) {
    // The MIT License
    // Copyright © 2017 Inigo Quilez
    // Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    // integer hash copied from Hugo Elias
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uint(0x7fffffffU))/float(0x7fffffff);
}

float hash1(const in int p) {return hash1(uint(p));}

float hash11Modified(float a, float s)
{
    return fract(53.156*sin(a*45.45 + s))-.5;
}

#define UI0 1597334673U
#define UI1 3812015801U
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

vec3 hash33(const in uvec3 p) {
    uvec3 q = p * UI3;
    q = (q.x ^ q.y ^ q.z) * UI3;
return -1.0 + 2.0 * vec3(q) * UIF;
}

vec3 hash33(const in vec3 p) {return hash33(uvec3(p));}

// Hash Without Sine from https://www.shadertoy.com/view/4djSRW
// The MIT License
// Copyright (c)2014 David Hoskins.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// 1 out, 1 in...
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

// 1 out, 4 in
float hash14(vec4 p4)
{
	p4 = fract(p4  * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.x + p4.y) * (p4.z + p4.w));
}

// 2 out, 2 in...
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

// 1 out, 2 in...
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
//  1 out, 3 in...
float hash13(vec3 p3) {
    p3  = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

//  2 out, 1 in...
vec2 hash21(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

//  3 out, 1 in...
vec3 hash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

//  3 out, 2 in...
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

// by David Hoskins
// https://www.shadertoy.com/view/XdGfRR
// CC-BY-SA 4.0 license:
// https://creativecommons.org/licenses/by-sa/4.0/
//  2 out, 3 in
vec2 hash23(vec3 p) {
    uvec3 q = uvec3(ivec3(p)) * uvec3(1597334673u, 3812015801u, 2798796415u);
    uvec2 n = (q.x ^ q.y ^ q.z) * uvec2(1597334673u, 3812015801u);

    return vec2(n) / float(0xffffffffu);
}


// 1 out, 2 in... Simplex noise functions are (C) Ashima Arts and Stefan Gustavson
float smoothHash12(vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    vec2 a = vec2(1.0, 0.0);
    return mix(mix(hash12(p + a.yy), hash12(p + a.xy), f.x), mix(hash12(p + a.yx), hash12(p + a.xx), f.x), f.y);
}