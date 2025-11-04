/////////////////////////////////////
// Complementary Shaders by EminGT //
// With Euphoria Patches by SpacEagle17 //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;
in vec2 lmCoord;

flat in vec3 upVec, sunVec, northVec, eastVec;
in vec3 normal;

in vec4 glColor;

#if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || defined IPBR && defined IS_IRIS
    in vec2 signMidCoordPos;
    flat in vec2 absMidCoordPos;
    flat in vec2 midCoord;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    flat in vec3 binormal, tangent;
#endif

#ifdef POM
    in vec3 viewVector;

    in vec4 vTexCoordAM;
#endif

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
float skyLightCheck = 0.0;

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
#include "/lib/util/dither.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/mainLighting.glsl"

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

#if SHOCKWAVE > 0
    #include "/lib/misc/shockwave.glsl"
#endif


//Program//
void main() {
    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    vec3 viewPos = ScreenToView(screenPos);
    vec3 nViewPos = normalize(viewPos);
    vec3 playerPos = ViewToPlayer(viewPos);
    float lViewPos = length(viewPos);
    float purkinjeOverwrite = 0.0, emission = 0.0;

    if (glColor.a < 0.0) discard;
    skyLightCheck = pow2(1.0 - min1(lmCoord.y * 2.9 * sunVisibility));
    #if SHOCKWAVE > 0
        vec4 color = doShockwave(playerPos + relativeEyePosition, texCoord);
    #else
        vec4 color = texture2D(tex, texCoord);
    #endif
    #if defined GENERATED_NORMALS || PIXEL_WATER == 1
        vec3 colorP = color.rgb;
    #endif
    color *= glColor;

    float smoothnessD = 0.0, skyLightFactor = 0.0, materialMask = OSIEBCA * 254.0; // No SSAO, No TAA
    vec3 normalM = normal;

    float luminance = GetLuminance(color.rgb);

    if (color.a > 0.001) {
        float overlayNoiseIntensity = 1.0;
        float snowNoiseIntensity = 1.0;
        float sandNoiseIntensity = 1.0;
        float mossNoiseIntensity = 1.0;
        float overlayNoiseEmission = 1.0;
        float overlayNoiseTransparentOverwrite = 0.0;
        bool isFoliage = false;
        vec3 dhColor = vec3(1.0);

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

    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

        bool noSmoothLighting = atlasSize.x < 600.0; // To fix fire looking too dim
        bool noGeneratedNormals = false;
        float smoothnessG = 0.0, highlightMult = 0.0, noiseFactor = 0.75;
        vec2 lmCoordM = lmCoord;
        vec3 shadowMult = vec3(1.0);
        #ifdef IPBR
            #include "/lib/materials/materialHandling/entityMaterials.glsl"

            #ifdef IS_IRIS
                vec3 maRecolor = vec3(0.0);
                #include "/lib/materials/materialHandling/irisMaterials.glsl"
            #endif

            if (materialMask != OSIEBCA * 254.0) materialMask += OSIEBCA * 100.0; // Entity Reflection Handling

            #ifdef GENERATED_NORMALS
                if (!noGeneratedNormals) GenerateNormals(normalM, colorP);
            #endif

            #ifdef COATED_TEXTURES
                CoatTextures(color.rgb, noiseFactor, playerPos, false);
            #endif

            #if IPBR_EMISSIVE_MODE != 1
                emission = GetCustomEmissionForIPBR(color, emission);
            #endif
        #else
            #ifdef CUSTOM_PBR
                GetCustomMaterials(color, normalM, lmCoordM, NdotU, shadowMult, smoothnessG, smoothnessD, highlightMult, emission, materialMask, viewPos, lViewPos);
            #endif

            if (entityId == 50004) { // Lightning Bolt
                #include "/lib/materials/specificMaterials/entities/lightningBolt.glsl"
            } else if (entityId == 50008) { // Item Frame, Glow Item Frame
                noSmoothLighting = true;
            } else if (entityId == 50076) { // Boats
                playerPos.y += 0.38; // to avoid water shadow and the black inner shadow bug
            }
            #ifdef SOUL_SAND_VALLEY_OVERHAUL_INTERNAL
                if (entityId == 50020) { // blaze
                    color.rgb = changeColorFunction(color.rgb, 2.0, colorSoul, inSoulValley);
                } else if (entityId == 50052) { // Magma Cube
                    color.rgb = changeColorFunction(color.rgb, 2.0, colorSoul, inSoulValley);
                } else if (entityId == 50088) { // Entity Flame
                    color.rgb = changeColorFunction(color.rgb, 2.0, colorSoul, inSoulValley);
                } else if (entityId == 50092 || entityId == 50093) { // fireball, small fireball
                    color.rgb = changeColorFunction(color.rgb, 3.0, colorSoul, inSoulValley);
                }
            #endif
        #endif
    
        color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

        normalM = gl_FrontFacing ? normalM : -normalM; // Inverted Normal Workaround
        vec3 geoNormal = normalM;
        vec3 worldGeoNormal = normalize(ViewToPlayer(geoNormal * 10000.0));

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
                   worldGeoNormal, lmCoordM, noSmoothLighting, false, false,
                   true, 0, smoothnessG, highlightMult, emission, purkinjeOverwrite);

        #if defined IPBR && defined IS_IRIS
            color.rgb += maRecolor;
        #endif

        #ifdef PBR_REFLECTIONS
            #ifdef OVERWORLD
                skyLightFactor = clamp01(pow2(max(lmCoord.y - 0.7, 0.0) * 3.33333) + 0.0 + 0.0);
            #else
                skyLightFactor = dot(shadowMult, shadowMult) / 3.0;
            #endif
        #endif
    }

    #ifdef COLOR_CODED_PROGRAMS
        ColorCodeProgram(color, -1);
    #endif

    /* DRAWBUFFERS:06 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(smoothnessD, materialMask, skyLightFactor, lmCoord.x + purkinjeOverwrite + clamp01(emission));

    #if BLOCK_REFLECT_QUALITY >= 2 && RP_MODE >= 1
        /* DRAWBUFFERS:065 */
        gl_FragData[2] = vec4(mat3(gbufferModelViewInverse) * normalM, 1.0);

        #ifdef SS_BLOCKLIGHT
            /* DRAWBUFFERS:0658 */
            gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
        #endif
    #elif defined SS_BLOCKLIGHT
        /* DRAWBUFFERS:068 */
        gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;
out vec2 lmCoord;

flat out vec3 upVec, sunVec, northVec, eastVec;
out vec3 normal;

out vec4 glColor;

#if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || defined IPBR && defined IS_IRIS
    out vec2 signMidCoordPos;
    flat out vec2 absMidCoordPos;
    flat out vec2 midCoord;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    flat out vec3 binormal, tangent;
#endif

#ifdef POM
    out vec3 viewVector;

    out vec4 vTexCoordAM;
#endif

//Attributes//
#if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || (defined IPBR && defined IS_IRIS) || defined WAVE_EVERYTHING
    attribute vec4 mc_midTexCoord;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    attribute vec4 at_tangent;
#endif

attribute vec4 at_midBlock;

//Common Variables//

//Common Functions//

//Includes//

#if defined MIRROR_DIMENSION || defined WORLD_CURVATURE
    #include "/lib/misc/distortWorld.glsl"
#endif
#ifdef WAVE_EVERYTHING
    #include "/lib/materials/materialMethods/wavingBlocks.glsl"
#endif

//Program//
void main() {
    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    #ifdef ATLAS_ROTATION
        texCoord += texCoord * float(hash33(mod(cameraPosition * 0.5, vec3(100.0))));
    #endif

    lmCoord  = GetLightMapCoordinates();

    lmCoord.x = min(lmCoord.x, 0.9);
    //Fixes some servers/mods making entities insanely bright, while also slightly reducing the max blocklight on a normal entity

    glColor = gl_Color;

    normal = normalize(gl_NormalMatrix * gl_Normal);

    upVec = normalize(gbufferModelView[1].xyz);
    eastVec = normalize(gbufferModelView[0].xyz);
    northVec = normalize(gbufferModelView[2].xyz);
    sunVec = GetSunVector();

    #if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || defined IPBR && defined IS_IRIS
        midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
        vec2 texMinMidCoord = texCoord - midCoord;
        signMidCoordPos = sign(texMinMidCoord);
        absMidCoordPos  = abs(texMinMidCoord);
    #endif

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

    #ifdef GBUFFERS_ENTITIES_GLOWING
        if (glColor.a > 0.99) gl_Position.z *= 0.01;
    #endif

    #ifdef EMIN_BOAT
        if (entityId == 50076) {
            vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
            position.y += 1.25;
            gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
        }
    #endif

    #ifdef FLICKERING_FIX
        if (entityId == 50008 || entityId == 50012) { // Item Frame, Glow Item Frame
            if (dot(normal, upVec) > 0.99) {
                vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
                vec3 comPos = fract(position.xyz + cameraPosition);
                comPos = abs(comPos - vec3(0.5));
                if ((comPos.y > 0.437 && comPos.y < 0.438) || (comPos.y > 0.468 && comPos.y < 0.469)) {
                    gl_Position.z += 0.0001;
                }
            }
            if (gl_Normal.y == 1.0) { // Maps
                normal = upVec * 2.0;
            }
        } else if (entityId == 50084) { // Slime, Chicken
            gl_Position.z -= 0.00015;
        }

        #if SHADOW_QUALITY == -1
            #ifdef VANILLA_ENTITY_SHADOWS
                if (glColor.a < 0.5) gl_Position.z -= 0.0005;
            #else
                if (glColor.a < 0.5) gl_Position.z += 0.0005;
            #endif
        #endif
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
    #if END_CRYSTAL_VORTEX_INTERNAL / 2 == 1
    if (entityId == 50200) {
        gl_Position = vec4(-1);
    }
    #endif
    #if DRAGON_DEATH_EFFECT_INTERNAL > 0 && !defined IRIS_TAG_SUPPORT
        if (entityId == 0 && gl_Color.a < 0.2 && abs(normal.y) < 0.2) {
            glColor.a = -100000.0;
        }
    #endif
}

#endif
