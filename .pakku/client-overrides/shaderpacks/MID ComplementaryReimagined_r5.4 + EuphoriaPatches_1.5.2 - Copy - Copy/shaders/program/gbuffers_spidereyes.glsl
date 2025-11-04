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
#ifdef COLOR_CODED_PROGRAMS
    #include "/lib/misc/colorCodedPrograms.glsl"
#endif

//Program//
void main() {
    vec4 color = texture2D(tex, texCoord) * glColor;

    #ifdef IPBR
        if (CheckForColor(color.rgb, vec3(224, 121, 250))) { // Enderman Eye Edges
            color.rgb = vec3(0.8, 0.25, 0.8);
        }
    #endif
    #ifdef INTENSE_DEEP_DARK
        if (color.b > 0.1 && color.r < 0.5) { // Warden
            color.rgb = mix(color.rgb, color.rgb + 0.3, darknessFactor);
        }
    #endif

    color.rgb *= 1.0 - 0.6 * pow2(pow2(min1(GetLuminance(color.rgb) * 1.2))); // Fixes ultra bright Breeze

    color.rgb = pow1_5(color.rgb);
    color.rgb *= pow2(1.0 + color.b + 0.5 * color.g) * 1.5;

    #ifdef COLOR_CODED_PROGRAMS
        ColorCodeProgram(color, -1);
    #endif

    /* DRAWBUFFERS:06 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(0, 0, 0, 1);
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
