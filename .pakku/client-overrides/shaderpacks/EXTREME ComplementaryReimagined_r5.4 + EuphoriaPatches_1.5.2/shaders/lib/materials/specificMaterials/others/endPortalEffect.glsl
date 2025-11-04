// End Portal fix by fayer3#2332 (Modified)
float dither = Bayer64(gl_FragCoord.xy);
#ifdef TAA
    dither = fract(dither + goldenRatio * mod(float(frameCounter), 3600.0));
    int repeat = 4;
#else
    int repeat = 8;
#endif

#if END_PORTAL_VARIATION == 0 || END_PORTAL_VARIATION == 1
    #if END_PORTAL_VARIATION == 0
        vec3[8] colors = vec3[](
            vec3(0.3472479, 0.6559956, 0.7387838) * 1.5,
            vec3(0.6010780, 0.7153565, 1.060625 ),
            vec3(0.4221090, 0.8135094, 0.9026056),
            vec3(0.3492291, 1.0241201, 1.8612821),
            vec3(0.7543085, 0.8238697, 0.6803233),
            vec3(0.4144472, 0.5648165, 0.8037   ),
            vec3(0.508905 , 0.6719649, 0.9982805),
            vec3(0.5361914, 0.4476583, 0.8008522));
        color.rgb = vec3(0.421, 0.7, 1.6) * 0.14;
    #else
        vec3[3] colors = vec3[](
            vec3(1.0, 0.0, 0.0),
            vec3(0.0, 1.0, 0.0),
            vec3(0.0, 0.0, 1.0));
        color.rgb = vec3(0.4214321, 0.4722309, 1.9922364) * 0.08;
    #endif

    float dismult = 0.5;
    for (int j = 0; j < repeat; j++) {
        float add = float(j + dither) * 0.0625 / float(repeat);
        for (int i = 1; i <= 8; i++) {
            vec2 offset = vec2(0.0, 1.0/(3600.0/24.0)) * pow(16.0 - i, 2.0) * 0.004;
            vec2 wind = fract((frameTimeCounter + 984.0) * (i + 8) * 0.125 * offset);

            vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos * (i * dismult + 1), 1.0)).xyz);
            if (abs(NdotU) > 0.9) {
                wpos.xz /= wpos.y;
                wpos.xz *= 0.06 * sign(- playerPos.y);
                wpos.xz *= abs(playerPos.y) + i * dismult + add;
                wpos.xz -= cameraPosition.xz * 0.05;
            } else {
                vec3 absPos = abs(playerPos);
                if (abs(dot(normal, eastVec)) > 0.9) {
                    wpos.xz = wpos.yz / wpos.x;
                    wpos.xz *= 0.06 * sign(- playerPos.x);
                    wpos.xz *= abs(playerPos.x) + i * dismult + add;
                    wpos.xz -= cameraPosition.yz * 0.05;
                } else {
                    wpos.xz = wpos.yx / wpos.z;
                    wpos.xz *= 0.06 * sign(- playerPos.z);
                    wpos.xz *= abs(playerPos.z) + i * dismult + add;
                    wpos.xz -= cameraPosition.yx * 0.05;
                }
            }
            vec2 pos = wpos.xz;

            #if END_PORTAL_VARIATION == 0
                float colormult = 0.9/(30.0+i);
                float rotation = (i - 0.1 * i + 0.71 * i - 11 * i + 21) * 0.01 + i * 0.01;
                float Cos = cos(radians(rotation));
                float Sin = sin(radians(rotation));

                vec2 coord = mat2(Cos, Sin, -Sin, Cos) * pos + wind;
                if (mod(float(i), 4) < 1.5) coord = coord.yx + vec2(-1.0, 1.0) * wind.y;

                vec3 psample = pow(texture2D(tex, coord).rgb, vec3(0.85)) * colors[i-1] * colormult;
                color.rgb += psample * length(psample.rgb) * (3000.0 / repeat);
            #else
                float noisePortal = texture2D(noisetex, pos * 0.5).g;
                color.rgb += texture2D(noisetex, vec2(noisePortal, noisePortal) + wind * 2.0).g * colors[i % 3] * 0.1;
            #endif
        }
    }
    color.rgb *= vec3(0.09, 0.086, 0.06) * 0.9;
    emission = 10.0;
#elif END_PORTAL_VARIATION == 3 // Thanks to WoMspace
    float portalEffectSpeed = 3.0;
    vec3 roundedCoords = floor((playerPos - vec3(0.001) + cameraPosition) * 16.0); // not perfect yet, portal shifts when moving up or down
    float pixelPortalEffect = 0.0;
    for (int i = 0; i < 5; i++){
        float currentTime = floor(frameTimeCounter * portalEffectSpeed + float(i));
        float nextTime = floor(frameTimeCounter * portalEffectSpeed + 1.0 + float(i));
        // float currentFrame = hash14(vec4(roundedCoords, floor(worldPos.y * 16.0), currentTime));
        float currentFrame = hash13(vec3(roundedCoords + currentTime));
        // float nextFrame = hash14(vec4(roundedCoords, floor(worldPos.y * 16.0), nextTime));
        float nextFrame = hash13(vec3(roundedCoords + nextTime));
        pixelPortalEffect += mix(currentFrame, nextFrame, fract(frameTimeCounter * portalEffectSpeed));
    }
    pixelPortalEffect /= 5.0;

    color.rgb = vec3(0.37, 0.5, 0.8) * pow(pixelPortalEffect, 5.0) * 10.0;
    emission = pow(pixelPortalEffect, 5.0) * 2.0;
    lmCoordM.x = 0.0;
#endif
noDirectionalShading = true;

#ifdef COATED_TEXTURES
    noiseFactor = 0.0;
#endif

#ifdef PORTAL_EDGE_EFFECT
    //vec3 voxelPos = SceneToVoxel(mix(playerPos, vec3(0.0), -0.02)); // Fixes weird parallax offset
    vec3 voxelPos = SceneToVoxel(playerPos);

    if (CheckInsideVoxelVolume(voxelPos)) {
        float portalOffset = 0.08333 * dither;
        vec3[4] portalOffsets = vec3[](
            vec3( portalOffset, 0, portalOffset),
            vec3( portalOffset, 0,-portalOffset),
            vec3(-portalOffset, 0, portalOffset),
            vec3(-portalOffset, 0,-portalOffset)
        );

        float edge = 0.0;
        for (int i = 0; i < 4; i++) {
            int voxel = int(texelFetch(voxel_sampler, ivec3(voxelPos + portalOffsets[i]), 0).r);
            if (voxel == 58 || voxel == 255) { // End Portal Frame or Bedrock
                edge = 1.0; break;
            }
        }
        
        #ifdef END
            // No edge effect in the middle of the return fountain
            vec2 var1 = abs(playerPos.xz + cameraPosition.xz - 0.5);
            float var2 = max(var1.x, var1.y);
            if (var2 > 1.0)
        #endif
        {
            vec4 edgeColor = vec4(vec3(0.18, 0.5, 0.45), 1.0);
            #if END_PORTAL_VARIATION == 3
                edgeColor = vec4(vec3(0.2431, 0.2588, 0.7294), 1.0);
            #endif
            color = mix(color, edgeColor, edge);
            emission = mix(emission, 5.0, edge);
        }
    }
#endif