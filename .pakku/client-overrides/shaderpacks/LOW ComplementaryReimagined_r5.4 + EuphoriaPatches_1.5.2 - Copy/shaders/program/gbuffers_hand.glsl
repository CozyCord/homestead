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
float NdotU = dot(normal, vec3(0.0, 1.0, 0.0)); // NdotU is different here to improve held map visibility
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

//Program//
void main() {
    skyLightCheck = pow2(1.0 - min1(lmCoord.y * 2.9 * sunVisibility));
    vec4 color = texture2D(tex, texCoord);
    float purkinjeOverwrite = 0.0, emission = 0.0;

    float smoothnessD = 0.0, skyLightFactor = 0.0, materialMask = OSIEBCA * 254.0; // No SSAO, No TAA
    vec3 normalM = normal;

    #ifdef SS_BLOCKLIGHT
        vec3 lightAlbedo = vec3(0.0);
    #endif

    if (color.a > 0.00001) {
        #if defined GENERATED_NORMALS || PIXEL_WATER == 1
            vec3 colorP = color.rgb;
        #endif
        color *= glColor;

        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z + 0.38);
        vec3 viewPos = ScreenToView(screenPos);
        vec3 playerPos = ViewToPlayer(viewPos);

        float luminance = GetLuminance(color.rgb);

        if (color.a < 0.75) materialMask = 0.0;

        bool noSmoothLighting = true, noGeneratedNormals = false;
        float smoothnessG = 0.0, highlightMult = 1.0, noiseFactor = 0.6;
        vec2 lmCoordM = lmCoord;
        vec3 geoNormal = normalM;
        vec3 worldGeoNormal = normalize(ViewToPlayer(geoNormal * 10000.0));
        vec3 shadowMult = vec3(0.4);

        float overlayNoiseIntensity = 1.0;
        float snowNoiseIntensity = 1.0;
        float sandNoiseIntensity = 1.0;
        float mossNoiseIntensity = 1.0;
        float overlayNoiseEmission = 1.0;
        bool isFoliage = false;

        #ifdef IPBR
            #ifdef IS_IRIS
                vec3 maRecolor = vec3(0.0);
                #include "/lib/materials/materialHandling/irisMaterials.glsl"

                if (materialMask != OSIEBCA * 254.0) materialMask += OSIEBCA * 100.0; // Entity Reflection Handling
            #endif

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
                GetCustomMaterials(color, normalM, lmCoordM, NdotU, shadowMult, smoothnessG, smoothnessD, highlightMult, emission, materialMask, viewPos, 0.0);
            #endif
        #endif

        // Support for modded light sources and blockID set by the user
        #if defined IS_IRIS && !defined MC_OS_MAC
            if (currentRenderedItemId == 0) {
                float screenWidth = viewPos.x;
                float region1End = -0.1;  // End of the first 2/5 region
                float region2Start = 0.1; // Start of the last 2/5 region
                int heldBlockLight = 0;
                if (screenWidth <= region1End || screenWidth >= region2Start) {
                    heldBlockLight = (viewPos.x > 0.0 ^^ isRightHanded) ? heldBlockLightValue2 : heldBlockLightValue;
                }

                if (heldBlockLight > 0) {
                    bool doesNothing;
                    emission = DoAutomaticEmission(noSmoothLighting, doesNothing, color.rgb, 0.0, heldBlockLight);
                }
            }
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

        DoLighting(color, shadowMult, playerPos, viewPos, 0.0, geoNormal, normalM,
                   worldGeoNormal, lmCoordM, noSmoothLighting, false, false,
                   false, 0, smoothnessG, highlightMult, emission, purkinjeOverwrite);

        #ifdef SS_BLOCKLIGHT
            lightAlbedo = normalize(color.rgb) * min1(emission);
        #endif

        #if defined IPBR && defined IS_IRIS
            color.rgb += maRecolor;
        #endif

        #if (defined CUSTOM_PBR || defined IPBR && defined IS_IRIS) && defined PBR_REFLECTIONS
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

    #if BLOCK_REFLECT_QUALITY >= 2 && (RP_MODE >= 2 || defined IS_IRIS)
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
#if defined GENERATED_NORMALS || defined COATED_TEXTURES || defined POM || defined IPBR && defined IS_IRIS
    attribute vec4 mc_midTexCoord;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
    attribute vec4 at_tangent;
#endif

attribute vec4 at_midBlock;

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    #ifdef ATLAS_ROTATION
        texCoord += texCoord * float(hash33(mod(cameraPosition * 0.5, vec3(100.0))));
    #endif

    lmCoord  = GetLightMapCoordinates();

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

    #if HAND_SWAYING > 0
        #include "/lib/misc/handSway.glsl"
    #endif
}

#endif
