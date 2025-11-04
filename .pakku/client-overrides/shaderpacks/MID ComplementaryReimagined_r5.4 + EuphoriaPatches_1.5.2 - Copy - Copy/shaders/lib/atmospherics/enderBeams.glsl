#ifndef INCLUDE_ENDER_BEAMS
    #define INCLUDE_ENDER_BEAMS

    #include "/lib/colors/lightAndAmbientColors.glsl"

    vec3 endDragonCol = vec3(E_DRAGON_BEAM_R, E_DRAGON_BEAM_G, E_DRAGON_BEAM_B) / 255.0 * E_DRAGON_BEAM_I;
    vec3 beamCol = normalize(endColorBeam * endColorBeam * endColorBeam) * (2.5 - 1.0 * vlFactor) * E_BEAM_I;
    vec3 beamDragon = endDragonCol * (300.0 + 700.0 * vlFactor);

    vec2 wind = vec2(syncedTime * 0.00);

    float BeamNoise(vec2 planeCoord, vec2 wind) {
        float noise = texture2D(noisetex, planeCoord * 0.175   - wind * 0.0625).b;
            noise+= texture2D(noisetex, planeCoord * 0.04375 + wind * 0.0375).b * 5.0;

        return noise;
    }

    vec3 DrawEnderBeams(float VdotU, vec3 playerPos) {
        int sampleCount = 8;

        float VdotUM = 1.0 - VdotU * VdotU;
        float VdotUM2 = VdotUM + smoothstep1(pow2(pow2(1.0 - abs(VdotU)))) * 0.2;

        vec4 beams = vec4(0.0);
        float gradientMix = 1.0;
        for (int i = 0; i < sampleCount; i++) {
            vec2 planeCoord = playerPos.xz + cameraPosition.xz;
            planeCoord *= (1.0 + i * 6.0 / sampleCount) * 0.0014;

            float noise = BeamNoise(planeCoord, wind);
            #ifndef BEAMS_NEAR_PLAYER
                noise = max(0.75 - 1.0 / abs(noise - (4.0 + VdotUM * 2.0)), 0.0) * 3.0;
            #else
                noise = max(0.75 - 1.0 / abs(noise - (4.0 + dot(upVec, upVec) * 2.0)), 0.0) * 3.0;
            #endif


            if (noise > 0.0) {
                noise *= 0.65;
                float fireNoise = texture2D(noisetex, abs(planeCoord * 0.2) - wind).b;
                noise *= 0.5 * fireNoise + 0.75;
                noise = noise * noise * 3.0 / sampleCount;
                #ifndef BEAMS_NEAR_PLAYER
                    noise *= VdotUM2;
                #endif

                vec3 beamColor = beamCol;
                beamColor += beamDragon * pow2(pow2(fireNoise - 0.5));
                beamColor *= gradientMix / sampleCount;

                noise *= exp2(-6.0 * i / float(sampleCount));
                beams += vec4(noise * beamColor, noise);
            }
            gradientMix += 1.0;
        }
        #ifdef EPIC_THUNDERSTORM
            beams.rgb += 0.2 * isLightningActive();
        #endif
        beams.rgb *= beams.a * beams.a * beams.a * 3.5;
        beams.rgb = sqrt(beams.rgb);

        return beams.rgb;
    }

#endif //INCLUDE_ENDER_BEAMS