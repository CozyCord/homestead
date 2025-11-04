// Yes I hate myself for having done all of this in a big file and with functions. Thanks you me from a year ago

#ifndef GBUFFERS_HAND
    vec3 oldColor = color.rgb; // Needed for entities

    #if SEASONS != 2 && SEASONS != 5
        // Color Desaturation
        vec3 desaturatedColor = color.rgb;
        if (SEASON_COLOR_DESATURATION > 0.0) {
            float desaturation = SEASON_COLOR_DESATURATION;

            #if SEASONS == 1 || SEASONS == 4
                if (winterTime > 0) {
                    // snow conditions
                    #if SNOW_CONDITION != 2
                        desaturation *= inSnowy; // make only appear in cold biomes
                    #elif SNOW_CONDITION == 0
                        desaturation *= rainFactor; // make only appear in rain
                    #endif
                }
            #endif

            desaturatedColor = mix(color.rgb, vec3(GetLuminance(color.rgb)), clamp01(desaturation - lmCoord.x));
        }
    #endif

    bool dhLeaves = true;
    #ifdef DH_TERRAIN
        if (mat == DH_BLOCK_LEAVES && dhColor.r < 0.17 || dhColor.r > 0.7) dhLeaves = false;
    #endif

    #if SEASONS == 1 || SEASONS == 2
        vec3 summerColor = color.rgb;
        if (summerTime > 0) {
            #if defined GBUFFERS_TERRAIN || defined DH_TERRAIN
                if (isFoliage && dhLeaves || mat == 10132 && glColor.b < 0.999) { // Normal Grass Block
                    summerColor = mix(summerColor, GetLuminance(summerColor) * vec3(1.0, 0.8941, 0.3725), 0.3 * SUMMER_STRENGTH);
                }
            #endif
        }
    #endif

    float autumnOnlyForests = 1.0;
    #ifdef AUTUMN_CONDITION
        autumnOnlyForests = inForest;
    #endif

    #if SEASONS == 1 || SEASONS == 3
        vec3 autumnColor = vec3(0);

        if (autumnTime > 0 && inPaleGarden < 0.5) {
            autumnColor = mix(color.rgb, desaturatedColor, 0.65 * autumnOnlyForests);

            #if defined GBUFFERS_TERRAIN || defined GBUFFERS_BLOCK || defined DH_TERRAIN
                const vec3 autumnLeafColor0 = vec3(0.9922, 0.5707, 0.098);
                const vec3 autumnLeafColor1 = vec3(0.9922, 0.4786, 0.098);
                const vec3 autumnLeafColor2 = vec3(0.9804, 0.4033, 0.1569);
                const vec3 autumnLeafColor3 = vec3(0.9765, 0.3333, 0.149);
                const vec3 autumnLeafColor4 = vec3(0.9765, 0.1333, 0.149);

                float noiseLeavesColor1 = smoothstep(0.4, 0.7,  Noise3D(worldPos * 0.0001 * AUTUMN_NOISE_SIZE));
                float noiseLeavesColor2 = smoothstep(0.3, 0.7,  Noise3D(worldPos * 0.0003 * AUTUMN_NOISE_SIZE + 300.0));
                float noiseLeavesColor3 = smoothstep(0.65, 0.7, Noise3D(worldPos * 0.0005 * AUTUMN_NOISE_SIZE + 700.0));
                float noiseLeavesColor4 = smoothstep(0.7, 0.8, Noise3D(worldPos * 0.0003 * AUTUMN_NOISE_SIZE + 1000.0));

                vec3 leafMainColor = mix(mix(mix(mix(autumnLeafColor0, autumnLeafColor1, noiseLeavesColor1), autumnLeafColor2, noiseLeavesColor2), autumnLeafColor3, noiseLeavesColor3), autumnLeafColor4, noiseLeavesColor4)  * 1.5; // giant mix :p

                if (isFoliage) {
                    if (mat == 10009 || mat == 10011
                    #ifdef DH_TERRAIN
                        || mat == DH_BLOCK_LEAVES && isFoliage && dhLeaves
                    #endif
                    ) { // Except some leaves
                        autumnColor *= mix(vec3(1.0), leafMainColor, autumnOnlyForests);
                    } else {
                        autumnColor *= mix(vec3(1.0), vec3(0.9882, 0.7725, 0.5725), autumnOnlyForests * 0.5);
                    }
                } else { // leaves on the ground
                    if ((mat == 10132
                    #ifdef DH_TERRAIN
                        || mat == DH_BLOCK_GRASS
                    #endif
                    ) && glColor.b < 0.999) { // Normal Grass Block, grass part
                        autumnColor *= mix(vec3(1.0), vec3(0.9882, 0.7725, 0.5725), autumnOnlyForests * 0.4);
                    }
                    #ifdef LEAVES_ON_GROUND
                        vec3 absPlayerPos = abs(playerPos);
                        float maxPlayerPosXZ = max(absPlayerPos.x, absPlayerPos.z);
                        float leafDecider = -clamp01(pow2(min1(maxPlayerPosXZ / 100) * 2.0)) + 1.0; // The effect will only be around the player
                        if (leafDecider > 0.001){
                            float noiseLeavesFloorColor = float(hash33(floor(mod(worldPos, vec3(100.0)) * 16 + 0.03) * 16)) * 0.25;

                            vec3 leafFloorColorRandomMess = mix(mix(mix(mix(autumnLeafColor0, autumnLeafColor1, noiseLeavesFloorColor), autumnLeafColor2, noiseLeavesFloorColor), autumnLeafColor3, noiseLeavesFloorColor), autumnLeafColor4, noiseLeavesFloorColor) * 2.0;

                            vec3 leafFloorColor = mix(leafFloorColorRandomMess, leafMainColor, 0.6); // this mixes between the random colors and the colors of the leaves at the world pos

                            vec2 leafVec = getOverlayNoise(0.0, true, false, 0.1, 16, worldPos, 1.0, 0.0);

                            float leafFloorNoise = leafVec.y;
                            float leafVariable = leafVec.x;

                            leafVariable *= (1.0 - pow(lmCoord.y + 0.01, 30.0)) * pow(lmCoord.y + 0.01, 2.0);

                            leafFloorColor += 0.13 * leafFloorNoise; // make the noise less noticeable

                            float leafAddNoise1 = 1.0 - texture2D(noisetex, 0.0005 * (worldPos.xz + worldPos.y)).r * 1.3;
                            float leafAddNoise2 = 1.0 - texture2D(noisetex, 0.005 * (worldPos.xz + worldPos.y)).r * 1.3;
                            float leafAddNoise3 = texture2D(noisetex, 0.02 * (worldPos.xz + worldPos.y)).r * 1.3;
                            leafVariable += mix(0.0, lmCoord.y * 1.0 - clamp(2.0 * leafAddNoise1 + 0.70 * leafAddNoise2 + 0.2 * leafAddNoise1, 0.0, 1.0), inForest);
                            leafVariable = clamp01(leafVariable);

                            leafVariable *= abs(clamp01(dot(normal, upVec))); // make only appear on top of blocks

                            leafVariable *= leafDecider;

                            autumnColor *= mix(vec3(1.0), leafFloorColor, leafVariable * overlayNoiseIntensity * autumnOnlyForests);
                        }
                    #endif
                }

            #endif

            #ifndef GBUFFERS_ENTITIES
                autumnColor *= mix(vec3(1.0), vec3(1.0, 0.7, 0.5), autumnTime * 0.7 * autumnOnlyForests * AUTUMN_STRENGTH);
            #endif
        }
    #endif

    #if (SEASONS == 1 || SEASONS == 3 || SEASONS == 4) && (defined GBUFFERS_TERRAIN || defined DH_TERRAIN) && LESS_LEAVES > 0
        if (mat == 10009 || mat == 10011) { // Except some leaves
            #if defined MIRROR_DIMENSION || defined WORLD_CURVATURE || defined WAVING_ANYTHING_TERRAIN || defined WAVE_EVERYTHING || defined INTERACTIVE_FOLIAGE
                vec3 worldLeavesNoise = beforeTransformPos.xyz;
            #else
                vec3 worldLeavesNoise = playerPos.xyz;
            #endif
            float autumnWinterTime = autumnTime + winterTime;
            #if SNOW_CONDITION != 2
                autumnWinterTime *= mix(inSnowy + autumnOnlyForests, inSnowy, winterTime); // make only appear in cold biomes during winter
            #endif
            #if SNOW_CONDITION == 0
                autumnWinterTime *= mix(rainFactor + autumnOnlyForests, rainFactor, winterTime); // make only appear in rain during winter
            #endif
            float noiseLeaveAlpha = step(autumnWinterTime * LESS_LEAVES * 0.15, hash13(floor(mod(worldLeavesNoise - 0.001 * (mat3(gbufferModelViewInverse) * normal) + cameraPosition.xyz, vec3(100.0)) * 4) * 4)); // remove some leaves with noise
            noiseLeaveAlpha += step(autumnWinterTime * LESS_LEAVES * 0.13, hash13(floor(mod(worldLeavesNoise - 0.001 * (mat3(gbufferModelViewInverse) * normal) + cameraPosition.xyz, vec3(100.0)) * 16) * 16));
            color.a *= noiseLeaveAlpha;
        }
    #endif

    #if SEASONS == 1 || SEASONS == 4
        vec3 winterColor = vec3(0);

        if (winterTime > 0) {
            float snowSide = 0.0;
            #if !defined GBUFFERS_ENTITIES && defined GBUFFERS_TERRAIN
                if (isFoliage) snowSide = mix(1.0, 0.0, 1.0 / (color.g * color.g) * 0.05); // make all foliage white
                #ifndef DH_TERRAIN
                if ((mat == 10132 && glColor.b < 0.999) || (mat == 10126 && color.b + color.g < color.r * 2.0 && color.b > 0.3 && color.g < 0.45) || (mat == 10493 && color.r > 0.52 && color.b < 0.30 && color.g > 0.41 && color.g + color.b * 0.95 > color.r * 1.2)) { // Normal Grass Block and Dirt Path
                    snowSide = mix(0.0, 1.0, pow(blockUV.y, 3.0));
                    #if defined SSS_SEASON_SNOW && (SEASONS == 1 || SEASONS == 4)
                        #if SNOW_CONDITION == 0
                            if (rainFactor > 0 && inSnowy > 0) subsurfaceMode = 3, noSmoothLighting = true, noDirectionalShading = true; // SSS
                        #elif SNOW_CONDITION == 1
                            if (inSnowy > 0) subsurfaceMode = 3, noSmoothLighting = true, noDirectionalShading = true;
                        #else
                            subsurfaceMode = 3, noSmoothLighting = true, noDirectionalShading = true;
                        #endif
                    #endif
                } // add to the side of grass, mycelium, path blocks; in that order. Use blockUV to increase transparency the the further down the block it goes
                #endif
                if (mat == 10132 && glColor.b < 0.999) snowSide += abs(color.g - color.g * 0.5); // Normal Grass Block, mute the grass colors a bit

                if ((mat == 10132
                #ifdef DH_TERRAIN
                    || mat == DH_BLOCK_GRASS
                #endif
                ) && glColor.b < 0.999 || isFoliage && dhLeaves && mat != 10007) { // Foliage except some leaves
                    desaturatedColor = mix(desaturatedColor, mix(saturateColors(desaturatedColor, 0.4), desaturatedColor * vec3(0.9098, 0.6118, 0.4118), 0.5), winterTime * (1.0 - WINTER_GREEN_AMOUNT));
                }
            #endif

            winterColor = desaturatedColor;

            #ifdef GBUFFERS_ENTITIES
                oldColor = mix(color.rgb, winterColor, winterTime);
            #else
                float winterAlpha = color.a;

                vec3 snowColor = vec3(0.9713, 0.9691, 0.9891);

                vec2 snowVec = getOverlayNoise(snowSide, false, false, MELTING_RADIUS, SNOW_SIZE, worldPos, SNOW_TRANSPARENCY, SNOW_NOISE_REMOVE_INTENSITY * 1.2);

                float snowNoise = snowVec.y;
                float snowVariable = snowVec.x;

                snowColor *= 1.1;
                snowColor += 0.13 * snowNoise * SNOW_NOISE_INTENSITY; // make the noise less noticeable & configurable with option

                // snow conditions
                #if SNOW_CONDITION != 2
                    snowVariable *= inSnowy; // make only appear in cold biomes
                #endif
                #if SNOW_CONDITION == 0
                    snowVariable *= rainFactor; // make only appear in rain
                #endif

                #if SNOW_CONDITION == 0
                    highlightMult = mix(highlightMult, 2.3 - subsurfaceMode * 0.1, snowVariable * IPBRMult * winterTime * rainFactor * inSnowy * overlayNoiseIntensity);
                    smoothnessG = mix(smoothnessG, 0.45 + 0.1 * snowNoise, snowVariable * IPBRMult * winterTime * rainFactor * inSnowy * overlayNoiseIntensity);
                #elif SNOW_CONDITION == 1
                    highlightMult = mix(highlightMult, 2.3 - subsurfaceMode * 0.1, snowVariable * IPBRMult * winterTime * inSnowy * overlayNoiseIntensity);
                    smoothnessG = mix(smoothnessG, 0.45 + 0.1 * snowNoise, snowVariable * IPBRMult * winterTime * inSnowy * overlayNoiseIntensity);
                #else
                    highlightMult = mix(highlightMult, 2.3 - subsurfaceMode * 0.1, snowVariable * IPBRMult * winterTime * overlayNoiseIntensity);
                    smoothnessG = mix(smoothnessG, 0.45 + 0.1 * snowNoise, snowVariable * IPBRMult * winterTime * overlayNoiseIntensity);
                #endif

                #ifdef SSS_SEASON_SNOW
                    if (dot(normal, upVec) > 0.99) {
                        #if SNOW_CONDITION == 0
                            if (rainFactor > 0 && inSnowy > 0) subsurfaceMode = 3, noSmoothLighting = true, noDirectionalShading = true;
                        #elif SNOW_CONDITION == 1
                            if (inSnowy > 0) subsurfaceMode = 3, noSmoothLighting = true, noDirectionalShading = true;
                        #else
                            subsurfaceMode = 3, noSmoothLighting = true, noDirectionalShading = true;
                        #endif
                    }
                #endif

                #ifdef GBUFFERS_TERRAIN
                    if (dot(normal, upVec) > 0.99) {
                        #if SNOW_CONDITION == 0
                            emission = mix(emission, emission * overlayNoiseEmission, rainFactor * inSnowy * winterTime * overlayNoiseIntensity); // make only appear in rain
                            #ifndef DH_TERRAIN
                                smoothnessD = mix(smoothnessD, 0.0, snowVariable * rainFactor * inSnowy * winterTime * overlayNoiseIntensity);
                            #endif
                        #elif SNOW_CONDITION == 1
                            emission = mix(emission, emission * overlayNoiseEmission, inSnowy * winterTime * overlayNoiseIntensity); // make only appear in cold biomes
                            #ifndef DH_TERRAIN
                                smoothnessD = mix(smoothnessD, 0.0, snowVariable * inSnowy * winterTime * overlayNoiseIntensity);
                            #endif
                        #else
                            emission = mix(emission, emission * overlayNoiseEmission, winterTime * overlayNoiseIntensity);
                            #ifndef DH_TERRAIN
                                smoothnessD = mix(smoothnessD, 0.0, snowVariable * winterTime * overlayNoiseIntensity);
                            #endif
                        #endif
                    }
                #endif

                #ifdef GBUFFERS_WATER
                    if (dot(normal, upVec) > 0.99) {
                        #if SNOW_CONDITION == 0
                            overlayNoiseTransparentOverwrite = mix(overlayNoiseTransparentOverwrite, overlayNoiseAlpha, rainFactor * inSnowy * winterTime);
                            fresnel = mix(fresnel, 0.01, snowVariable * overlayNoiseFresnelMult * winterTime * rainFactor * inSnowy);
                        #elif SNOW_CONDITION == 1
                            overlayNoiseTransparentOverwrite = mix(overlayNoiseTransparentOverwrite, overlayNoiseAlpha, inSnowy * winterTime);
                            fresnel = mix(fresnel, 0.01, snowVariable * overlayNoiseFresnelMult * winterTime * inSnowy);
                        #else
                            overlayNoiseTransparentOverwrite = mix(1.0, overlayNoiseAlpha, winterTime);
                            fresnel = mix(fresnel, 0.01, snowVariable * overlayNoiseFresnelMult * winterTime);
                        #endif
                    }
                #endif

                // final mix
                winterColor = mix(winterColor, snowColor, snowVariable * overlayNoiseIntensity);
                winterAlpha = mix(color.a, 1.0, clamp(overlayNoiseTransparentOverwrite * snowVariable, 0.0, 1.0));
                color.a = mix(color.a, winterAlpha, winterTime * overlayNoiseIntensity);
            #endif
        }
    #endif

    #if SEASONS == 1 || SEASONS == 5
        vec3 springColor = color.rgb;
        if (springTime > 0 && inPaleGarden < 0.5) {
            #ifdef GBUFFERS_TERRAIN
                if (isFoliage && dhLeaves || mat == 10132 && glColor.b < 0.999
                #ifdef DH_TERRAIN
                    || mat == DH_BLOCK_GRASS
                #endif
                ) { // Foliage except some leaves, Normal Grass Block
                    if (glColor.b < 0.99) springColor = mix(springColor, GetLuminance(springColor) * vec3(0.3725, 1.0, 0.4235), 0.5 * SPRING_GREEN_INTENSITY);
                }
                #if FLOWER_AMOUNT > 0 && !defined DH_TERRAIN
                    if (mat == 10132) { // Normal Grass Block
                        float flowerNoiseAdd = step(texture2D(noisetex, 0.0005 * (worldPos.xz + atMidBlock.xz / 64)).r, 0.25) * 3.5 + 1.0; // Noise to add more flowers
                        float flowerNoiseRemove = clamp01(step(texture2D(noisetex, 0.003 * (worldPos.xz + atMidBlock.xz / 64)).g, 0.69) + 0.15); // Noise to reduce the amount of flowers

                        ivec2 flowerUV = ivec2(blockUV.xz * FLOWER_SIZE);

                        float flower1Variable = 0.0;
                        float flower2Variable = 0.0;
                        float flower3Variable = 0.0;
                        float flower4Variable = 0.0;
                        float flower5Variable = 0.0;

                        float flower4Emission = 0.0; // this exists to only make the purple part of the flower bud be emissive
                        float flowerEmissionMask = 0.0;

                        const ivec2 flower1Size = ivec2(3, 3);
                        const ivec2 flower2Size = ivec2(3, 3);
                        const ivec2 flower3Size = ivec2(1, 1);
                        const ivec2 flower4Size = ivec2(2, 2);
                        const ivec2 flower5Size = ivec2(5, 5);

                        vec4 flower1Pixels[flower1Size.x * flower1Size.y] = vec4[flower1Size.x * flower1Size.y](
                            vec4(0), vec4(1)                       , vec4(0),
                            vec4(1), vec4(1.0, 0.8784, 0.2706, 1.0), vec4(1),
                            vec4(0), vec4(1)                       , vec4(0)
                        );
                        vec4 flower2Pixels[flower2Size.x * flower2Size.y] = vec4[flower2Size.x * flower2Size.y](
                            vec4(0), vec4(0.9922, 0.7686, 0.4078, 1.0)                          , vec4(0),
                            vec4(0.9922, 0.7686, 0.4078, 1.0), vec4(0.8471, 0.5216, 0.0627, 1.0), vec4(0.9922, 0.7686, 0.4078, 1.0),
                            vec4(0), vec4(0.9922, 0.7686, 0.4078, 1.0)                          , vec4(0)
                        );
                        vec4 flower3Pixels[flower3Size.x] = vec4[flower3Size.x](vec4(1.0, 0.8784, 0.2706, 1.0));
                        vec4 flower4Pixels[flower4Size.x * flower4Size.y] = vec4[flower4Size.x * flower4Size.y](
                            vec4(0.1137, 0.3882, 0.1137, 1.0), vec4(0.5294, 0.2902, 0.5647, 1.0),
                            vec4(0.1059, 0.3333, 0.0863, 1.0), vec4(0.1137, 0.3882, 0.1137, 1.0)
                        );
                        vec4 flower5Pixels[flower5Size.x * flower5Size.y] = vec4[flower5Size.x * flower5Size.y](
                            vec4(0), vec4(0.6627, 0.4118, 0.7373, 1.0), vec4(0.6627, 0.4118, 0.7373, 1.0), vec4(0), vec4(0),
                            vec4(0), vec4(0.6627, 0.4118, 0.7373, 1.0), vec4(0.9137, 0.5882, 0.9647, 1.0), vec4(0.6627, 0.4118, 0.7373, 1.0), vec4(0.6627, 0.4118, 0.7373, 1.0),
                            vec4(0.6627, 0.4118, 0.7373, 1.0), vec4(0.9137, 0.5882, 0.9647, 1.0), vec4(0.8667, 0.2627, 0.9569, 1.0), vec4(0.9137, 0.5882, 0.9647, 1.0), vec4(0.6627, 0.4118, 0.7373, 1.0),
                            vec4(0.6627, 0.4118, 0.7373, 1.0), vec4(0.6627, 0.4118, 0.7373, 1.0), vec4(0.9137, 0.5882, 0.9647, 1.0), vec4(0.6627, 0.4118, 0.7373, 1.0), vec4(0),
                            vec4(0), vec4(0), vec4(0.6627, 0.4118, 0.7373, 1.0), vec4(0.6627, 0.4118, 0.7373, 1.0), vec4(0)
                        );

                        for (int i = 1; i <= FLOWER_AMOUNT; i++) {
                            if (NdotU > 0.5) {
                                ivec2 randomFlower1UV = ivec2((hash33(mod(floor(worldPos + atMidBlock / 64), vec3(200)) + i) * 0.5 + 0.5) * (FLOWER_SIZE + 1 - flower1Size.x)); // here the bigger component of flower1Size should be used, currently all flowers are symmetric
                                ivec2 randomFlower2UV = ivec2((hash33(mod(floor(worldPos + atMidBlock / 64), vec3(300)) + i) * 0.5 + 0.5) * (FLOWER_SIZE + 1 - flower2Size.x));
                                ivec2 randomFlower3UV = ivec2((hash33(mod(floor(worldPos + atMidBlock / 64), vec3(400)) + i) * 0.5 + 0.5) * (FLOWER_SIZE + 1 - flower3Size.x));
                                ivec2 randomFlower4UV = ivec2((hash33(mod(floor(worldPos + atMidBlock / 64), vec3(501)))     * 0.5 + 0.5) * (FLOWER_SIZE + 1 - flower4Size.x)); // Only 1 flower should max generate on a block for flower4/5
                                ivec2 randomFlower5UV = ivec2((hash33(mod(floor(worldPos + atMidBlock / 64), vec3(500)))     * 0.5 + 0.5) * (FLOWER_SIZE + 1 - flower5Size.x));

                                float randomFlower1Block  = step(hash13(mod(floor(worldPos + atMidBlock / 64), vec3(300)) + i), 0.15 * flowerNoiseRemove * flowerNoiseAdd * FLOWER_DENSITY);
                                float randomFlower2Block  = step(hash13(mod(floor(worldPos + atMidBlock / 64), vec3(200)) + i), 0.15 * flowerNoiseRemove * flowerNoiseAdd * FLOWER_DENSITY);
                                float randomFlower3Block  = step(hash13(mod(floor(worldPos + atMidBlock / 64), vec3(500)) + i), 0.40 * flowerNoiseRemove * flowerNoiseAdd * FLOWER_DENSITY);
                                float randomFlower45Block = step(hash13(mod(floor(worldPos + atMidBlock / 64), vec3(400)))   , 0.001 * flowerNoiseRemove * flowerNoiseAdd * FLOWER_DENSITY); // both purple flowers should appear only on the same block
                                float inverseRandomFlower45Block = randomFlower45Block * -1.0 + 1.0; // to remove other flower types on the block where the purple flower is on

                                ivec2 flower1RelCoord = flowerUV - randomFlower1UV;
                                ivec2 flower2RelCoord = flowerUV - randomFlower2UV;
                                ivec2 flower3RelCoord = flowerUV - randomFlower3UV;
                                ivec2 flower4RelCoord = flowerUV - randomFlower4UV;
                                ivec2 flower5RelCoord = flowerUV - randomFlower5UV;

                                if (all(greaterThanEqual(flower1RelCoord, ivec2(0))) && all(lessThan(flower1RelCoord, flower1Size))) { // if the position is inside the flower, do the flower
                                    vec4 flower1Col = flower1Pixels[flower1RelCoord.x + flower1Size.x * flower1RelCoord.y]; // this flower pixel's colour
                                    flower1Variable = flower1Col.a * randomFlower1Block * inverseRandomFlower45Block;
                                    springColor = mix(springColor, flower1Col.rgb, flower1Variable); // apply the flower colour
                                }
                                if (all(greaterThanEqual(flower2RelCoord, ivec2(0))) && all(lessThan(flower2RelCoord, flower2Size))) {
                                    vec4 flower2Col = flower2Pixels[flower2RelCoord.x + flower2Size.x * flower2RelCoord.y];
                                    flower2Variable = flower2Col.a * randomFlower2Block * inverseRandomFlower45Block;
                                    springColor = mix(springColor, flower2Col.rgb, flower2Variable);
                                }
                                if (all(greaterThanEqual(flower3RelCoord, ivec2(0))) && all(lessThan(flower3RelCoord, flower3Size))) {
                                    vec4 flower3Col = flower3Pixels[flower3RelCoord.x + flower3RelCoord.y];
                                    flower3Variable = flower3Col.a * randomFlower3Block * inverseRandomFlower45Block;
                                    springColor = mix(springColor, flower3Col.rgb, flower3Variable);
                                }
                                if (all(greaterThanEqual(flower4RelCoord, ivec2(0))) && all(lessThan(flower4RelCoord, flower4Size))) {
                                    vec4 flower4Col = flower4Pixels[flower4RelCoord.x + flower4Size.x * flower4RelCoord.y];
                                    flower4Variable = flower4Col.a * randomFlower45Block;
                                    flower4Emission = flower4Variable * (1.0 - step(flower4Col.r , 0.5));
                                    springColor = mix(springColor, flower4Col.rgb, flower4Variable);
                                }
                                if (all(greaterThanEqual(flower5RelCoord, ivec2(0))) && all(lessThan(flower5RelCoord, flower5Size))) {
                                    vec4 flower5Col = flower5Pixels[flower5RelCoord.x + flower5Size.x * flower5RelCoord.y];
                                    flower5Variable = flower5Col.a * randomFlower45Block;
                                    springColor = mix(springColor, flower5Col.rgb, flower5Variable);
                                }

                                #if EMISSIVE_FLOWERS > 0
                                    flowerEmissionMask = max(emission, (flower1Variable + flower2Variable + flower3Variable + flower4Emission + flower5Variable)); // Emission Mask
                                #endif
                            }
                        }
                        #if EMISSIVE_FLOWERS > 0 && defined EMISSIVE_SPRING_FLOWERS
                            #if EMISSIVE_FLOWERS_TYPE == 1
                                if (color.b < max(color.r, color.g * 1.1) * 0.95) emission = 0.0;
                            #elif EMISSIVE_FLOWERS_TYPE == 2
                                if (color.r < max(color.b * 1.15, color.g * 1.1) * 0.95) emission = 0.0;
                            #endif
                            emission = 2.0 * skyLightCheck * flowerEmissionMask;
                            #if EMISSIVE_FLOWERS == 2
                                emission = max(emission, mix(0.0, rainFactor + 1.0 * rainFactor, flowerEmissionMask));
                            #endif
                                emission *= EMISSIVE_FLOWERS_STRENGTH;
                        #endif
                    }
                #endif
            #endif
        }
    #endif

    #if SEASONS == 1
        vec3 summerToAutumn = mix(summerColor, autumnColor, summer);
        vec3 autumnToWinter = mix(summerToAutumn, winterColor, autumn);
        vec3 winterToSpring = mix(autumnToWinter, springColor, winter);
        vec3 springToSummer = mix(winterToSpring, summerColor, spring);

        #ifndef GBUFFERS_ENTITIES
            color.rgb = springToSummer;
        #endif

    #elif SEASONS == 2
        color.rgb = summerColor;

    #elif SEASONS == 3
        color.rgb = autumnColor;

    #elif SEASONS == 4
        color.rgb = winterColor;

    #elif SEASONS == 5
        color.rgb = springColor;
    #endif

    #ifdef GBUFFERS_ENTITIES
        color.rgb = oldColor;
    #endif
#endif