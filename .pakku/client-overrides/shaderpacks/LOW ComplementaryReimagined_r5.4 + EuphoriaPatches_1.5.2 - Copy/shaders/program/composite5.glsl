/////////////////////////////////////
// Complementary Shaders by EminGT //
// With Euphoria Patches by SpacEagle17 //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

#if defined BLOOM_FOG || LENSFLARE_MODE > 0 && defined OVERWORLD
    flat in vec3 upVec, sunVec;
#endif

//Pipeline Constants//

//Common Variables//
float pw = 1.0 / viewWidth;
float ph = 1.0 / viewHeight;

vec2 view = vec2(viewWidth, viewHeight);

#if defined BLOOM_FOG || LENSFLARE_MODE > 0 && defined OVERWORLD
    float SdotU = dot(sunVec, upVec);
    float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
#endif

//Common Functions//
vec3 DoBSLTonemap(vec3 color) {
    color = T_EXPOSURE * color;
    color = color / pow(pow(color, vec3(TM_WHITE_CURVE)) + 1.0, vec3(1.0 / TM_WHITE_CURVE));
    color = pow(color, mix(vec3(T_LOWER_CURVE), vec3(T_UPPER_CURVE), sqrt(color)));

    return pow(color, vec3(1.0 / 2.2));
}

void linearToRGB(inout vec3 color) {
    const vec3 k = vec3(0.055);
    color = mix((vec3(1.0) + k) * pow(color, vec3(1.0 / 2.4)) - k, 12.92 * color, lessThan(color, vec3(0.0031308)));
}

void doColorAdjustments(inout vec3 color) {
    color = (T_EXPOSURE - 0.40) * color;
    // color = color / pow(pow(color, vec3(TM_WHITE_CURVE * 0.5)) + 1.0, vec3(1.0 / (TM_WHITE_CURVE * 0.5)));
    color = pow(color, mix(vec3(T_LOWER_CURVE - 0.20), vec3(T_UPPER_CURVE - 0.30), sqrt(color)));
}

float saturationTM = T_SATURATION;

vec3 LottesTonemap(vec3 color) {
    // Lottes 2016, "Advanced Techniques and Optimization of HDR Color Pipelines"
    // http://32ipi028l5q82yhj72224m8j.wpengine.netdna-cdn.com/wp-content/uploads/2016/03/GdcVdrLottes.pdf
    const vec3 a      = vec3(1.3);
    const vec3 d      = vec3(0.95);
    const vec3 hdrMax = vec3(8.0);
    const vec3 midIn  = vec3(0.25);
    const vec3 midOut = vec3(0.25);

    const vec3 a_d = a * d;
    const vec3 hdrMaxA = pow(hdrMax, a);
    const vec3 hdrMaxAD = pow(hdrMax, a_d);
    const vec3 midInA = pow(midIn, a);
    const vec3 midInAD = pow(midIn, a_d);
    const vec3 HM1 = hdrMaxA * midOut;
    const vec3 HM2 = hdrMaxAD - midInAD;

    const vec3 b = (-midInA + HM1) / (HM2 * midOut);
    const vec3 c = (hdrMaxAD * midInA - HM1 * midInAD) / (HM2 * midOut);

    color = pow(color, a) / (pow(color, a_d) * b + c);

    doColorAdjustments(color);

    linearToRGB(color);
    return color;
}

// From https://github.com/godotengine/godot/blob/master/servers/rendering/renderer_rd/shaders/effects/tonemap.glsl
// Adapted from https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
// (MIT License).
vec3 ACESTonemap(vec3 color) {
    float white = ACES_WHITE;
    const float exposure_bias = ACES_EXPOSURE;
    const float A = 0.0245786f;
    const float B = 0.000090537f;
    const float C = 0.983729f;
    const float D = 0.432951f;
    const float E = 0.238081f;

    const mat3 rgb_to_rrt = mat3(
            vec3(0.59719f * exposure_bias, 0.35458f * exposure_bias, 0.04823f * exposure_bias),
            vec3(0.07600f * exposure_bias, 0.90834f * exposure_bias, 0.01566f * exposure_bias),
            vec3(0.02840f * exposure_bias, 0.13383f * exposure_bias, 0.83777f * exposure_bias));

    const mat3 odt_to_rgb = mat3(
            vec3(1.60475f, -0.53108f, -0.07367f),
            vec3(-0.10208f, 1.10813f, -0.00605f),
            vec3(-0.00327f, -0.07276f, 1.07602f));
    color *= rgb_to_rrt;
    vec3 color_tonemapped = (color * (color + A) - B) / (color * (C * color + D) + E);
    color_tonemapped *= odt_to_rgb;

    white *= exposure_bias;
    float white_tonemapped = (white * (white + A) - B) / (white * (C * white + D) + E);

    color = color_tonemapped / white_tonemapped;
    color = clamp(color, vec3(0.0), vec3(1.0));
    doColorAdjustments(color);
    linearToRGB(color);
    return color;
}

vec3 ACESRedModified(vec3 color) {
    float white = ACES_WHITE;
    const float exposure_bias = ACES_EXPOSURE;
    const float A = 0.0245786f;
    const float B = 0.000090537f;
    const float C = 0.983729f;
    const float D = 0.432951f;
    const float E = 0.238081f;

    const mat3 rgb_to_rrt = mat3(
            vec3(0.50719f * exposure_bias, 0.40458f * exposure_bias, 0.03823f * exposure_bias),
            vec3(0.00700f * exposure_bias, 0.95834f * exposure_bias, 0.00966f * exposure_bias),
            vec3(0.00200f * exposure_bias, 0.15383f * exposure_bias, 0.83777f * exposure_bias));

    const mat3 odt_to_rgb = mat3(
            vec3(1.60475f, -0.53108f, -0.07367f),
            vec3(-0.10208f, 1.10813f, -0.00605f),
            vec3(-0.00327f, -0.07276f, 1.07602f));
    color *= rgb_to_rrt;
    vec3 color_tonemapped = (color * (color + A) - B) / (color * (C * color + D) + E);
    color_tonemapped *= odt_to_rgb;

    white *= exposure_bias;
    float white_tonemapped = (white * (white + A) - B) / (white * (C * white + D) + E);

    color = color_tonemapped / white_tonemapped;
    color = clamp(color, vec3(0.0), vec3(1.0));
    doColorAdjustments(color);
    linearToRGB(color);
    return color;
}

// Filmic tonemapping operator made by Jim Hejl and Richard Burgess
// Modified by Tech to not lose color information below 0.004
vec3 BurgessTonemap(vec3 rgb) {
       rgb = rgb * min(vec3(1.0), 1.0 - 0.8 * exp(1.0/-0.004 * rgb));
    rgb = (rgb * (6.2 * rgb + 0.5)) / (rgb * (6.2 * rgb + 1.7) + 0.06);
    doColorAdjustments(rgb);
    return rgb;
}

// Filmic tonemapping operator made by John Hable for Uncharted 2
vec3 uncharted2_tonemap_partial(vec3 color) {
    const float a = 0.15;
    const float b = 0.50;
    const float c = 0.10;
    const float d = 0.20;
    const float e = 0.02;
    const float f = 0.30;
    color = ((color * (a * color + (c * b)) + (d * e)) / (color * (a * color + b) + d * f)) - e / f;
    doColorAdjustments(color);
    linearToRGB(color);
    return color;
}

vec3 uncharted2_filmic(vec3 v) {
    float exposure_bias = 1.0f;
    vec3 curr = uncharted2_tonemap_partial(v * exposure_bias);

    vec3 W = vec3(11.2f);
    vec3 white_scale = vec3(1.0f) / uncharted2_tonemap_partial(W);
    v = curr * white_scale;
    doColorAdjustments(v);
    linearToRGB(v);
    return v;
}

vec3 reinhard2(vec3 x) {
    const float L_white = 4.0;
    linearToRGB(x);
      x = (x * (1.1 + x / (L_white * L_white))) / (1.0 + x);
    doColorAdjustments(x);
    return x;
}

vec3 filmic(vec3 x) {
    linearToRGB(x);
    vec3 X = max(vec3(0.0), x - 0.004);
    vec3 result = (X * (6.2 * X + 0.5)) / (X * (6.2 * X + 1.7) + 0.06);
    x = pow(result, vec3(2.2));
    doColorAdjustments(x);
    return x;
}

float GTTonemap(float x) { // source https://gist.github.com/shakesoda/1dcb3e159f586995ca076c8b21f05a67
    float m = 0.22; // linear section start
    float a = 1.0;  // contrast
    float c = 1.33; // black brightness
    float P = 1.0;  // maximum brightness
    float l = 0.4;  // linear section length
    float l0 = ((P-m)*l) / a; // 0.312
    float S0 = m + l0; // 0.532
    float S1 = m + a * l0; // 0.532
    float C2 = (a*P) / (P - S1); // 2.13675213675
    float L = m + a * (x - m);
    float T = m * pow(x/m, c);
    float S = P - (P - S1) * exp(-C2*(x - S0)/P);
    float w0 = 1 - smoothstep(0.0, m, x);
    float w2 = (x < m+l)?0:1;
    float w1 = 1 - w0 - w2;
    return float(T * w0 + L * w1 + S * w2);
}

// this costs about 0.2-0.3ms more than aces, as-is
vec3 GTTonemap(vec3 x) {
    linearToRGB(x);
    x = vec3(GTTonemap(x.r), GTTonemap(x.g), GTTonemap(x.b));
    doColorAdjustments(x);
    return x;
}

vec3 uchimura(vec3 x, float P, float a, float m, float l, float c, float b) { //Uchimura, H. (2017). HDR Theory and practice. https://www.slideshare.net/nikuque/hdr-theory-and-practicce-jp; https://github.com/dmnsgn/glsl-tone-map/blob/main/uchimura.glsl
    float l0 = ((P - m) * l) / a;
    float L0 = m - m / a;
    float L1 = m + (1.0 - m) / a;
    float S0 = m + l0;
    float S1 = m + a * l0;
    float C2 = (a * P) / (P - S1);
    float CP = -C2 / P;

    vec3 w0 = vec3(1.0 - smoothstep(0.0, m, x));
    vec3 w2 = vec3(step(m + l0, x));
    vec3 w1 = vec3(1.0 - w0 - w2);

    vec3 T = vec3(m * pow(x / m, vec3(c)) + b);
    vec3 S = vec3(P - (P - S1) * exp(CP * (x - S0)));
    vec3 L = vec3(m + a * (x - m));

    return T * w0 + L * w1 + S * w2;
}

vec3 uchimura(vec3 color) {
    const float P = 1.0;  // max display brightness
    const float a = 1.0;  // contrast
    const float m = 0.22; // linear section start
    const float l = 0.4;  // linear section length
    const float c = 1.33; // black
    const float b = 0.0;  // pedestal
    linearToRGB(color);
    color = uchimura(color, P, a, m, l, c, b);
    doColorAdjustments(color);
    return color;
}

// const mat3 agxTransform = mat3(
//     0.842479062253094 , 0.0423282422610123, 0.0423756549057051,
//     0.0784335999999992, 0.878468636469772 , 0.0784336,
//     0.0792237451477643, 0.0791661274605434, 0.879142973793104
// );

// const mat3 agxTransformInverse = mat3(
//      1.19687900512017  , -0.0528968517574562, -0.0529716355144438,
//     -0.0980208811401368,  1.15190312990417  , -0.0980434501171241,
//     -0.0990297440797205, -0.0989611768448433,  1.15107367264116
// );

// vec3 agxDefaultContrastApproximation(vec3 x) {
//     vec3 x2 = x * x;
//     vec3 x4 = x2 * x2;

//     return + 15.5     * x4 * x2
//            - 40.14    * x4 * x
//            + 31.96    * x4
//            - 6.868    * x2 * x
//            + 0.4298   * x2
//            + 0.1191   * x
//            - 0.00232;
// }

// void agx(inout vec3 color) {
//     const float minEv = -12.47393;
//     const float maxEv = 4.026069;

//     color = agxTransform * color;
//     color = clamp(log2(color), minEv, maxEv);
//     color = (color - minEv) / (maxEv - minEv);
//     color = agxDefaultContrastApproximation(color);
// }

// void agxEotf(inout vec3 color) {
//     color = agxTransformInverse * color;
// }

// void agxLook(inout vec3 color) {
//     #if AGX_LOOK == 0 // Default
//         const vec3 slope = vec3(1.0);
//         const vec3 power = vec3(1.0);
//     #elif AGX_LOOK == 1 // Golden
//         const vec3 slope = vec3(1.0, 0.9, 0.5);
//         const vec3 power = vec3(0.8);
//         saturationTM *= 0.8;
//     #elif AGX_LOOK == 2 // Punchy
//         const vec3 slope = vec3(1.1);
//         const vec3 power = vec3(1.2);
//         saturationTM *= 1.2;
//     #else
//         const vec3 slope = vec3(AGX_R, AGX_G, AGX_B) / 256;
//         const vec3 power = vec3(AGX_POWER);
//     #endif

//     color = pow(color * slope, power);
// }

// vec3 agxTonemap(vec3 color) { // Minimal version of Troy Sobotka's AgX by bwrensch https://www.shadertoy.com/view/cd3XWr
//     agx(color);
//     agxLook(color);
//     agxEotf(color);
//     doColorAdjustments(color);
//     return color;
// }

vec3 agxDefaultContrastApprox(vec3 x) {
  vec3 x2 = x * x;
  vec3 x4 = x2 * x2;
  
  return x*(+0.12410293f
    +x*(+0.2078625f
    +x*(-5.9293431f
    +x*(+30.376821f
    +x*(-38.901506f
    +x*(+15.122061f))))));
}

vec3 agx(vec3 val) {
    const mat3 agx_mat = mat3(
        0.842479062253094, 0.0423282422610123, 0.0423756549057051,
        0.0784335999999992,  0.878468636469772,  0.0784336,
        0.0792237451477643, 0.0791661274605434, 0.879142973793104);
    const float minEv = -12.47393f;
    const float maxEv = 4.026069f;

    // Input transform
    val = agx_mat * val;
    
    // Log2 space encoding
    val = clamp(log2(val), minEv, maxEv);
    val = (val - minEv) / (maxEv - minEv);
    
    // Apply sigmoid function approximation
    val = agxDefaultContrastApprox(val);

    return val;
}

vec3 inv_agx(vec3 val) {
    const mat3 inv_agx_mat = mat3(
        1.1968790051201738155, -0.052896851757456180321, -0.052971635514443794537,
        -0.098020881140136776078,  1.1519031299041727435,  -0.098043450117124120312,
        -0.099029744079720471434, -0.098961176844843346553, 1.1510736726411610622);

    // Input transform
    val = inv_agx_mat * val;

    return val;
}

vec3 agxLook(vec3 val) {
    const vec3 lw = vec3(0.2126, 0.7152, 0.0722);
    float luma = dot(val, lw);

    vec3 offset = vec3(0.0);

    #if AGX_LOOK == 0
        // Default
        const vec3 slope = vec3(1.0);
        const vec3 power = vec3(1.0);
        const float sat = 1.0;
    #elif AGX_LOOK == 1
        // Golden
        const vec3 slope = vec3(1.0, 0.9, 0.5);
        const vec3 power = vec3(0.8);
        const float sat = 0.8;
    #elif AGX_LOOK == 2
        // Punchy
        const vec3 slope = vec3(1.0);
        const vec3 power = vec3(1.35, 1.35, 1.35);
        const float sat = 1.4;
    #else
        const vec3 slope = vec3(AGX_R, AGX_G, AGX_B) / 256;
        const vec3 power = vec3(AGX_POWER);
        const float sat = AGX_SATURATION;
    #endif

    // ASC CDL
    val = pow(val * slope + offset, power);
    return luma + sat * (val - luma);
}

vec3 agxTonemap(vec3 color) { // Minimal version of Troy Sobotka's AgX by bwrensch https://www.shadertoy.com/view/mdcSDH
    color = agx(color);
    color = agxLook(color);
    color = inv_agx(color);
    doColorAdjustments(color);
    return color;
}

void DoBSLColorSaturation(inout vec3 color) {
    float grayVibrance = (color.r + color.g + color.b) / 3.0;
    float graySaturation = grayVibrance;
    if (saturationTM < 1.00) graySaturation = dot(color, vec3(0.299, 0.587, 0.114));

    float mn = min(color.r, min(color.g, color.b));
    float mx = max(color.r, max(color.g, color.b));
    float sat = (1.0 - (mx - mn)) * (1.0 - mx) * grayVibrance * 5.0;
    vec3 lightness = vec3((mn + mx) * 0.5);

    color = mix(color, mix(color, lightness, 1.0 - T_VIBRANCE), sat);
    color = mix(color, lightness, (1.0 - lightness) * (2.0 - T_VIBRANCE) / 2.0 * abs(T_VIBRANCE - 1.0));
    color = color * saturationTM - graySaturation * (saturationTM - 1.0);
}

#ifdef BLOOM
    vec2 rescale = max(vec2(viewWidth, viewHeight) / vec2(1920.0, 1080.0), vec2(1.0));
    vec3 GetBloomTile(float lod, vec2 coord, vec2 offset) {
        float scale = exp2(lod);
        vec2 bloomCoord = coord / scale + offset;
        bloomCoord = clamp(bloomCoord, offset, 1.0 / scale + offset);

        vec3 bloom = texture2D(colortex3, bloomCoord / rescale).rgb;
        bloom *= bloom;
        bloom *= bloom;
        return bloom * 128.0;
    }

    void DoBloom(inout vec3 color, vec2 coord, float dither, float lViewPos) {
        vec3 blur1 = GetBloomTile(2.0, coord, vec2(0.0      , 0.0   ));
        vec3 blur2 = GetBloomTile(3.0, coord, vec2(0.0      , 0.26  ));
        vec3 blur3 = GetBloomTile(4.0, coord, vec2(0.135    , 0.26  ));
        vec3 blur4 = GetBloomTile(5.0, coord, vec2(0.2075   , 0.26  ));
        vec3 blur5 = GetBloomTile(6.0, coord, vec2(0.135    , 0.3325));
        vec3 blur6 = GetBloomTile(7.0, coord, vec2(0.160625 , 0.3325));
        vec3 blur7 = GetBloomTile(8.0, coord, vec2(0.1784375, 0.3325));

        vec3 blur = (blur1 + blur2 + blur3 + blur4 + blur5 + blur6 + blur7) * 0.14;

        float bloomStrength = BLOOM_STRENGTH + 0.2 * darknessFactor;

        #if defined BLOOM_FOG && defined NETHER && defined BORDER_FOG
            float farM = min(renderDistance, NETHER_VIEW_LIMIT); // consistency9023HFUE85JG
            float netherBloom = lViewPos / clamp(farM, 96.0, 256.0);
            netherBloom *= netherBloom;
            netherBloom *= netherBloom;
            netherBloom = 1.0 - exp(-8.0 * netherBloom);
            netherBloom *= 1.0 - maxBlindnessDarkness;
            bloomStrength = mix(bloomStrength * 0.7, bloomStrength * 1.8, netherBloom);
        #endif

        color = mix(color, blur, bloomStrength);
        //color += blur * bloomStrength * (ditherFactor.x + ditherFactor.y);
    }
#endif

#include "/lib/util/colorConversion.glsl"

#if COLORED_LIGHTING_INTERNAL > 0
    #include "/lib/misc/voxelization.glsl"
#endif

// http://www.diva-portal.org/smash/get/diva2:24136/FULLTEXT01.pdf
// The MIT License
// Copyright © 2024 Benjamin Stott "sixthsurge"
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
vec3 purkinjeShift(vec3 rgb, vec4 texture6, vec3 playerPos, float lViewPos, float purkinjeOverwrite) {
    #ifdef NETHER
        #define PURKINKE_INTENSITY NIGHT_DESATURATION_NETHER
    #elif defined END
        #define PURKINKE_INTENSITY NIGHT_DESATURATION_END
        nightFactor = 1.0;
    #else
        #define PURKINKE_INTENSITY NIGHT_DESATURATION_OW
    #endif

    float renderDistanceFade = mix(0, lViewPos * 2.5 / renderDistance, PURKINJE_RENDER_DISTANCE_FADE);
    float nightCaveDesaturation = NIGHT_CAVE_DESATURATION * 0.1;
    
    float interiorFactor = isEyeInWater == 1 ? 0.0 : pow2(1.0 - texture6.b);
    interiorFactor =  mix(interiorFactor, 0, renderDistanceFade);
    interiorFactor -= sqrt2(eyeBrightnessM) * 0.66;
    interiorFactor = smoothstep(0.0, 1.0, interiorFactor);

    // return vec3(interiorFactor);

    float lightSourceFactor = 1.0;
    #ifdef NIGHT_DESATURATION_REMOVE_NEAR_LIGHTS
        lightSourceFactor = pow3(1.0 - texture6.a);

        #if COLORED_LIGHTING_INTERNAL > 0
            vec3 voxelPos = SceneToVoxel(playerPos);

            vec4 lightVolume = vec4(0.0);
            if (CheckInsideVoxelVolume(voxelPos)) {
                vec3 voxelPosM = clamp01(voxelPos / vec3(voxelVolumeSize));
                lightVolume = GetLightVolume(voxelPosM);
                lightVolume = sqrt(lightVolume);
            }
            lightSourceFactor *= pow6(1.0 - lightVolume.a * 3); // Remove purkinje shift in ACL light
        #endif
        lightSourceFactor += renderDistanceFade;
        lightSourceFactor = clamp01(lightSourceFactor);
    #endif

    float heldLight = 1.0;
    #ifdef NIGHT_DESATURATION_REMOVE_LIGHTS_IN_HAND
        heldLight = max(heldBlockLightValue, heldBlockLightValue2);
        if (heldLight > 0){
            if (heldItemId == 45032 || heldItemId2 == 45032) heldLight = 15; // Lava Bucket
            heldLight = clamp(heldLight, 0.0, 15.0);
            heldLight = sqrt2(heldLight / 15.0) * -1.0 + 1.0; // Normalize and invert
            heldLight = mix(heldLight, 1.0, clamp01(lViewPos * 15 / renderDistance)); // Only do it around the player
        } else {
            heldLight = 1.0;
        }
    #endif

    float nightVisionFactor = 1.0;
    #ifdef NIGHT_DESATURATION_REMOVE_NIGHT_VISION
        nightVisionFactor = nightVision * -1.0 + 1.0;
    #endif

    float purkinjeIntensity = 0.004 * purkinjeOverwrite * PURKINKE_INTENSITY;
    purkinjeIntensity  = purkinjeIntensity * fuzzyOr(interiorFactor, sqrt2(nightFactor)); // No purkinje shift in daylight
    purkinjeIntensity *= lightSourceFactor; // Reduce purkinje intensity in blocklight
    purkinjeIntensity *= clamp01(nightCaveDesaturation + (1.0 - nightCaveDesaturation) * pow3(1.0 - interiorFactor)); // Reduce purkinje intensity underground
    purkinjeIntensity *= clamp01(heldLight); // Reduce purkinje intensity when holding light sources
    purkinjeIntensity *= nightVisionFactor * (1.0 - isLightningActive()); // Reduce purkinje intensity when using night vision or during lightning
    purkinjeIntensity = clamp(purkinjeIntensity, 0.01, 1.0); // prevent it going to 0 to avoid NaNs
    
    #if PURKINKE_INTENSITY < 300
        const vec3 purkinjeTint = vec3(0.5, 0.7, 1.0) * rec709ToRec2020;
        const vec3 rodResponse = vec3(7.15e-5, 4.81e-1, 3.28e-1) * rec709ToRec2020;

        vec3 xyz = rgb * rec2020ToXyz;

        vec3 scotopicLuminance = xyz * (1.33 * (1.0 + (xyz.y + xyz.z) / xyz.x) - 0.5);

        float purkinje = dot(rodResponse, scotopicLuminance * xyzToRec2020) * 0.45;

        rgb = mix(rgb, purkinje * purkinjeTint, exp2(-rcp(purkinjeIntensity) * purkinje));
    #else
        rgb = mix(rgb, vec3(GetLuminance(rgb) * 0.9), clamp01(purkinjeIntensity));
    #endif

    // return vec3(purkinjeIntensity);

    return max0(rgb);
}

//Includes//
#ifdef BLOOM_FOG
    #include "/lib/atmospherics/fog/bloomFog.glsl"
#endif

#ifdef BLOOM
    #include "/lib/util/dither.glsl"
#endif

#if LENSFLARE_MODE > 0 && defined OVERWORLD
    #include "/lib/misc/lensFlare.glsl"
#endif

#include "/lib/util/spaceConversion.glsl"

//Program//
void main() {
    vec3 color = texture2D(colortex0, texCoord).rgb;

    #if defined BLOOM_FOG || LENSFLARE_MODE > 0 && defined OVERWORLD || defined NIGHT_DESATURATION
        float z0 = texture2D(depthtex0, texCoord).r;

        vec4 screenPos = vec4(texCoord, z0, 1.0);
        vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;
        float lViewPos = length(viewPos.xyz);

        vec3 playerPos = ViewToPlayer(viewPos.xyz);

        #if defined DISTANT_HORIZONS && defined NETHER
            float z0DH = texelFetch(dhDepthTex, texelCoord, 0).r;
            vec4 screenPosDH = vec4(texCoord, z0DH, 1.0);
            vec4 viewPosDH = dhProjectionInverse * (screenPosDH * 2.0 - 1.0);
            viewPosDH /= viewPosDH.w;
            lViewPos = min(lViewPos, length(viewPosDH.xyz));
        #endif
    #else
        float lViewPos = 0.0;
    #endif

    float dither = texture2D(noisetex, texCoord * view / 128.0).b;
    #ifdef TAA
        dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
    #endif

    #ifdef BLOOM_FOG
        color /= GetBloomFog(lViewPos);
    #endif

    #ifdef BLOOM
        DoBloom(color, texCoord, dither, lViewPos);
    #endif

    #ifdef COLORGRADING
        color =
            pow(color.r, GR_RC) * vec3(GR_RR, GR_RG, GR_RB) +
            pow(color.g, GR_GC) * vec3(GR_GR, GR_GG, GR_GB) +
            pow(color.b, GR_BC) * vec3(GR_BR, GR_BG, GR_BB);
        color *= 0.01;
    #endif

    #ifdef TONEMAP_COMPARISON
        color = texCoord.x < mix(0.5, 0.0, isSneaking) ? tonemap_left(color) : tonemap_right(color); // Thanks to SixthSurge
    #else
        #ifndef SPOOKY
            color = tonemap(color);
        #else
            color = LottesTonemap(color);
        #endif
    #endif
    color = clamp01(color);

    #if defined GREEN_SCREEN_LIME || defined BLUE_SCREEN || SELECT_OUTLINE == 4 || defined NIGHT_DESATURATION
        vec4 texture6 = texelFetch(colortex6, texelCoord, 0);
        int materialMaskInt = int(texture6.g * 255.1);
    #endif
    float purkinjeOverwrite = 1.0;

    #ifdef GREEN_SCREEN_LIME
        if (materialMaskInt == 240) { // Green Screen Lime Blocks
            color = vec3(0.0, 1.0, 0.0);
            purkinjeOverwrite = 0.0;
        }
    #endif
    #ifdef BLUE_SCREEN
        if (materialMaskInt == 239) { // Blue Screen Blue Blocks
            color = vec3(0.0, 0.0, 1.0);
            purkinjeOverwrite = 0.0;
        }
    #endif

    #if SELECT_OUTLINE == 4 || defined NIGHT_DESATURATION
        if (materialMaskInt == 252) { // Selection Outline
            #if SELECT_OUTLINE == 4 // Versatile Selection Outline
                float colorMF = 1.0 - dot(color, vec3(0.25, 0.45, 0.1));
                colorMF = smoothstep1(smoothstep1(smoothstep1(smoothstep1(smoothstep1(colorMF)))));
                color = mix(color, 3.0 * (color + 0.2) * vec3(colorMF * SELECT_OUTLINE_I), 0.3);
            #endif
            purkinjeOverwrite = 0.0;
        }
    #endif

    #if LENSFLARE_MODE > 0 && defined OVERWORLD
        DoLensFlare(color, viewPos.xyz, dither);
    #endif

    DoBSLColorSaturation(color);

    #ifdef VIGNETTE_R
        vec2 texCoordMin = texCoord.xy - 0.5;
        float vignette = 1.0 - dot(texCoordMin, texCoordMin) * (1.0 - GetLuminance(color));
        color *= vignette;
    #endif

    float filmGrain = dither;
    color += vec3((filmGrain - 0.25) / 128.0);

    #ifdef NIGHT_DESATURATION
        color.rgb = purkinjeShift(color.rgb, texture6, playerPos, lViewPos, purkinjeOverwrite);
    #endif

    // vec4 texture6 = texelFetch(colortex6, texelCoord, 0).rgba;
    // float interiorFactor = texture6.b;

    // color = vec3(interiorFactor);

    /* DRAWBUFFERS:3 */
    gl_FragData[0] = vec4(color, 1.0);
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

#if defined BLOOM_FOG || LENSFLARE_MODE > 0 && defined OVERWORLD
    flat out vec3 upVec, sunVec;
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    #if defined BLOOM_FOG || LENSFLARE_MODE > 0 && defined OVERWORLD
        upVec = normalize(gbufferModelView[1].xyz);
        sunVec = GetSunVector();
    #endif
}

#endif
