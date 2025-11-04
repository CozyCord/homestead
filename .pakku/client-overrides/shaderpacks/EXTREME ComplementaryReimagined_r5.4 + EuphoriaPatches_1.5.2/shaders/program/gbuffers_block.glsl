//////////////////////////////////
// Complementary Base by EminGT //
//////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;
in vec2 lmCoord;

flat in int mat;

flat in vec3 upVec, sunVec, northVec, eastVec;
in vec3 normal;
in vec3 atMidBlock;

in vec4 glColor;

#if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || SHOCKWAVE > 0
    in vec2 signMidCoordPos;
    flat in vec2 absMidCoordPos;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    flat in vec3 binormal, tangent;
#endif

#ifdef POM
    in vec3 viewVector;

    in vec4 vTexCoordAM;
#endif

// #if SEASONS == 1 || SEASONS == 4 || defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
//     flat in ivec2 pixelTexSize;
// #endif

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

#ifdef OVERWORLD
    vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
    vec3 lightVec = sunVec;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    mat3 tbnMatrix = mat3(
        tangent.x, binormal.x, normal.x,
        tangent.y, binormal.y, normal.y,
        tangent.z, binormal.z, normal.z
    );
#endif

//Common Functions//

//Includes//
#include "/lib/util/spaceConversion.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/lighting/mainLighting.glsl"

#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif

#if defined GENERATED_NORMALS || defined COATED_TEXTURES
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

#ifdef PORTAL_EDGE_EFFECT
    #include "/lib/misc/voxelization.glsl"
#endif

#if SHOCKWAVE > 0
    #include "/lib/misc/shockwave.glsl"
#endif

//Program//
void main() {
    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    #ifdef TAA
        vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
    #else
        vec3 viewPos = ScreenToView(screenPos);
    #endif
    float lViewPos = length(viewPos);
    vec3 playerPos = ViewToPlayer(viewPos);
    vec3 worldPos = playerPos + cameraPosition;

    #if SHOCKWAVE > 0
        vec4 color = doShockwave(playerPos + relativeEyePosition, texCoord);
    #else
        vec4 color = texture2D(tex, texCoord);
    #endif
    #if defined GENERATED_NORMALS || PIXEL_WATER == 1
        vec3 colorP = color.rgb;
    #endif
    color *= glColor;

    float overlayNoiseIntensity = 1.0;
    float snowNoiseIntensity = 1.0;
    float sandNoiseIntensity = 1.0;
    float mossNoiseIntensity = 1.0;
    float overlayNoiseTransparentOverwrite = 0.0;
    float IPBRMult = 1.0;
    int subsurfaceMode = 0;
    bool isFoliage = false;
    vec3 dhColor = vec3(1.0);

    #if defined ATM_COLOR_MULTS || defined SPOOKY
        atmColorMult = GetAtmColorMult();
        sqrtAtmColorMult = sqrt(atmColorMult);
    #endif

    bool noSmoothLighting = false, noDirectionalShading = false;
    float smoothnessD = 0.0, skyLightFactor = 0.0, materialMask = 0.0;
    float smoothnessG = 0.0, highlightMult = 1.0, emission = 0.0, noiseFactor = 1.0;
    vec2 lmCoordM = lmCoord;
    vec3 normalM = normal, geoNormal = normal, shadowMult = vec3(1.0);
    vec3 worldGeoNormal = normalize(ViewToPlayer(geoNormal * 10000.0));
    float purkinjeOverwrite = 0.0;

    if (lmCoord.x > 0.99) { // Mod support for light level 15 (and all light levels with iris 1.7) light sources
        if (blockEntityId == 0) {
            emission = DoAutomaticEmission(noSmoothLighting, noDirectionalShading, color.rgb, 1.0, 15);
        }
        overlayNoiseIntensity = 0.0;
    }

    if (blockEntityId < 21025 && blockEntityId > 20999){
        emission = DoAutomaticEmission(noSmoothLighting, noDirectionalShading, color.rgb, 1.0, 15);
    }

    #ifdef IPBR
        #include "/lib/materials/materialHandling/blockEntityMaterials.glsl"

        #if IPBR_EMISSIVE_MODE != 1
            emission = GetCustomEmissionForIPBR(color, emission);
        #endif
    #else
        #ifdef CUSTOM_PBR
            GetCustomMaterials(color, normalM, lmCoordM, NdotU, shadowMult, smoothnessG, smoothnessD, highlightMult, emission, materialMask, viewPos, lViewPos);
        #endif

        if (blockEntityId == 60025) { // End Portal, End Gateway
            #ifdef SPECIAL_PORTAL_EFFECTS
                #include "/lib/materials/specificMaterials/others/endPortalEffect.glsl"
            #endif
            overlayNoiseIntensity = 0.0;
        } else if (blockEntityId == 60004) { // Signs
            noSmoothLighting = true;
            if (glColor.r + glColor.g + glColor.b <= 2.99 || lmCoord.x > 0.999) { // Sign Text
                #include "/lib/materials/specificMaterials/others/signText.glsl"
            }
        } else if (blockEntityId == 60020) { // Conduit
            overlayNoiseIntensity = 0.3;
        } else if (blockEntityId == 60012) {
            overlayNoiseIntensity = 0.5;
        } else {
            noSmoothLighting = true;
        }
    #endif

    #if defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
        #include "/lib/materials/overlayNoiseApply.glsl"
    #endif
    #if SEASONS > 0
        #include "/lib/materials/seasons.glsl"
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

    #ifdef GENERATED_NORMALS
        GenerateNormals(normalM, colorP);
    #endif

    #ifdef COATED_TEXTURES
        CoatTextures(color.rgb, noiseFactor, playerPos, false);
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

    emission *= EMISSION_MULTIPLIER;

    DoLighting(color, shadowMult, playerPos, viewPos, lViewPos, geoNormal, normalM,
               worldGeoNormal, lmCoordM, noSmoothLighting, noDirectionalShading, false,
               false, 0, smoothnessG, highlightMult, emission, purkinjeOverwrite);

    #ifdef SS_BLOCKLIGHT
        vec3 lightAlbedo = normalize(color.rgb) * min1(emission);

        if (blockEntityId == 60000) lightAlbedo = color.rgb;
        if (blockEntityId == 60004) lightAlbedo = vec3(0.0); // fix glowing sign text affecting blocklight color
    #endif

    #ifdef PBR_REFLECTIONS
        #ifdef OVERWORLD
            skyLightFactor = clamp01(pow2(max(lmCoord.y - 0.7, 0.0) * 3.33333) + 0.0 + 0.0);
        #else
            skyLightFactor = dot(shadowMult, shadowMult) / 3.0;
        #endif
    #endif

    #ifdef COLOR_CODED_PROGRAMS
        ColorCodeProgram(color, blockEntityId);
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
#ifdef END_PORTAL_BEAM_INTERNAL
    #extension GL_ARB_shader_image_load_store : enable
    layout(r32i) uniform iimage2D endcrystal_img;
#endif

out vec2 texCoord;
out vec2 lmCoord;

flat out int mat;

flat out vec3 upVec, sunVec, northVec, eastVec;
out vec3 normal;
out vec3 atMidBlock;

out vec4 glColor;

// #if SEASONS == 1 || SEASONS == 4 || defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
//     flat out ivec2 pixelTexSize;
// #endif

#if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || SHOCKWAVE > 0
    out vec2 signMidCoordPos;
    flat out vec2 absMidCoordPos;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    flat out vec3 binormal, tangent;
#endif

#ifdef POM
    out vec3 viewVector;

    out vec4 vTexCoordAM;
#endif

//Attributes//
#if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || SHOCKWAVE > 0
    attribute vec4 mc_midTexCoord;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    attribute vec4 at_tangent;
#endif

attribute vec4 at_midBlock;
attribute vec4 mc_Entity;

//Common Variables//

//Common Functions//

//Includes//
#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif

#if defined MIRROR_DIMENSION || defined WORLD_CURVATURE
    #include "/lib/misc/distortWorld.glsl"
#endif

#ifdef WAVE_EVERYTHING
    #include "/lib/materials/materialMethods/wavingBlocks.glsl"
#endif

//Program//
void main() {
    gl_Position = ftransform();
    #ifdef TAA
        gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
    #endif

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    #ifdef ATLAS_ROTATION
        texCoord += texCoord * float(hash33(mod(cameraPosition * 0.1, vec3(100.0))));
    #endif

    lmCoord  = GetLightMapCoordinates();

    glColor = gl_Color;

    mat = int(mc_Entity.x + 0.5);

    normal = normalize(gl_NormalMatrix * gl_Normal);

    upVec = normalize(gbufferModelView[1].xyz);
    eastVec = normalize(gbufferModelView[0].xyz);
    northVec = normalize(gbufferModelView[2].xyz);
    sunVec = GetSunVector();
    atMidBlock = at_midBlock.xyz;

    if (normal != normal) normal = -upVec; // Mod Fix: Fixes Better Nether Fireflies

    #ifdef END_PORTAL_BEAM_INTERNAL
        if (blockEntityId == 60025 && length((gl_ModelViewMatrix * gl_Vertex).xyz) < 28) // end portal
        imageStore(endcrystal_img, ivec2(35, 4), ivec4(1));
    #endif

    #ifdef IPBR
        /*if (blockEntityId == 60025) { // End Portal, End Gateway
            gl_Position.z -= 0.002;
        }*/
    #endif

    #if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || SHOCKWAVE > 0
        if (blockEntityId == 60008) { // Chest
            float fractWorldPosY = fract((gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).y + cameraPosition.y);
            if (fractWorldPosY > 0.56 && 0.57 > fractWorldPosY) gl_Position.z -= 0.0001;
        }

        vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
        vec2 texMinMidCoord = texCoord - midCoord;
        signMidCoordPos = sign(texMinMidCoord);
        absMidCoordPos  = abs(texMinMidCoord);
    #endif

    // #if SEASONS == 1 || SEASONS == 4 || defined MOSS_NOISE_INTERNAL || defined SAND_NOISE_INTERNAL
    //     ivec2 pixelTexSize = ivec2(absMidCoordPos * 2.0 * atlasSize);
    // #endif

    #if defined GENERATED_NORMALS || defined CUSTOM_PBR
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
