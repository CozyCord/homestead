/////////////////////////////////////
// Complementary Shaders by EminGT //
// With Euphoria Patches by SpacEagle17 //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

//Pipeline Constants//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    discard;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

//Pipeline Constants//
#if END_CRYSTAL_VORTEX_INTERNAL > 0 || DRAGON_DEATH_EFFECT_INTERNAL > 0 || defined END_PORTAL_BEAM_INTERNAL
    #extension GL_ARB_shader_image_load_store : enable
#endif

//Uniforms//
#if END_CRYSTAL_VORTEX_INTERNAL > 0 || DRAGON_DEATH_EFFECT_INTERNAL > 0 || defined END_PORTAL_BEAM_INTERNAL
    layout(r32i) uniform iimage2D endcrystal_img;
#endif
//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    #if END_CRYSTAL_VORTEX_INTERNAL > 0 || DRAGON_DEATH_EFFECT_INTERNAL > 0 || defined END_PORTAL_BEAM_INTERNAL
        vec4 position0 = ftransform();
        if (position0.x < 0.0 && position0.y > 0.0) {
            #if END_CRYSTAL_VORTEX_INTERNAL % 2 == 1
                // update temporally stable end crystal data
                for (int index = 0; index < 20; index++) {
                    int state = imageLoad(endcrystal_img, ivec2(index, 8)).r;
                    state -= max(1, int(10000 * frameTime));
                    if (state < 0) {
                        for (int i = 0; i < 5; i++) {
                            imageStore(endcrystal_img, ivec2(index, i+5), ivec4(0));
                        }
                    } else {
                        ivec4 writeData = ivec4(
                            imageLoad(endcrystal_img, ivec2(index, 5)).r,
                            imageLoad(endcrystal_img, ivec2(index, 6)).r,
                            imageLoad(endcrystal_img, ivec2(index, 7)).r,
                            state
                        );
                        writeData.xyz += ivec3(10000 * (previousCameraPosition - cameraPosition));
                        for (int i = 0; i < 4; i++) {
                            imageStore(endcrystal_img, ivec2(index, i+5), ivec4(writeData[i]));
                        }
                        imageStore(endcrystal_img, ivec2(index, 9), ivec4(
                            imageLoad(endcrystal_img, ivec2(index, 9)).r + int(10000 * frameTime)
                        ));
                    }
                }
                // crystals
                for (int index = 0; index < 20; index++) {
                    ivec4 newData = ivec4(
                        imageLoad(endcrystal_img, ivec2(index, 1)).r,
                        imageLoad(endcrystal_img, ivec2(index, 2)).r,
                        imageLoad(endcrystal_img, ivec2(index, 3)).r,
                        imageLoad(endcrystal_img, ivec2(index, 4)).r
                    );
                    if (newData.w > 0) {
                        vec3 pos = vec3(newData.xyz) / newData.w;
                        int temporalIndex = -1;
                        for (int k = 0; k < 20; k++) {
                            ivec4 temporalData = ivec4(
                                imageLoad(endcrystal_img, ivec2(k, 5)).r,
                                imageLoad(endcrystal_img, ivec2(k, 6)).r,
                                imageLoad(endcrystal_img, ivec2(k, 7)).r,
                                imageLoad(endcrystal_img, ivec2(k, 8)).r
                            );
                            vec3 temporalPos = 0.0001 * temporalData.xyz;
                            if (temporalData.w > 0 && length((temporalPos - pos) * vec3(1.0, 0.3, 1.0)) < 1.0) {
                                temporalIndex = k;
                                break;
                            }
                        }
                        if (temporalIndex == -1) {
                            for (int k = 0; k < 20; k++) {
                                int previousWeight = imageAtomicCompSwap(endcrystal_img, ivec2(k, 8), 0, -1);
                                if (previousWeight == 0) {
                                    temporalIndex = k;
                                    break;
                                }
                            }
                        }
                        if (temporalIndex >= 0) {
                            ivec4 storeData = ivec4(10000 * pos, 16000);
                            for (int i = 0; i < 4; i++) {
                                imageStore(endcrystal_img, ivec2(temporalIndex, i+5), ivec4(storeData[i]));
                            }
                        }
                    }
                }
            #endif
            #if END_CRYSTAL_VORTEX_INTERNAL / 2 == 1
                // healing beams
                for (int index = 20; index < 35; index++) {
                    ivec4 writeData = ivec4(
                        imageLoad(endcrystal_img, ivec2(index, 1)).r,
                        imageLoad(endcrystal_img, ivec2(index, 2)).r,
                        imageLoad(endcrystal_img, ivec2(index, 3)).r,
                        imageLoad(endcrystal_img, ivec2(index, 4)).r
                    );
                    for (int i = 0; i < 4; i++) {
                        imageStore(endcrystal_img, ivec2(index, i + 5), ivec4(writeData[i]));
                    }
                }
            #endif
            #if END_CRYSTAL_VORTEX_INTERNAL / 2 == 1 || DRAGON_DEATH_EFFECT_INTERNAL > 0
                // dragon position
                {
                    const int index = 35;
                    int isDying = imageLoad(endcrystal_img, ivec2(index, 0)).r;
                    // if (isDying == 0) isDying = 10000; // Helpful for debugging
                    ivec4 readData = ivec4(
                        imageLoad(endcrystal_img, ivec2(index, 1)).r,
                        imageLoad(endcrystal_img, ivec2(index, 2)).r,
                        imageLoad(endcrystal_img, ivec2(index, 3)).r,
                        imageLoad(endcrystal_img, ivec2(index, 4)).r
                    );
                    ivec4 temporalData = ivec4(
                        imageLoad(endcrystal_img, ivec2(index, 5)).r,
                        imageLoad(endcrystal_img, ivec2(index, 6)).r,
                        imageLoad(endcrystal_img, ivec2(index, 7)).r,
                        imageLoad(endcrystal_img, ivec2(index, 8)).r
                    );
                    ivec4 writeData = ivec4(
                        readData.w > 0 ? 10000.0 * readData.xyz / readData.w : temporalData.xyz + ivec3(10000 * (previousCameraPosition - cameraPosition)),
                        isDying > 0 ? temporalData.w + int(10000 * frameTime) : 0
                    );
                    imageStore(endcrystal_img, ivec2(index, 0), ivec4(max(0, isDying - int(1000 * frameTime))));
                    for (int i = 0; i < 4; i++) {
                        imageStore(endcrystal_img, ivec2(index, i + 1), ivec4(0));
                        imageStore(endcrystal_img, ivec2(index, i + 5), ivec4(writeData[i]));
                    }
                }
                #endif
            
            #ifdef END_PORTAL_BEAM_INTERNAL
                for (int k = 0; k < 4; k++) {
                    imageStore(
                        endcrystal_img,
                        ivec2(35, k+5),
                        imageLoad(endcrystal_img, ivec2(35, k))
                    );
                }
            #endif
            // clear temporally unstable data
            for (int index = 0; index < 36; index++) {
                #if DRAGON_DEATH_EFFECT_INTERNAL > 0
                    if (index == 35) {
                        continue;
                    }
                #endif
                for (int i = 0; i < 5; i++) {
                    imageStore(endcrystal_img, ivec2(index, i), ivec4(0));
                }
            }
        }
        gl_Position = vec4(-1);
    #endif
}

#endif
