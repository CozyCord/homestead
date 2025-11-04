/////////////////////////////////////
// Complementary Shaders by EminGT //
// With Euphoria Patches by SpacEagle17 //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

flat in int mat;
flat in int blockLightEmission;

in vec2 texCoord;
in vec2 lmCoord;
in vec2 signMidCoordPos;
flat in vec2 absMidCoordPos;
flat in vec2 midCoord;
in vec3 blockUV;
in vec3 atMidBlock;
// #if SEASONS == 1 || SEASONS == 4 || defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
//     flat in ivec2 pixelTexSize;
// #endif

flat in vec3 upVec, sunVec, northVec, eastVec;
in vec3 normal;

in vec4 glColorRaw;

#if RAIN_PUDDLES >= 1 || defined SPOOKY_RAIN_PUDDLE_OVERRIDE || defined GENERATED_NORMALS || defined CUSTOM_PBR
    flat in vec3 binormal, tangent;
#endif

#ifdef POM
    in vec3 viewVector;

    in vec4 vTexCoordAM;
#endif

#if ANISOTROPIC_FILTER > 0
    in vec4 spriteBounds;
#endif

in vec4 beforeTransformPos;

//Pipeline Constants//
#if END_CRYSTAL_VORTEX_INTERNAL > 0 || DRAGON_DEATH_EFFECT_INTERNAL > 0
    const float voxelDistance = 128.0;
#elif COLORED_LIGHTING_INTERNAL > 0
    const float voxelDistance = 32.0;
#endif

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
float skyLightCheck = 0.0;

vec4 glColor = glColorRaw;

#ifdef OVERWORLD
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
    vec3 lightVec = sunVec;
#endif

#if RAIN_PUDDLES >= 1 || defined SPOOKY_RAIN_PUDDLE_OVERRIDE || defined GENERATED_NORMALS || defined CUSTOM_PBR
    mat3 tbnMatrix = mat3(
        tangent.x, binormal.x, normal.x,
        tangent.y, binormal.y, normal.y,
        tangent.z, binormal.z, normal.z
    );
#endif

//Common Functions//
void DoFoliageColorTweaks(inout vec3 color, inout vec3 shadowMult, inout float snowMinNdotU, vec3 viewPos, vec3 nViewPos, float lViewPos, float dither) {
    #ifdef DREAM_TWEAKED_LIGHTING
        return;
    #endif
    float factor = max(80.0 - lViewPos, 0.0);
    shadowMult *= 1.0 + 0.004 * noonFactor * factor;

    if (signMidCoordPos.x < 0.0) color.rgb *= 1.08;
    else color.rgb *= 0.93;

    #ifdef FOLIAGE_ALT_SUBSURFACE
        float edgeSize = 0.12;
        float edgeEffectFactor = 0.75;

        edgeEffectFactor *= (sqrt1(abs(dot(nViewPos, normal))) - 0.1) * 1.111;

        vec2 texCoordM = texCoord;
             texCoordM.y -= edgeSize * pow2(dither) * absMidCoordPos.y;
             texCoordM.y = max(texCoordM.y, midCoord.y - absMidCoordPos.y);
        vec4 colorSample = texture2DLod(tex, texCoordM, 0);

        if (colorSample.a < 0.5) {
            float edgeFactor = dot(nViewPos, lightVec);
            shadowMult *= 1.0 + edgeEffectFactor * (1.0 + edgeFactor);
        }

        shadowMult *= 1.0 + 0.2333 * edgeEffectFactor * (dot(normal, lightVec) - 1.0);
    #endif

    #ifdef SNOWY_WORLD
        if (glColor.g - glColor.b > 0.01)
            snowMinNdotU = min(pow2(pow2(max0(color.g * 2.0 - color.r - color.b))) * 5.0, 0.1);
        else
            snowMinNdotU = min(pow2(pow2(max0(color.g * 2.0 - color.r - color.b))) * 3.0, 0.1) * 0.25;

        #ifdef DISTANT_HORIZONS
            // DH chunks don't have foliage. The border looks too noticeable without this tweak
            snowMinNdotU = mix(snowMinNdotU, 0.09, smoothstep(far * 0.5, far, lViewPos));
        #endif
    #endif
}

void DoBrightBlockTweaks(vec3 color, float minLight, inout vec3 shadowMult, inout float highlightMult) {
    float factor = mix(minLight, 1.0, pow2(pow2(color.r)));
    shadowMult = vec3(factor);
    highlightMult /= factor;
}

void DoOceanBlockTweaks(inout float smoothnessD) {
    smoothnessD *= max0(lmCoord.y - 0.95) * 20.0;
}

//Includes//
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/mainLighting.glsl"
#include "/lib/util/dither.glsl"

#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif

#if defined GENERATED_NORMALS || defined COATED_TEXTURES || ANISOTROPIC_FILTER > 0 || defined DISTANT_LIGHT_BOKEH
    #include "/lib/util/miplevel.glsl"
#endif

#ifdef GENERATED_NORMALS
    #include "/lib/materials/materialMethods/generatedNormals.glsl"
#endif

#ifdef COATED_TEXTURES
    #include "/lib/materials/materialMethods/coatedTextures.glsl"
#endif

#if IPBR_EMISSIVE_MODE != 1
    #include "/lib/materials/materialMethods/customEmission.glsl"
#endif

#ifdef CUSTOM_PBR
    #include "/lib/materials/materialHandling/customMaterials.glsl"
#endif

#ifdef COLOR_CODED_PROGRAMS
    #include "/lib/misc/colorCodedPrograms.glsl"
#endif

#if ANISOTROPIC_FILTER > 0
    #include "/lib/materials/materialMethods/anisotropicFiltering.glsl"
#endif

#ifdef PUDDLE_VOXELIZATION
    #include "/lib/misc/puddleVoxelization.glsl"
#endif

#ifdef SNOWY_WORLD
    #include "/lib/materials/materialMethods/snowyWorld.glsl"
#endif

#ifdef DISTANT_LIGHT_BOKEH
    #include "/lib/misc/distantLightBokeh.glsl"
#endif

#ifdef SS_BLOCKLIGHT
    #include "/lib/lighting/coloredBlocklight.glsl"
#endif

#if defined ATM_COLOR_MULTS || defined SPOOKY
    #include "/lib/colors/colorMultipliers.glsl"
#endif

#ifdef AURORA_INFLUENCE
    #include "/lib/atmospherics/auroraBorealis.glsl"
#endif

#if SEASONS > 0 || defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
    #include "/lib/materials/overlayNoise.glsl"
#endif

#if PIXEL_WATER > 0
    #include "/lib/materials/materialMethods/waterProcedureTexture.glsl"
#endif

#if SHOCKWAVE > 0
    #include "/lib/misc/shockwave.glsl"
#endif

//Program//
void main() {
    skyLightCheck = pow2(1.0 - min1(lmCoord.y * 2.9 * sunVisibility));

    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    #ifdef TAA
        vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
    #else
        vec3 viewPos = ScreenToView(screenPos);
    #endif
    float lViewPos = length(viewPos);
    vec3 nViewPos = normalize(viewPos);
    vec3 playerPos = ViewToPlayer(viewPos);
    vec3 worldPos = playerPos + cameraPosition;

    #if SHOCKWAVE > 0
        vec4 color = doShockwave(playerPos + relativeEyePosition, texCoord);
    #else
        #if ANISOTROPIC_FILTER == 0
            vec4 color = texture2D(tex, texCoord);
        #else
            vec4 color = textureAF(tex, texCoord);
        #endif
    #endif

    float smoothnessD = 0.0, materialMask = 0.0, skyLightFactor = 0.0;

    #if !defined POM || !defined POM_ALLOW_CUTOUT
        if (color.a <= 0.00001) discard;
    #endif

    vec3 colorP = color.rgb;
    color.rgb *= glColor.rgb;

    float dither = Bayer64(gl_FragCoord.xy);
    #ifdef TAA
        dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
    #endif

    float luminance = GetLuminance(color.rgb);

    int subsurfaceMode = 0;
    bool noSmoothLighting = false, noDirectionalShading = false, noVanillaAO = false, centerShadowBias = false, noGeneratedNormals = false, doTileRandomisation = true, isFoliage = false;
    float smoothnessG = 0.0, highlightMult = 1.0, emission = 0.0, noiseFactor = 1.0, snowFactor = 1.0, snowMinNdotU = 0.0, noPuddles = 0.0, overlayNoiseIntensity = 1.0, snowNoiseIntensity = 1.0, sandNoiseIntensity = 1.0, mossNoiseIntensity = 1.0, overlayNoiseTransparentOverwrite = 0.0, overlayNoiseEmission = 1.0, IPBRMult = 1.0, lavaNoiseIntensity = LAVA_NOISE_INTENSITY;
    vec2 lmCoordM = lmCoord;
    vec3 normalM = normal, geoNormal = normal, shadowMult = vec3(1.0);
    vec3 worldGeoNormal = normalize(ViewToPlayer(geoNormal * 10000.0));
    vec3 dhColor = vec3(1.0);
    float purkinjeOverwrite = 0.0;


    if (lmCoord.x > 0.99 || blockLightEmission > 0) { // Mod support for light level 15 (and all light levels with iris 1.7) light sources
        if (mat == 0) {
            emission = DoAutomaticEmission(noSmoothLighting, noDirectionalShading, color.rgb, lmCoord.x, blockLightEmission);
        }
        overlayNoiseIntensity = 0.0;
    }

    if (length(abs(worldGeoNormal.xz) - vec2(sqrt(0.5))) < 0.01) { // Auto SSS on unknown cross model blocks (modded)
        if (mat == 0) {
            subsurfaceMode = 1;
            noSmoothLighting = true, noDirectionalShading = true;
        }
        isFoliage = true;
        sandNoiseIntensity = 0.3, mossNoiseIntensity = 0.0;
    }

    #if defined SPOOKY && defined EYES
        vec3 eyes1 = vec3(0.0);
        vec3 eyes2 = vec3(0.0);
        float sideRandom = hash13(mod(floor(worldPos + atMidBlock / 64) + frameTimeCounter * 0.00001, vec3(100)));
        vec3 blockUVEyes = blockUV;
        if (step(0.5, sideRandom) > 0.0) { // Randomly make eyes visible only on either the x or z axis
            blockUVEyes.x = 0.0;
        } else {
            blockUVEyes.z = 0.0;
        }
        float spookyEyesFrequency = EYE_FREQUENCY;
        float spookyEyesSpeed = EYE_SPEED;

        float randomEyesTime = 24000 * hash1(worldDay * 3); // Effect happens randomly throughout the day
        int moreEyesEffect = (int(hash1(worldDay / 2)) % (2 * 24000)) + int(randomEyesTime);
        if (worldTime > moreEyesEffect && worldTime < moreEyesEffect + 30) { // 30 in ticks - 1.5s, how long the effect will be on
            spookyEyesFrequency = 20.0; // make eyes appear everywhere
        }
        if ((blockUVEyes.x > 0.15 && blockUVEyes.x < 0.43 || blockUVEyes.x < 0.85 && blockUVEyes.x > 0.57 || blockUVEyes.z > 0.15 && blockUVEyes.z < 0.43 || blockUVEyes.z < 0.85 && blockUVEyes.z > 0.57) && blockUVEyes.y > 0.42 && blockUVEyes.y < 0.58 && abs(clamp01(dot(normal, upVec))) < 0.99) eyes1 = vec3(1.0); // Eye Shape 1 Horizontal
        if ((blockUVEyes.x > 0.65 && blockUVEyes.x < 0.8 || blockUVEyes.x < 0.35 && blockUVEyes.x > 0.2 || blockUVEyes.z > 0.65 && blockUVEyes.z < 0.8 || blockUVEyes.z < 0.35 && blockUVEyes.z > 0.2) && blockUVEyes.y > 0.3 && blockUVEyes.y < 0.7 && abs(clamp01(dot(normal, upVec))) < 0.99) eyes2 = vec3(1.0); // Eye Shape 2 Vertical
        vec3 spookyEyes = mix(eyes1, eyes2, step(0.75, hash13(mod(floor(worldPos + atMidBlock / 64) + frameTimeCounter * 0.00005, vec3(100))))); // have either eye shape 1 or 2 randomly, the horizontal ones have a 0.75 to 0.25 higher probability of appearing
        spookyEyes *= vec3(step(1.0075 - spookyEyesFrequency * 0.01, hash13(mod(floor(worldPos + atMidBlock / 64) + frameTimeCounter * 0.0000005 * spookyEyesSpeed, vec3(100))))); // Make them appear randomly and much less
    #endif

    #ifdef IPBR
        vec3 maRecolor = vec3(0.0);
        #include "/lib/materials/materialHandling/terrainMaterials.glsl"
        #ifdef REFLECTIVE_WORLD
            smoothnessD = 1.0;
            smoothnessG = 1.0;
        #endif

        //int blockEntityId = mat;
        //#include "/lib/materials/materialHandling/blockEntityMaterials.glsl"

        #ifdef GENERATED_NORMALS
            if (!noGeneratedNormals) GenerateNormals(normalM, colorP);
        #endif

        #ifdef COATED_TEXTURES
            CoatTextures(color.rgb, noiseFactor, playerPos, doTileRandomisation);
        #endif

        #if IPBR_EMISSIVE_MODE != 1
            emission = GetCustomEmissionForIPBR(color, emission);
        #endif
    #else
        #ifdef CUSTOM_PBR
            GetCustomMaterials(color, normalM, lmCoordM, NdotU, shadowMult, smoothnessG, smoothnessD, highlightMult, emission, materialMask, viewPos, lViewPos);
        #endif

        if (mat == 10001) { // No directional shading
            noDirectionalShading = true;
        } else if (mat == 10003 || mat == 10005 || mat == 10029) { // Grounded Waving Foliage
            subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true, isFoliage = true;
            DoFoliageColorTweaks(color.rgb, shadowMult, snowMinNdotU, viewPos, nViewPos, lViewPos, dither);
            sandNoiseIntensity = 0.3, mossNoiseIntensity = 0.0;
        } else if (mat == 10007 || mat == 10009 || mat == 10011) { // Leaves
            #include "/lib/materials/specificMaterials/terrain/leaves.glsl"
        } else if (mat == 10013 || mat == 10923) { // Vine
            subsurfaceMode = 3, centerShadowBias = true; noSmoothLighting = true, isFoliage = true;
            sandNoiseIntensity = 0.3, mossNoiseIntensity = 0.0;
        } else if (mat == 10015 || mat == 10017 || mat == 10019) { // Non-waving Foliage
            subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true, isFoliage = true;
            sandNoiseIntensity = 0.3, mossNoiseIntensity = 0.0;
        } else if (mat == 10021 || mat == 10023) { // Upper Waving Foliage
            subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true, isFoliage = true;
            sandNoiseIntensity = 0.3, mossNoiseIntensity = 0.0;
            DoFoliageColorTweaks(color.rgb, shadowMult, snowMinNdotU, viewPos, nViewPos, lViewPos, dither);
        } else if (mat == 10068 || mat == 10070){ // Lava
            vec3 previousLavaColor = color.rgb;
            if (emission < 1.0) emission = max(2.0, emission);
            #ifdef SOUL_SAND_VALLEY_OVERHAUL_INTERNAL
                color.rgb = changeColorFunction(color.rgb, 3.0, colorSoul, inSoulValley);
            #endif
            #ifdef PURPLE_END_FIRE_INTERNAL
                color.rgb = changeColorFunction(color.rgb, 3.0, colorEndBreath, 1.0);
            #endif
            vec3 lavaNoiseColor = color.rgb;
            #if LAVA_VARIATION > 0
                vec2 lavaPos = (floor(worldPos.xz * 16.0) + worldPos.y * 32.0) * 0.000666;
                vec2 wind = vec2(frameTimeCounter * 0.012, 0.0);
                lavaNoiseIntensity *= 0.95;
                #include "/lib/materials/specificMaterials/terrain/lavaNoise.glsl"
                color.rgb = lavaNoiseColor;
            #else
                if (LAVA_TEMPERATURE != 0.0) color.rgb += LAVA_TEMPERATURE * 0.3;
            #endif
            vec3 maxLavaColor = max(previousLavaColor, lavaNoiseColor);
            #if RAIN_PUDDLES >= 1 || defined SPOOKY_RAIN_PUDDLE_OVERRIDE
                noPuddles = 1.0;
            #endif
            
            #include "/lib/materials/specificMaterials/terrain/lavaEdge.glsl"

            emission *= LAVA_EMISSION;
        } else if (mat > 20999 && mat < 21025){
            emission = DoAutomaticEmission(noSmoothLighting, noDirectionalShading, color.rgb, lmCoord.x, blockLightEmission);
        }

        #ifdef SNOWY_WORLD
            else if (mat == 10132) { // Grass Block:Normal
                if (glColor.b < 0.999) { // Grass Block:Normal:Grass Part
                    snowMinNdotU = min(pow2(pow2(color.g)) * 1.9, 0.1);
                    color.rgb = color.rgb * 0.5 + 0.5 * (color.rgb / glColor.rgb);
                }
            }
        #endif

        else if (lmCoord.x > 0.99999) lmCoordM.x = 0.95;
    #endif

    if (mat == 10572) { // Dragon Egg
        overlayNoiseIntensity = 0.0;
        #ifndef EMISSIVE_DRAGON_EGG
            emission *= 0.0;
        #endif
    }

    #ifdef SNOWY_WORLD
        DoSnowyWorld(color, smoothnessG, highlightMult, smoothnessD, emission,
                     playerPos, lmCoord, snowFactor, snowMinNdotU, NdotU, subsurfaceMode);
    #endif

    #if defined NETHER && defined BIOME_COLORED_NETHER_PORTALS && !defined IPBR
        if (mat == 10476 || mat == 10588 || mat == 10592) { // Crying Obsidian, Respawn Anchor lit and unlit
            emission = sqrt(luminance * luminance) * 10.0;
            color.a *= luminance;
        }
    #endif

    #if SEASONS > 0
        #include "/lib/materials/seasons.glsl"
    #endif
    #if defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
        #include "/lib/materials/overlayNoiseApply.glsl"
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

    #if RAIN_PUDDLES >= 1 || defined SPOOKY_RAIN_PUDDLE_OVERRIDE
        float puddleLightFactor = max0(lmCoord.y * 32.0 - 31.0) * clamp((1.0 - 1.15 * lmCoord.x) * 10.0, 0.0, 1.0);
        float puddleNormalFactor = pow2(max0(NdotUmax0 - 0.5) * 2.0);
        #ifdef NO_RAIN_ABOVE_CLOUDS
            puddleNormalFactor *= mix(0.0, 1.0, heightRelativeToCloud);
        #endif
        float puddleMixer = puddleLightFactor * inRainy * puddleNormalFactor;
        #if RAIN_PUDDLES < 3
            float wetnessM = wetness;
        #else
            float wetnessM = 1.0;
        #endif
        #ifdef PUDDLE_VOXELIZATION
            vec3 voxelPos = SceneToPuddleVoxel(playerPos);
            vec3 voxel_sample_pos = clamp01(voxelPos / vec3(puddle_voxelVolumeSize));
            if (CheckInsidePuddleVoxelVolume(voxelPos)) {
                noPuddles += texture2D(puddle_sampler, voxel_sample_pos.xz).r;
            }
        #endif
        if (pow2(pow2(wetnessM)) * puddleMixer - noPuddles > 0.00001) {
            vec2 worldPosXZ = playerPos.xz + cameraPosition.xz;
            vec2 puddleWind = vec2(frameTimeCounter) * 0.03;
            #if WATER_STYLE == 1
                vec2 puddlePosNormal = floor(worldPosXZ * 16.0) * 0.0625;
            #else
                vec2 puddlePosNormal = worldPosXZ;
            #endif

            puddlePosNormal *= 0.1;
            vec2 pNormalCoord1 = puddlePosNormal + vec2(puddleWind.x, puddleWind.y);
            vec2 pNormalCoord2 = puddlePosNormal + vec2(puddleWind.x * -1.5, puddleWind.y * -1.0);
            vec3 pNormalNoise1 = texture2D(noisetex, pNormalCoord1).rgb;
            vec3 pNormalNoise2 = texture2D(noisetex, pNormalCoord2).rgb;
            float pNormalMult = 0.03;

            vec3 puddleNormal = vec3((pNormalNoise1.xy + pNormalNoise2.xy - vec2(1.0)) * pNormalMult, 1.0);
            puddleNormal = clamp(normalize(puddleNormal * tbnMatrix), vec3(-1.0), vec3(1.0));

            #if RAIN_PUDDLES == 1 || RAIN_PUDDLES == 3 || defined SPOOKY_RAIN_PUDDLE_OVERRIDE
                vec2 puddlePosForm = puddlePosNormal * 0.05;
                float pFormNoise  = texture2D(noisetex, puddlePosForm).b        * 3.0;
                      pFormNoise += texture2D(noisetex, puddlePosForm * 0.5).b  * 5.0;
                      pFormNoise += texture2D(noisetex, puddlePosForm * 0.25).b * 8.0;
                      pFormNoise *= sqrt1(wetnessM) * 0.5625 + 0.4375;
                      pFormNoise  = clamp(pFormNoise - 7.0, 0.0, 1.0);
            #else
                float pFormNoise = wetnessM;
            #endif
            puddleMixer *= pFormNoise;

            float puddleSmoothnessG = 0.7 - rainFactor * 0.3;
            float puddleHighlight = (1.5 - subsurfaceMode * 0.6 * invNoonFactor);
            smoothnessG = mix(smoothnessG, puddleSmoothnessG, puddleMixer);
            highlightMult = mix(highlightMult, puddleHighlight, puddleMixer);
            smoothnessD = mix(smoothnessD, 1.0, sqrt1(puddleMixer));
            normalM = mix(normalM, puddleNormal, puddleMixer * rainFactor);
        }
    #endif

    #if SHOW_LIGHT_LEVEL > 0
        #include "/lib/misc/showLightLevels.glsl"
    #endif

    #ifdef SS_BLOCKLIGHT
        blocklightCol = ApplyMultiColoredBlocklight(blocklightCol, screenPos);
    #endif

    #if defined SPOOKY && BLOOD_MOON > 0
        auroraSpookyMix = getBloodMoon(moonPhase, sunVisibility);
        ambientColor *= 1.0 + auroraSpookyMix * vec3(2.0, -1.0, -1.0);
    #endif
    #ifdef AURORA_INFLUENCE
        ambientColor = mix(AuroraAmbientColor(ambientColor, viewPos), ambientColor, auroraSpookyMix);
    #endif

    #ifdef SPOOKY
        if (mat != 10068 && mat != 10070) { // Lava
            float noiseAdd = hash13(mod(floor(worldPos + atMidBlock / 64) + frameTimeCounter * 0.000001, vec3(100)));
            emission *= mix(clamp(noiseAdd * 1.5, 0.1, 2.0), 1.0, smoothstep(0.1, 0.11, texture2D(noisetex, vec2(frameTimeCounter * 0.008 + noiseAdd)).r));
        }
    #endif

    emission *= EMISSION_MULTIPLIER;

    DoLighting(color, shadowMult, playerPos, viewPos, lViewPos, geoNormal, normalM,
               worldGeoNormal, lmCoordM, noSmoothLighting, noDirectionalShading, noVanillaAO,
               centerShadowBias, subsurfaceMode, smoothnessG, highlightMult, emission, purkinjeOverwrite);

    #ifdef SS_BLOCKLIGHT
        vec3 lightAlbedo = normalize(color.rgb) * min1(emission);

        #ifdef COLORED_CANDLE_LIGHT
            if (mat == 10584) { // Candles:Lit
                lightAlbedo = normalize(color.rgb) * lmCoord.x;
            }
        #endif
    #endif

    #ifdef IPBR
        color.rgb += maRecolor;
    #endif

    #if defined SPOOKY && defined EYES
        vec2 flickerEyeNoise = texture2D(noisetex, vec2(frameTimeCounter * 0.025 + hash13(mod(floor(worldPos + atMidBlock / 64) + frameTimeCounter * 0.000001, vec3(100))))).rb;
        if (length(playerPos) > 8.0) {
            vec3 eyesColor = mix(vec3(1.0), vec3(3.0, 0.0, 0.0), vec3(step(1.0 - EYE_RED_PROBABILITY * mix(1.0, 2.0, getBloodMoon(moonPhase, sunVisibility)), hash13(mod(floor(worldPos + atMidBlock / 64) + frameTimeCounter * 0.0000002, vec3(500)))))); // Make Red eyes appear rarely, 7% chance
            color.rgb += spookyEyes * 3.0 * skyLightCheck * min1(max(flickerEyeNoise.r, flickerEyeNoise.g)) * clamp((1.0 - 1.15 * lmCoord.x) * 10.0, 0.0, 1.0) * eyesColor;
        }
    #endif

    #ifdef PBR_REFLECTIONS
        #ifdef OVERWORLD
            skyLightFactor = clamp01(pow2(max(lmCoord.y - 0.7, 0.0) * 3.33333) + 0.0 + 0.0);
        #else
            skyLightFactor = dot(shadowMult, shadowMult) / 3.0;
        #endif
    #endif

    #ifdef COLOR_CODED_PROGRAMS
        ColorCodeProgram(color, mat);
    #endif

    #ifdef SPOOKY
        int seed = worldDay / 2; // Thanks to Bálint
        int currTime = (worldDay % 2) * 24000 + worldTime; // Effect happens every 2 minecraft days
        float randomTime = 24000 * hash1(worldDay * 5); // Effect happens randomly throughout the day
        int timeWhenItHappens = (int(hash1(seed)) % (2 * 24000)) + int(randomTime);
        if (currTime > timeWhenItHappens && currTime < timeWhenItHappens + 100) { // 100 in ticks - 5s, how long the effect will be on, aka leaves are gone
            if (mat == 10007 || mat == 10009 || mat == 10011) discard; // Disable leaves
        }
    #endif

    /* DRAWBUFFERS:06 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(smoothnessD, materialMask, skyLightFactor, lmCoord.x + purkinjeOverwrite + clamp01(emission));

    #if BLOCK_REFLECT_QUALITY >= 2 && RP_MODE != 0
        /* DRAWBUFFERS:065 */
        gl_FragData[2] = vec4(mat3(gbufferModelViewInverse) * normalM, 1.0);

        #ifdef SS_BLOCKLIGHT
            /* DRAWBUFFERS:0658 */
            gl_FragData[3] = vec4(lightAlbedo, 1.0);
        #endif
    #elif defined SS_BLOCKLIGHT
        /* DRAWBUFFERS:068 */
        gl_FragData[2] = vec4(lightAlbedo, 1.0);
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

flat out int mat;
flat out int blockLightEmission;

out vec2 texCoord;
out vec2 lmCoord;
out vec2 signMidCoordPos;
flat out vec2 absMidCoordPos;
flat out vec2 midCoord;
out vec3 blockUV; // useful to hardcode something to a specific pixel coordinate of a block
out vec3 atMidBlock;
// #if SEASONS == 1 || SEASONS == 4 || defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
//     flat out ivec2 pixelTexSize;
// #endif

flat out vec3 upVec, sunVec, northVec, eastVec;
out vec3 normal;

out vec4 glColorRaw;

#if RAIN_PUDDLES >= 1 || defined GENERATED_NORMALS || defined CUSTOM_PBR || defined SPOOKY_RAIN_PUDDLE_OVERRIDE
    flat out vec3 binormal, tangent;
#endif

#ifdef POM
    out vec3 viewVector;

    out vec4 vTexCoordAM;
#endif

#if ANISOTROPIC_FILTER > 0
    out vec4 spriteBounds;
#endif

out vec4 beforeTransformPos;

//Attributes//
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;
attribute vec4 at_midBlock;

#if RAIN_PUDDLES >= 1 || defined GENERATED_NORMALS || defined CUSTOM_PBR || defined SPOOKY_RAIN_PUDDLE_OVERRIDE
    attribute vec4 at_tangent;
#endif

//Common Variables//
vec4 glColor = vec4(1.0);

//Common Functions//

//Includes//
#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif

#if defined WAVING_ANYTHING_TERRAIN || defined INTERACTIVE_FOLIAGE || defined WAVE_EVERYTHING
    #include "/lib/materials/materialMethods/wavingBlocks.glsl"
#endif

#if defined MIRROR_DIMENSION || defined WORLD_CURVATURE
    #include "/lib/misc/distortWorld.glsl"
#endif

//Program//
void main() {
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    #ifdef ATLAS_ROTATION
        texCoord += texCoord * float(hash33(mod(cameraPosition * 0.1, vec3(100.0))));
    #endif
    lmCoord  = GetLightMapCoordinates();
    blockUV = 0.5 - at_midBlock.xyz / 64.0;
    atMidBlock = at_midBlock.xyz;

    glColorRaw = gl_Color;
    if (glColorRaw.a < 0.1) glColorRaw.a = 1.0;
    glColor = glColorRaw;

    normal = normalize(gl_NormalMatrix * gl_Normal);
    upVec = normalize(gbufferModelView[1].xyz);
    eastVec = normalize(gbufferModelView[0].xyz);
    northVec = normalize(gbufferModelView[2].xyz);
    sunVec = GetSunVector();

    midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
    vec2 texMinMidCoord = texCoord - midCoord;
    signMidCoordPos = sign(texMinMidCoord);
    absMidCoordPos  = abs(texMinMidCoord);

    // #if SEASONS == 1 || SEASONS == 4 || defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
    //     pixelTexSize = ivec2(absMidCoordPos * 2.0 * atlasSize);
    // #endif

    mat = int(mc_Entity.x + 0.5);

    #if ANISOTROPIC_FILTER > 0
        if (mc_Entity.y > 0.5 && dot(normal, upVec) < 0.999) absMidCoordPos = vec2(0.0); // Fix257062
    #endif

    blockLightEmission = 0;
    #ifdef IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE
        blockLightEmission = clamp(int(at_midBlock.w + 0.5), 0, 15);
    #endif

    #if defined MIRROR_DIMENSION || defined WORLD_CURVATURE || defined WAVING_ANYTHING_TERRAIN || defined WAVE_EVERYTHING || defined INTERACTIVE_FOLIAGE
        vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
        beforeTransformPos = position;
        #ifdef MIRROR_DIMENSION
            doMirrorDimension(position);
        #endif
        #ifdef WORLD_CURVATURE
            position.y += doWorldCurvature(position.xz);
        #endif
        #ifdef WAVING_ANYTHING_TERRAIN
            DoWave(position.xyz, mat);
        #endif
        #ifdef INTERACTIVE_FOLIAGE
            if (mat == 10003 || mat == 10005 || mat == 10015 || mat == 10021 || mat == 10029 || mat == 10023 || mat == 10629 || mat == 10632 || mat == 10777 || mat == 10025 || mat == 10027 || mat == 10923) {
                vec3 playerPosM = position.xyz + relativeEyePosition;
                DoInteractiveWave(playerPosM, mat);
                position.xyz = playerPosM - relativeEyePosition;
            }
        #endif
        // #ifdef SPOOKY
        //  if (mat == 10744) { // Cobweb Thanks to gri
        //      vec3 irisThirdPersonPull = vec3(0.0);
        //      #ifdef IS_IRIS
        //          irisThirdPersonPull = eyePosition - cameraPosition;
        //      #endif
        //      vec3 pullCenter = vec3(0.1, -0.1, -0.05) - irisThirdPersonPull;
        //      float pullFactor = pow(min(abs(sin(1.81 * frameTimeCounter) + cos(0.9124 * frameTimeCounter)), 1.0), 10.0) * 4.0 / (length(position.xyz) + max(20 * texture2D(noisetex, vec2(frameTimeCounter * 0.1)).r, 10.0));
        //      vec3 pullDir = pullCenter - position.xyz - at_midBlock.xyz / 64.0;
        //      position.xyz += pullDir * pullFactor;
        //  }
        // #endif
        #ifdef WAVE_EVERYTHING
            DoWaveEverything(position.xyz);
        #endif
        gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
    #else
        gl_Position = ftransform();

        beforeTransformPos = vec4(0.0);

        #ifndef WAVING_LAVA
            if (mat == 10068 || mat == 10070) { // Lava
                // G8FL735 Fixes Optifine-Iris parity. Optifine has 0.9 gl_Color.rgb on a lot of versions
                glColorRaw.rgb = min(glColorRaw.rgb, vec3(0.9));
            }
        #endif
    #endif

    #ifdef FLICKERING_FIX
        if (mat == 10257) gl_Position.z -= 0.00001; // Iron Bars
    #endif

    #ifdef TAA
        gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    #endif

    #if RAIN_PUDDLES >= 1 || defined GENERATED_NORMALS || defined CUSTOM_PBR || defined SPOOKY_RAIN_PUDDLE_OVERRIDE
        binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
        tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
    #endif

    #ifdef POM
        mat3 tbnMatrix = mat3(
            tangent.x, binormal.x, normal.x,
            tangent.y, binormal.y, normal.y,
            tangent.z, binormal.z, normal.z
        );

        viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;

        vTexCoordAM.zw  = abs(texMinMidCoord) * 2;
        vTexCoordAM.xy  = min(texCoord, midCoord - texMinMidCoord);
    #endif

    #if ANISOTROPIC_FILTER > 0
        vec2 spriteRadius = abs(texCoord - mc_midTexCoord.xy);
        vec2 bottomLeft = mc_midTexCoord.xy - spriteRadius;
        vec2 topRight = mc_midTexCoord.xy + spriteRadius;
        spriteBounds = vec4(bottomLeft, topRight);
    #endif
}

#endif
