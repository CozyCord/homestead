/////////////////////////////////////
// Complementary Shaders by EminGT //
// With Euphoria Patches by SpacEagle17 //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

flat in int mat;

in vec2 lmCoord;

flat in vec3 upVec, sunVec, northVec, eastVec;
in vec3 normal;
in vec3 playerPos;

in vec4 glColor;

//Pipeline Constants//

//Common Variables//
float NdotU = dot(normal, upVec);
float NdotUmax0 = max(NdotU, 0.0);
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;

vec2 lmCoordM = lmCoord;

#ifdef OVERWORLD
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
    vec3 lightVec = sunVec;
#endif

//Includes//
#include "/lib/util/spaceConversion.glsl"
#include "/lib/util/dither.glsl"

#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif

#if defined ATM_COLOR_MULTS || defined SPOOKY
    #include "/lib/colors/colorMultipliers.glsl"
#endif

#ifdef AURORA_INFLUENCE
    #include "/lib/atmospherics/auroraBorealis.glsl"
#endif

#define GBUFFERS_TERRAIN
    #include "/lib/lighting/mainLighting.glsl"
#undef GBUFFERS_TERRAIN

#ifdef SNOWY_WORLD
    #include "/lib/materials/materialMethods/snowyWorld.glsl"
#endif
#if SEASONS > 0 || defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
    #include "/lib/materials/overlayNoise.glsl"
#endif

//Program//
void main() {
    vec4 color = vec4(glColor.rgb, 1.0);

    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    #ifdef TAA
        vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
    #else
        vec3 viewPos = ScreenToView(screenPos);
    #endif
    float lViewPos = length(playerPos);
    vec3 nViewPos = normalize(viewPos);
    float VdotU = dot(nViewPos, upVec);
    float VdotS = dot(nViewPos, sunVec);
    vec3 worldPos = playerPos + cameraPosition;
    vec3 beforeTransformPos = playerPos;

    float dither = Bayer64(gl_FragCoord.xy);
    #ifdef TAA
        dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
    #endif

    #if defined ATM_COLOR_MULTS || defined SPOOKY
        atmColorMult = GetAtmColorMult();
    #endif

    bool noSmoothLighting = false, noDirectionalShading = false, noVanillaAO = false, centerShadowBias = false;
    int subsurfaceMode = 0;
    float smoothnessG = 0.0, smoothnessD = 0.0, highlightMult = 1.0, emission = 0.0, snowFactor = 1.0, snowMinNdotU = 0.0;
    vec3 normalM = normal, geoNormal = normal, shadowMult = vec3(1.0);
    vec3 worldGeoNormal = normalize(ViewToPlayer(geoNormal * 10000.0));

    float overlayNoiseIntensity = 1.0;
    float snowNoiseIntensity = 1.0;
    float sandNoiseIntensity = 1.0;
    float mossNoiseIntensity = 1.0;
    float overlayNoiseTransparentOverwrite = 0.0;
    float overlayNoiseEmission = 1.0;
    float IPBRMult = 1.0;
    bool isFoliage = false;
    vec3 dhColor = color.rgb;
    float purkinjeOverwrite = 0.0;

    float lavaNoiseIntensity = LAVA_NOISE_INTENSITY;

    if (mat == DH_BLOCK_LEAVES) {
        #include "/lib/materials/specificMaterials/terrain/leaves.glsl"
        isFoliage = true;
        mossNoiseIntensity = 0.0;
        sandNoiseIntensity = 0.3;
        #ifdef SPOOKY
            int seed = worldDay / 2; // Thanks to Bálint
            int currTime = (worldDay % 2) * 24000 + worldTime; // Effect happens every 2 minecraft days
            float randomTime = 24000 * hash1(worldDay * 5); // Effect happens randomly throughout the day
            int timeWhenItHappens = (int(hash1(seed)) % (2 * 24000)) + int(randomTime);
            if (currTime > timeWhenItHappens && currTime < timeWhenItHappens + 100) { // 100 in ticks - 5s, how long the effect will be on, aka leaves are gone
                discard; // disable leaves
            }
        #endif
    } else if (mat == DH_BLOCK_GRASS) {
        smoothnessG = pow2(color.g) * 0.85;
    } else if (mat == DH_BLOCK_ILLUMINATED) {
        emission = 2.5;
        snowNoiseIntensity = 0.0;
        sandNoiseIntensity = 0.2;
        mossNoiseIntensity = 0.2;
    } else if (mat == DH_BLOCK_SNOW) {
        overlayNoiseIntensity = 0.0;
        #ifdef SSS_SNOW_ICE
            subsurfaceMode = 3, noSmoothLighting = true, noDirectionalShading = true;
        #endif
    } else if (mat == DH_BLOCK_LAVA) {
        overlayNoiseIntensity = 0.0;
        emission = 1.5;

        #ifdef SOUL_SAND_VALLEY_OVERHAUL_INTERNAL
            color.rgb = changeColorFunction(color.rgb, 3.0, colorSoul, inSoulValley);
            color.rgb = mix(color.rgb, (color.rgb - 0.5) * 1.35 + 0.5, inSoulValley); // increase contrast
        #endif
        #ifdef PURPLE_END_FIRE_INTERNAL
            color.rgb = changeColorFunction(color.rgb, 2.5, colorEndBreath * 1.4, 1.0);
            color.rgb = (color.rgb - 0.5) * 1.3 + 0.5;
        #endif

        vec3 lavaNoiseColor = color.rgb;
        #if LAVA_VARIATION > 0
            vec2 lavaPos = (floor(worldPos.xz * 16.0) + worldPos.y * 32.0) * 0.000666;
            vec2 wind = vec2(frameTimeCounter * 0.012, 0.0);
            #ifndef IPBR
                lavaNoiseIntensity *= 0.95;
            #endif
            #include "/lib/materials/specificMaterials/terrain/lavaNoise.glsl"
            color.rgb = lavaNoiseColor;
        #else
            if (LAVA_TEMPERATURE != 0.0) color.rgb += LAVA_TEMPERATURE * 0.3;
        #endif
    }

    #ifdef SNOWY_WORLD
        DoSnowyWorld(color, smoothnessG, highlightMult, smoothnessD, emission,
                     playerPos, lmCoord, snowFactor, snowMinNdotU, NdotU, subsurfaceMode);
    #endif

    float lengthCylinder = max(length(playerPos.xz), abs(playerPos.y));
    highlightMult *= 0.5 + 0.5 * pow2(1.0 - smoothstep(far, far * 1.5, lengthCylinder));
    color.a *= smoothstep(far * 0.5, far * 0.7, lengthCylinder);
    if (color.a < dither) discard;

    vec3 noisePos = floor((playerPos + cameraPosition) * 4.0 + 0.001) / 32.0;
    float noiseTexture = Noise3D(noisePos) + 0.5;
    float noiseFactor = max0(1.0 - 0.3 * dot(color.rgb, color.rgb));
    color.rgb *= pow(noiseTexture, 0.6 * noiseFactor);

    #if defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
        #define GBUFFERS_TERRAIN
        #include "/lib/materials/overlayNoiseApply.glsl"
        #undef GBUFFERS_TERRAIN
    #endif
    #if SEASONS > 0
        #define GBUFFERS_TERRAIN
        #include "/lib/materials/seasons.glsl"
        #undef GBUFFERS_TERRAIN
    #endif

    #if defined SPOOKY && BLOOD_MOON > 0
        auroraSpookyMix = getBloodMoon(moonPhase, sunVisibility);
        ambientColor *= 1.0 + auroraSpookyMix * vec3(2.0, -1.0, -1.0);
    #endif
    #ifdef AURORA_INFLUENCE
        ambientColor = mix(AuroraAmbientColor(ambientColor, viewPos), ambientColor, auroraSpookyMix);
    #endif

    #if MONOTONE_WORLD > 0
        #if MONOTONE_WORLD == 1
            color.rgb = vec3(1.0);
        #elif MONOTONE_WORLD == 2
            color.rgb = vec3(0.0);
        #else
            color.rgb = vec3(0.5);
        #endif
    #endif

    DoLighting(color, shadowMult, playerPos, viewPos, lViewPos, geoNormal, normalM,
               worldGeoNormal, lmCoordM, noSmoothLighting, noDirectionalShading, noVanillaAO,
               centerShadowBias, subsurfaceMode, smoothnessG, highlightMult, emission, purkinjeOverwrite);
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

flat out int mat;

out vec2 lmCoord;

flat out vec3 upVec, sunVec, northVec, eastVec;
out vec3 normal;
out vec3 playerPos;

out vec4 glColor;

//Attributes//

//Common Variables//

//Common Functions//

//Includes//
#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif
#if defined MIRROR_DIMENSION || defined WORLD_CURVATURE
    #include "/lib/misc/distortWorld.glsl"
#endif

//Program//
void main() {
    gl_Position = ftransform();
    #ifdef TAA
        gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    #endif

    mat = dhMaterialId;

    lmCoord  = GetLightMapCoordinates();

    normal = normalize(gl_NormalMatrix * gl_Normal);
    upVec = normalize(gbufferModelView[1].xyz);
    eastVec = normalize(gbufferModelView[0].xyz);
    northVec = normalize(gbufferModelView[2].xyz);
    sunVec = GetSunVector();

    playerPos = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz;

    glColor = gl_Color;

    #if defined MIRROR_DIMENSION || defined WORLD_CURVATURE || defined WAVE_EVERYTHING
        vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
        #ifdef MIRROR_DIMENSION
            doMirrorDimension(position);
        #endif
        #ifdef WORLD_CURVATURE
            position.y += doWorldCurvature(position.xz);
        #endif
        #ifdef WAVE_EVERYTHING
            DoWaveEverything(position.xyz);
        #endif
        gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
    #endif
}

#endif
