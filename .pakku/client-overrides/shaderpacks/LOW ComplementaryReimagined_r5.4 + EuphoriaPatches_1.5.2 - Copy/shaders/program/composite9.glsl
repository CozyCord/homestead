/////////////////////////////////////
// Complementary Shaders by EminGT //
// With Euphoria Patches by SpacEagle17 //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

//Pipeline Constants//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    #if LONG_EXPOSURE > 0
        vec4 color = vec4(0.0);

        float counter = texture2D(colortex1, ivec2(0)).g;
        counter += 0.00001;
        if(hideGUI == 0 || isViewMoving()) counter = 0.0; // reset counter when GUI visible OR when moving

        if (hideGUI == 1 && !isViewMoving()) { // accumulate ONLY when GUI hidden AND not moving otherwise use colortex7 as normal
            vec4 currentFrame = texture2D(colortex3, texCoord);
            vec4 previousFrame = texture2D(colortex7, texCoord);
            if (counter == 0.00001) previousFrame = currentFrame; // to fix the first frame as it still has info from colortex7 from deferred1
            #if LONG_EXPOSURE == 1
                color = max(currentFrame, previousFrame);
            #else
                float luma = dot(currentFrame.rgb, vec3(3.0)); // do luma weighting to preserve bright pixels for longer
                float mixAmount = 1.0 / (counter * 100000.0 + 1.0);
                color = mix(previousFrame, currentFrame, mixAmount * luma);
            #endif
        } else {
            color = texture2D(colortex7, texCoord);
        }

        /* DRAWBUFFERS:71 */
        gl_FragData[0] = color;
        gl_FragData[1] = vec4(texture2D(colortex1, texCoord).r, ivec2(texCoord * vec2(viewWidth, viewHeight)) == ivec2(0) ? counter : texture2D(colortex1, texCoord).g, texture2D(colortex1, texCoord).ba);
    #endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif
