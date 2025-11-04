/////////////////////////////////////
// Complementary Shaders by EminGT //
// With Euphoria Patches by SpacEagle17 //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;

in vec4 glColor;

//Pipeline Constants//

//Common Variables//

//Common Functions//

//Includes//
#include "/lib/util/spaceConversion.glsl"

#ifdef TAA
    #include "/lib/antialiasing/jitter.glsl"
#endif

#ifdef COLOR_CODED_PROGRAMS
    #include "/lib/misc/colorCodedPrograms.glsl"
#endif

//Program//
void main() {
    vec4 color = texture2D(tex, texCoord);
    vec3 colorP = color.rgb;
    color *= glColor;

    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    #ifdef TAA
        vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
    #else
        vec3 viewPos = ScreenToView(screenPos);
    #endif

    #ifdef DISTANT_HORIZONS
        vec3 screenPosDH = vec3(screenPos.xy, texture2D(dhDepthTex, screenPos.xy).r);
        #ifdef TAA
            vec3 viewPosDH = ScreenToViewDH(vec3(TAAJitter(screenPosDH.xy, -0.5), screenPosDH.z));
        #else
            vec3 viewPosDH = ScreenToViewDH(screenPosDH);
        #endif

        if (viewPos.z < viewPosDH.z)
            discard;
    #endif

    float lViewPos = length(viewPos);

    #ifdef IPBR
        float emission = dot(colorP, colorP);

        if (color.a < 0.5) {
            color.a = 0.101;
            emission = pow2(pow2(emission)) * 0.1;
        }

        emission *= BEACON_BEAM_EMISSION;

        color.rgb *= color.rgb * emission * 1.75;
        color.rgb += emission * 0.05;
    #else
        color.rgb *= color.rgb * 4.0 * BEACON_BEAM_EMISSION;
    #endif

    color.rgb *= 0.5 + 0.5 * exp(-lViewPos * 0.04);

    #ifdef COLOR_CODED_PROGRAMS
        ColorCodeProgram(color, -1);
    #endif

    /* DRAWBUFFERS:06 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;

out vec4 glColor;

//Attributes//

#if defined ATLAS_ROTATION || defined WAVE_EVERYTHING
    attribute vec4 mc_midTexCoord;
    vec2 lmCoord = GetLightMapCoordinates();
#endif

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
        texCoord += texCoord * float(hash33(mod(cameraPosition * 0.5, vec3(100.0))));
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

    glColor = gl_Color;
}

#endif
