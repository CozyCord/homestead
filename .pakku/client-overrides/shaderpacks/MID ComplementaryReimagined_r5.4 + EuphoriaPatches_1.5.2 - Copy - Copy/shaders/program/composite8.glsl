/////////////////////////////////////
// Complementary Shaders by EminGT //
// With Euphoria Patches by SpacEagle17 //
/////////////////////////////////////
#include "/lib/common.glsl"

#ifdef FRAGMENT_SHADER
in vec2 knifePos;
in vec2 knifeDir;
in float isKnifeDown;
in vec2 texelPos;
in float healing;

void drawKnife(inout vec3 color, vec2 uv, vec2 pos, vec2 dir, float scale) {
    vec2 localUV = mat2(vec2(1, -1) * dir, dir.yx) * (uv - pos) / scale;

    const float knifeRot0 = 0.3;
    const vec2 knifeOffset = vec2(0.3, -0.05);
    const mat2 knifeRotMat0 = mat2(cos(knifeRot0), sin(knifeRot0), -sin(knifeRot0), cos(knifeRot0));
    localUV = knifeRotMat0 * localUV + knifeOffset;
    float bladeLen0 = length(localUV * vec2(1, 2) - vec2(0.2, 0.5));

    float bladeLen1 = length(localUV - vec2(0.9, 1.5));
    float bladeLen2 = length(localUV - vec2(-0.8, 6.0));
    if (bladeLen0 < 0.6 && bladeLen1 > 1.3 && bladeLen2 > 5.8) {
        color = vec3(0.7);
        if (bladeLen0 > 0.5) color = vec3(0.9);
    }
    vec2 handleMidCoord = vec2(-0.6, 0.13);
    vec2 handleScale = vec2(2.0, 5.0);
    float handleDist = length(pow(abs(localUV - handleMidCoord) * handleScale, vec2(3)));
    if (handleDist < 1.0) {
        color = vec3(0.6,0.2,0.0);
        color += 0.1 * (localUV.y * handleScale.y - handleMidCoord.y + 0.5);
    }
}

void main() {
    #ifdef RENKO_CUT
        vec4 cutData = texelFetch(colortex1, texelCoord, 0);
        vec4 color = texelFetch(colortex3, texelCoord, 0);
        vec2 relPos = texelPos - knifePos;
        float projW = dot(relPos, knifeDir);
        float error = length(relPos - projW * knifeDir);
        if (isKnifeDown > 0.5 && error < 0.01 * (0.6 - 70.0 *  projW * projW)) {
            cutData.g = 1.0;
        } else if (healing > 0.5) {
            float aroundHealthy = 0;
            for (int k = 0; k < 4; k++) {
                ivec2 offset = (k/2*2-1) * ivec2(k%2, (k+1)%2);
                aroundHealthy += texelFetch(colortex1, texelCoord + offset, 0).g;
            }
            if (aroundHealthy < 3.5) cutData.g = 0.0;
        }
        if (cutData.g > 0.5) {
            color = vec4(0, 0, 0, 1);
        }
        drawKnife(color.rgb, texelPos, knifePos, -knifeDir, 0.2);
        if (frameCounter < 10) {
            cutData.g = 0.0;
        }
        /* DRAWBUFFERS:31 */
        gl_FragData[0] = color;
        gl_FragData[1] = cutData;
    #endif
}
#endif
#ifdef VERTEX_SHADER
out vec2 knifePos;
out vec2 knifeDir;
out float isKnifeDown;
out vec2 texelPos;
out float healing;

vec3 knifePosList[84] = vec3[84](
    vec3(0.1, 0.7, 1),
    vec3(0.1, 0.5, 1),
    vec3(0.1, 0.3, 1),
    vec3(0.15, 0.3, 1),
    vec3(0.15, 0.45, 1),
    vec3(0.2, 0.45, 1),
    vec3(0.27, 0.3, 1),
    vec3(0.32, 0.3, 1),
    vec3(0.25, 0.47, 1),
    vec3(0.3, 0.55, 1),
    vec3(0.3, 0.62, 1),
    vec3(0.25, 0.7, 1),
    vec3(0.1, 0.7, 0),
    vec3(0.4, 0.7, 1),
    vec3(0.4, 0.5, 1),
    vec3(0.4, 0.3, 1),
    vec3(0.53, 0.3, 1),
    vec3(0.65, 0.3, 1),
    vec3(0.65, 0.35, 1),
    vec3(0.45, 0.35, 1),
    vec3(0.45, 0.475, 1),
    vec3(0.6, 0.475, 1),
    vec3(0.6, 0.525, 1),
    vec3(0.45, 0.525, 1),
    vec3(0.45, 0.65, 1),
    vec3(0.65, 0.65, 1),
    vec3(0.65, 0.7, 1),
    vec3(0.4, 0.7, 0),
    vec3(0.7, 0.7, 1),
    vec3(0.7, 0.5, 1),
    vec3(0.7, 0.3, 1),
    vec3(0.75, 0.3, 1),
    vec3(0.75, 0.45, 1),
    vec3(0.75, 0.6, 1),
    vec3(0.825, 0.45, 1),
    vec3(0.9, 0.3, 1),
    vec3(0.95, 0.3, 1),
    vec3(0.95, 0.5, 1),
    vec3(0.95, 0.7, 1),
    vec3(0.9, 0.7, 1),
    vec3(0.9, 0.55, 1),
    vec3(0.9, 0.4, 1),
    vec3(0.825, 0.55, 1),
    vec3(0.75, 0.7, 1),
    vec3(0.7, 0.7, 0),
    vec3(1.0, 0.7, 1),
    vec3(1.0, 0.5, 1),
    vec3(1.0, 0.3, 1),
    vec3(1.05, 0.3, 1),
    vec3(1.05, 0.5, 1),
    vec3(1.15, 0.4, 1),
    vec3(1.23, 0.3, 1),
    vec3(1.29, 0.3, 1),
    vec3(1.2, 0.42, 1),
    vec3(1.13, 0.48, 1),
    vec3(1.2, 0.59, 1),
    vec3(1.28, 0.7, 1),
    vec3(1.22, 0.7, 1),
    vec3(1.15, 0.61, 1),
    vec3(1.1, 0.56, 1),
    vec3(1.05, 0.6, 1),
    vec3(1.05, 0.7, 1),
    vec3(1.0, 0.7, 0),
    vec3(1.35, 0.6, 1),
    vec3(1.35, 0.4, 1),
    vec3(1.43, 0.3, 1),
    vec3(1.52, 0.3, 1),
    vec3(1.6, 0.4, 1),
    vec3(1.6, 0.6, 1),
    vec3(1.52, 0.7, 1),
    vec3(1.43, 0.7, 1),
    vec3(1.35, 0.6, 0),
    vec3(1.4, 0.55, 1),
    vec3(1.4, 0.45, 1),
    vec3(1.475, 0.38, 1),
    vec3(1.55, 0.45, 1),
    vec3(1.55, 0.55, 1),
    vec3(1.475, 0.62, 1),
    vec3(1.4, 0.55, 0),
    vec3(1.2, 0.7, 0),
    vec3(0.8, 0.8, 0),
    vec3(0.5, 0.8, 0),
    vec3(0.2, 0.75, 0),
    vec3(0.1, 0.7, 0)
);

void main() {
    #ifdef RENKO_CUT
    gl_Position = ftransform();
    texelPos = 0.5 * gl_Position.xy + 0.5;
    texelPos.x *= aspectRatio;
    float cutProgress = max(0, frameTimeCounter * 2 - 40.0);
    int thisIndex = int(cutProgress) % knifePosList.length();
    healing = float(thisIndex > knifePosList.length() - 5);
    int nextIndex = (thisIndex+1) % knifePosList.length();
    knifePos = mix(
        knifePosList[thisIndex].xy,
        knifePosList[nextIndex].xy,
        mod(cutProgress, float(knifePosList.length())) - thisIndex);
    knifeDir = normalize(knifePosList[nextIndex].xy - knifePosList[thisIndex].xy);
    isKnifeDown = knifePosList[thisIndex].z;
    #endif
}
#endif