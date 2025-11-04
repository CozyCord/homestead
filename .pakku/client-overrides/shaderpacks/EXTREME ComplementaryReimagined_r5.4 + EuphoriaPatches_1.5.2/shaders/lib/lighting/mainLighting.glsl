//Lighting Includes//
#include "/lib/colors/lightAndAmbientColors.glsl"
#include "/lib/lighting/ggx.glsl"

#if SHADOW_QUALITY > -1 && (defined OVERWORLD || defined END)
    #include "/lib/lighting/shadowSampling.glsl"
#endif

#if defined CLOUDS_REIMAGINED && defined CLOUD_SHADOWS
    #include "/lib/atmospherics/clouds/cloudCoord.glsl"
#endif

#ifdef LIGHT_COLOR_MULTS
    #include "/lib/colors/colorMultipliers.glsl"
#endif

#if defined MOON_PHASE_INF_LIGHT || defined MOON_PHASE_INF_REFLECTION
    #include "/lib/colors/moonPhaseInfluence.glsl"
#endif

#if COLORED_LIGHTING_INTERNAL > 0
    #include "/lib/misc/voxelization.glsl"
#endif

#if DRAGON_DEATH_EFFECT_INTERNAL > 0
    #define ENDCRYSTAL_SAMPLER_DEFINE
    uniform isampler2D endcrystal_sampler;
#endif

vec3 highlightColor = normalize(pow(lightColor, vec3(0.37))) * (0.3 + 1.5 * sunVisibility2) * (1.0 - 0.85 * rainFactor);

//Lighting//
void DoLighting(inout vec4 color, inout vec3 shadowMult, vec3 playerPos, vec3 viewPos, float lViewPos, vec3 geoNormal, vec3 normalM,
                vec3 worldGeoNormal, vec2 lightmap, bool noSmoothLighting, bool noDirectionalShading, bool noVanillaAO,
                bool centerShadowBias, int subsurfaceMode, float smoothnessG, float highlightMult, float emission, inout float purkinjeOverwrite) {
    #ifdef SPOOKY
        lightmap.x *= 0.85;
    #endif

    vec2 oldLightmap = lightmap.xy; 

    #ifdef DO_PIXELATION_EFFECTS
        vec2 pixelationOffset = ComputeTexelOffset(tex, texCoord);

        #ifdef PIXELATED_SHADOWS
            vec3 playerPosPixelated = TexelSnap(playerPos, pixelationOffset);
        #endif 
        #ifdef PIXELATED_BLOCKLIGHT
            lightmap = clamp(TexelSnap(lightmap, pixelationOffset), 0.0, 1.0);
            lViewPos = TexelSnap(lViewPos, pixelationOffset);
        #endif
    #endif

    float lightmapY2 = pow2(lightmap.y);
    float lightmapYM = smoothstep1(lightmap.y);
    float subsurfaceHighlight = 0.0;
    float ambientMult = 1.0;
    vec3 lightColorM = lightColor;
    vec3 ambientColorM = ambientColor;
    vec3 nViewPos = normalize(viewPos);

    #if defined LIGHT_COLOR_MULTS && !defined GBUFFERS_WATER // lightColorMult is defined early in gbuffers_water
        lightColorMult = GetLightColorMult();
    #endif
    vec2 lightningAdd = vec2(0);
    vec2 deathFlashAdd = vec2(0);
    vec3 lightningPos = vec3(0);
    #ifdef EPIC_THUNDERSTORM
        float lightningDistance = 550.0;
        lightningPos = getLightningPos(playerPos, lightningBoltPosition.xyz, false);
        float lightningFadeOut = max(1.0 - length(lightningPos) / lightningDistance, 0.0);
        float lightningFadeOutExp = exp((1.0 - lightningFadeOut) * -15.0);
        vec3 normalLightning = mat3(gbufferModelViewInverse) * mix(geoNormal, normalM, 0.25);
        float lightningNormalGradient = 0.12;
        if (subsurfaceMode == 1) lightningNormalGradient = mix(lightningNormalGradient, 0.45, lightningFadeOutExp);
        lightningAdd = (lightningFlashEffect(lightningPos, normalLightning, lightningDistance, lightningNormalGradient, subsurfaceMode) * 10.0 + mix(0.1, 0.0 , lightningFadeOut)) * isLightningActive();
        ambientColorM += lightningAdd.x;
    #endif
    #if DRAGON_DEATH_EFFECT_INTERNAL > 0
        vec3 dragonPosition = vec3(0, 80, 0) - cameraPosition;
        int isDying = texelFetch(endcrystal_sampler, ivec2(35, 0), 0).r;
        float dragonDeathFactor = 0.0001 * isDying;
        float deathFadeFactor = exp(-3.0 * (1.0 - dragonDeathFactor)) * dragonDeathFactor;

        if (dragonDeathFactor < 0.99) {
            vec3 normalMDeath = mat3(gbufferModelViewInverse) * mix(geoNormal, normalM, 0.5);
            vec3 endDragonCol = vec3(E_DRAGON_BEAM_R, E_DRAGON_BEAM_G, E_DRAGON_BEAM_B) / 255.0 * E_DRAGON_BEAM_I;
            vec3 deathFlashPos = getLightningPos(playerPos, dragonPosition, true);
            float effectDistance = 800.0;
            deathFlashAdd = lightningFlashEffect(deathFlashPos, normalMDeath, effectDistance, 0.0, subsurfaceMode) * 35.0 * deathFadeFactor;
            ambientColorM *= mix(1.0, 0.0, deathFadeFactor) + deathFlashAdd.x * saturateColors(sqrt(endDragonCol), 0.5);
            purkinjeOverwrite = 1.0;
        }
    #endif

    #if SSS_STRENGTH == 0
        subsurfaceMode = 0;
    #endif

    #ifdef OVERWORLD
        float skyLightShadowMult = pow2(pow2(lightmapY2));
    #else
        float skyLightShadowMult = 1.0;
    #endif

    #if defined SIDE_SHADOWING || defined DIRECTIONAL_SHADING
        float NdotN = dot(normalM, northVec);
        float absNdotN = abs(NdotN);
    #endif

    #if defined CUSTOM_PBR || defined GENERATED_NORMALS
        float NPdotU = abs(dot(geoNormal, upVec));
    #endif

    // Shadows
    #if defined OVERWORLD || defined END
        float NdotL = dot(normalM, lightVec);
        #ifdef GBUFFERS_WATER
            //NdotL = mix(NdotL, 1.0, 1.0 - color.a);
        #endif
        #ifdef CUSTOM_PBR
            float geoNdotL = dot(geoNormal, lightVec);
            float geoNdotLM = geoNdotL > 0.0 ? geoNdotL * 10.0 : geoNdotL;
            NdotL = min(geoNdotLM, NdotL);

            NdotL *= 1.0 - 0.7 * (1.0 - pow2(pow2(NdotUmax0))) * NPdotU;
        #endif
        #if SHADOW_QUALITY == -1 && defined GBUFFERS_TERRAIN || defined DREAM_TWEAKED_LIGHTING
            if (subsurfaceMode == 1) {
                NdotU = 1.0;
                NdotUmax0 = 1.0;
                NdotL = dot(upVec, lightVec);
            } else if (subsurfaceMode == 2) {
                highlightMult *= NdotL;
                NdotL = mix(NdotL, 1.0, 0.35);
            }

            subsurfaceMode = 0;
        #endif
        float NdotLmax0 = max0(NdotL);
        float NdotLM = NdotLmax0 * 0.9999;

        #ifdef GBUFFERS_TEXTURED
            NdotLM = 1.0;
        #else
            #ifdef GBUFFERS_TERRAIN
                if (subsurfaceMode != 0) {
                    #if defined CUSTOM_PBR && defined POM && POM_QUALITY >= 128 && POM_LIGHTING_MODE == 2
                        shadowMult *= max(pow2(pow2(dot(normalM, geoNormal))), sqrt2(NdotLmax0));
                    #endif
                    NdotLM = 1.0;
                }
                #ifdef SIDE_SHADOWING
                    else
                #endif
            #endif
            #ifdef SIDE_SHADOWING
                NdotLM = max0(NdotL + 0.4) * 0.714;

                #ifdef END
                    NdotLM = sqrt3(NdotLM);
                #endif
            #endif
        #endif

        #if ENTITY_SHADOWS_DEFINE == -1 && (defined GBUFFERS_ENTITIES || defined GBUFFERS_BLOCK)
            lightColorM = mix(lightColorM * 0.75, ambientColorM, 0.5 * pow2(pow2(1.0 - NdotLM)));
            NdotLM = NdotLM * 0.75 + 0.25;
        #endif

        if (shadowMult.r > 0.00001) {
            #if SHADOW_QUALITY > -1
                if (NdotLM > 0.0001) {
                    vec3 shadowMultBeforeLighting = shadowMult;
                    float shadowLength = min(shadowDistance, far) * 0.9166667 - lViewPos; //consistent08JJ622

                    if (shadowLength > 0.000001) {
                        #if SHADOW_SMOOTHING == 4 || SHADOW_QUALITY == 0
                            float offset = 0.00098;
                        #elif SHADOW_SMOOTHING == 3
                            float offset = 0.00075;
                        #elif SHADOW_SMOOTHING == 2
                            float offset = 0.0005;
                        #elif SHADOW_SMOOTHING == 1
                            float offset = 0.0003;
                        #endif

                        vec3 playerPosM = playerPos;

                        #if defined DO_PIXELATION_EFFECTS && defined PIXELATED_SHADOWS
                            playerPosM = playerPosPixelated;
                        #endif

                        #ifdef GBUFFERS_TEXTURED
                            vec3 centerPlayerPos = floor(playerPos + cameraPosition) - cameraPosition + 0.5;
                            playerPosM = mix(centerPlayerPos, playerPosM + vec3(0.0, 0.02, 0.0), lightmapYM);
                        #else
                            // Shadow bias without peter-panning
                            float distanceBias = pow(dot(playerPos, playerPos), 0.75);
                            distanceBias = 0.12 + 0.0008 * distanceBias;
                            vec3 bias = worldGeoNormal * distanceBias * (2.0 - 0.95 * NdotLmax0); // 0.95 fixes pink petals noon shadows

                            #ifdef GBUFFERS_TERRAIN
                                if (subsurfaceMode == 2) {
                                    bias *= vec3(0.0, 0.0, -0.75);
                                } else if (subsurfaceMode == 1) {
                                    bias = vec3(0.0);
                                    centerShadowBias = true;
                                }
                            #endif

                            // Fix light leaking in caves
                            if (lightmapYM < 0.999) {
                                #ifdef GBUFFERS_HAND
                                    playerPosM = mix(vec3(0.0), playerPosM, 0.2 + 0.8 * lightmapYM);
                                #else
                                    if (centerShadowBias) {
                                        #ifdef OVERWORLD
                                            vec3 centerPos = floor(playerPosM + cameraPosition) - cameraPosition + 0.5;
                                            playerPosM = mix(centerPos, playerPosM, 0.5 + 0.5 * lightmapYM);
                                        #endif
                                    } else {
                                        vec3 edgeFactor = 0.2 * (0.5 - fract(playerPosM + cameraPosition + worldGeoNormal * 0.01));

                                        #ifdef GBUFFERS_WATER
                                            bias *= 0.7;
                                            playerPosM += (1.0 - lightmapYM) * edgeFactor;
                                        #endif

                                        playerPosM += (1.0 - pow2(pow2(max(glColor.a, lightmapYM)))) * edgeFactor;
                                    }
                                #endif
                            }

                            playerPosM += bias;
                        #endif

                        vec3 shadowPos = GetShadowPos(playerPosM);

                        bool leaves = false;
                        #ifdef GBUFFERS_TERRAIN
                            if (subsurfaceMode == 0) {
                                #if defined PERPENDICULAR_TWEAKS && defined SIDE_SHADOWING
                                    offset *= 1.0 + pow2(absNdotN);
                                #endif
                            } else {
                                float VdotL = dot(nViewPos, lightVec);

                                float lightFactor = pow(max(VdotL, 0.0), 10.0) * float(isEyeInWater == 0);
                                if (subsurfaceMode == 1) {
                                    offset = 0.0010235 * lightmapYM + 0.0009765;
                                    shadowPos.z -= max(NdotL * 0.0001, 0.0) * lightmapYM;
                                    subsurfaceHighlight = lightFactor * 0.8;
                                    #ifndef SHADOW_FILTERING
                                        shadowPos.z -= 0.0002;
                                    #endif
                                } else if (subsurfaceMode == 2) {
                                    leaves = true;
                                    offset = 0.0005235 * lightmapYM + 0.0009765;
                                    shadowPos.z -= 0.000175 * lightmapYM;
                                    subsurfaceHighlight = lightFactor * 0.6;
                                    #ifndef SHADOW_FILTERING
                                        NdotLM = mix(NdotL, NdotLM, 0.5);
                                    #endif
                                } else {

                                }
                            }
                        #endif

                        shadowMult *= GetShadow(shadowPos, lViewPos, lightmap.y, offset, leaves);
                    }

                    float shadowSmooth = 16.0;
                    if (shadowLength < shadowSmooth) {
                        float shadowMixer = max0(shadowLength / shadowSmooth);

                        #ifdef GBUFFERS_TERRAIN
                            if (subsurfaceMode != 0) {
                                float shadowMixerM = pow2(shadowMixer);

                                if (subsurfaceMode == 1) skyLightShadowMult *= mix(0.6 + 0.3 * pow2(noonFactor), 1.0, shadowMixerM);
                                else skyLightShadowMult *= mix(NdotL * 0.4999 + 0.5, 1.0, shadowMixerM);

                                subsurfaceHighlight *= shadowMixer;
                            }
                        #endif

                        shadowMult = mix(vec3(skyLightShadowMult * shadowMultBeforeLighting), shadowMult, shadowMixer);
                    }
                }
            #else
                shadowMult *= skyLightShadowMult;
            #endif

            #ifdef CLOUD_SHADOWS
                vec3 worldPos = playerPos + cameraPosition;
                #if defined DO_PIXELATION_EFFECTS && defined PIXELATED_SHADOWS
                    worldPos = playerPosPixelated + cameraPosition;
                #endif
                float cloudShadowMult = 1.0;
                #ifdef CLOUDS_REIMAGINED
                    float EdotL = dot(eastVec, lightVec);
                    float EdotLM = tan(acos(EdotL));

                    #if SUN_ANGLE != 0
                        float NVdotLM = tan(acos(dot(northVec, lightVec)));
                    #endif

                    float distToCloudLayer1 = cloudAlt1i - worldPos.y;
                    vec3 cloudOffset1 = vec3(distToCloudLayer1 / EdotLM, 0.0, 0.0);
                    #if SUN_ANGLE != 0
                        cloudOffset1.z += distToCloudLayer1 / NVdotLM;
                    #endif
                    vec2 cloudPos1 = GetRoundedCloudCoord(ModifyTracePos(worldPos + cloudOffset1, cloudAlt1i).xz, CLOUD_SHADOW_ROUNDNESS);
                    float cloudSample = texture2D(gaux4, cloudPos1).b;
                    cloudSample *= clamp(distToCloudLayer1 * 0.1, 0.0, 1.0);

                    #ifdef DOUBLE_REIM_CLOUDS
                        float distToCloudLayer2 = cloudAlt2i - worldPos.y;
                        vec3 cloudOffset2 = vec3(distToCloudLayer2 / EdotLM, 0.0, 0.0);
                        #if SUN_ANGLE != 0
                            cloudOffset2.z += distToCloudLayer2 / NVdotLM;
                        #endif
                        vec2 cloudPos2 = GetRoundedCloudCoord(ModifyTracePos(worldPos + cloudOffset2, cloudAlt2i).xz, CLOUD_SHADOW_ROUNDNESS);
                        float cloudSample2 = texture2D(gaux4, cloudPos2).b;
                        cloudSample2 *= clamp(distToCloudLayer2 * 0.1, 0.0, 1.0);

                        cloudSample = 1.0 - (1.0 - cloudSample) * (1.0 - cloudSample2);
                    #endif

                    cloudSample *= sqrt3(1.0 - abs(EdotL));
                    cloudShadowMult = 1.0 - 0.85 * cloudSample;
                #else
                    vec2 csPos = worldPos.xz + worldPos.y * 0.25;
                    csPos.x += syncedTime;
                    csPos *= 0.000002 * CLOUD_UNBOUND_SIZE_MULT;

                    vec2 shadowoffsets[8] = vec2[8](
                        vec2( 0.0   , 1.0   ),
                        vec2( 0.7071, 0.7071),
                        vec2( 1.0   , 0.0   ),
                        vec2( 0.7071,-0.7071),
                        vec2( 0.0   ,-1.0   ),
                        vec2(-0.7071,-0.7071),
                        vec2(-1.0   , 0.0   ),
                        vec2(-0.7071, 0.7071));
                    float cloudSample = 0.0;
                    for (int i = 0; i < 8; i++) {
                        cloudSample += texture2D(noisetex, csPos + 0.005 * shadowoffsets[i]).b;
                    }

                    shadowMult *= smoothstep1(pow2(min1(cloudSample * 0.2)));
                    cloudShadowMult = smoothstep1(pow2(min1(cloudSample * 0.2)));
                #endif
                shadowMult *= mix(1.0, mix(cloudShadowMult, 1.0, NIGHT_CLOUD_UNBOUND_REMOVE * (1.0 - sunVisibility)), CLOUD_TRANSPARENCY);
            #endif

            shadowMult *= max(NdotLM * shadowTime, 0.0);
        }
        #ifdef GBUFFERS_WATER
            else { // Low Quality Water
                shadowMult = vec3(pow2(lightmapY2) * max(NdotLM * shadowTime, 0.0));
            }
        #endif
    #endif

    // Blocklight
    #if defined DIRECTIONAL_LIGHTMAP_NORMALS && !defined GBUFFERS_HAND
        float lightmapDir = oldLightmap.x;
        float lightmapDir1 = lightmapDir;
        vec3 dFdViewPosX = dFdx(viewPos);
        vec3 dFdViewPosY = dFdy(viewPos);
        vec2 dFdBlock = vec2(dFdx(oldLightmap.x), dFdy(oldLightmap.x));
        vec3 blockLightDir = dFdViewPosX * dFdBlock.x + dFdViewPosY * dFdBlock.y;
        if (length(dFdBlock) > 1e-6) {
            lightmapDir *= clamp01(dot(normalize(blockLightDir), normalM)) + 1.0;
            lightmapDir1 *= clamp01(dot(normalize(blockLightDir), normalM) + 1.0);
            lightmapDir = mix(lightmapDir, lightmapDir1, 0.55);
        }
        lightmap.x = mix(lightmap.x, lightmapDir, DIRECTIONAL_LIGHTMAP_NORMALS_BLOCK_STRENGTH * 0.01 * max0(100.0 - lViewPos)); // mix with 0.5 to match regular normal intensity, mix to the normal lightmap with lViewPos to mitigate floating point precision error, dir lightmap only when player near light sources, otherwise normal lightmap
    #endif

    #ifndef GBUFFERS_TEXTURED
        float lightmapXM;
        if (!noSmoothLighting) {
            float lightmapXMTransition = pow2(pow2(pow2(pow2(lightmap.x)))) * (10 - vsBrightness) * 2;
            float lightmapXMTransition2 = pow2(pow2(pow2(lightmap.x))) * (3.8 - vsBrightness) * 0.8;
            float lightmapXMTransition3 = pow2(pow2(lightmap.x)) * (3.8 - vsBrightness * 0.7);

            float lightmapXMSteep = max(0.0, pow2(pow2(lightmap.x * lightmap.x)) * (3.8 - 0.6 * vsBrightness) + (lightmapXMTransition + lightmapXMTransition2 + lightmapXMTransition3) * ((UPPER_LIGHTMAP_CURVE * 0.1 + 0.9) - 1.0) * mix(1.0, 10.0, float(int(max(0.0, UPPER_LIGHTMAP_CURVE - 0.01))))); // Fancy Math
            float lightmapXMCalm = (lightmap.x) * (1.8 + 0.6 * vsBrightness) * LOWER_LIGHTMAP_CURVE;
            lightmapXM = pow(lightmapXMSteep + lightmapXMCalm, 2.25);
        } else lightmapXM = pow2(lightmap.x) * 10.0 * pow(lightmap.x, pow2(UPPER_LIGHTMAP_CURVE)) * UPPER_LIGHTMAP_CURVE * (UPPER_LIGHTMAP_CURVE * 0.7 + 0.3);
    #else
        float lightmapXM;
        if (!noSmoothLighting) {
            float lightmapXMSteep = pow2(pow2(lightmap.x * lightmap.x))  * (3.8 - 0.6 * vsBrightness);
            float lightmapXMCalm = (lightmap.x) * (1.8 + 0.6 * vsBrightness);
            lightmapXM = pow(lightmapXMSteep + lightmapXMCalm, 2.25);
        } else lightmapXM = pow2(lightmap.x) * lightmap.x * 10.0;
    #endif

    #if BLOCKLIGHT_FLICKERING > 0 || defined SPOOKY
        float blocklightFlickerSpookyStrength = 0.0;
        #ifdef SPOOKY
            blocklightFlickerSpookyStrength = 0.7;
        #endif
        vec2 flickerNoiseBlock = texture2D(noisetex, vec2(frameTimeCounter * 0.06)).rb;
        lightmapXM *= mix(1.0, min1(max(flickerNoiseBlock.r, flickerNoiseBlock.g) * 1.7), max(pow2(BLOCKLIGHT_FLICKERING * 0.1), blocklightFlickerSpookyStrength));
    #endif

    #ifdef RANDOM_BLOCKLIGHT
        float RandR = texture2D(noisetex, 0.00016 * RANDOM_BLOCKLIGHT_SIZE * (playerPos.xz + cameraPosition.xz)).r * XLIGHT_R;
        float RandG = texture2D(noisetex, 0.00029 * RANDOM_BLOCKLIGHT_SIZE * (playerPos.xz + cameraPosition.xz)).r * XLIGHT_G;
        float RandB = texture2D(noisetex, 0.00034 * RANDOM_BLOCKLIGHT_SIZE * (playerPos.xz + cameraPosition.xz)).r * XLIGHT_B;
        blocklightCol = vec3(RandR, RandG, RandB) * 0.875;
    #endif

    vec3 blockLighting = lightmapXM * blocklightCol;

    #if COLORED_LIGHTING_INTERNAL > 0
        // Prepare
        #if defined GBUFFERS_HAND
            vec3 voxelPos = SceneToVoxel(vec3(0.0));
        #elif defined GBUFFERS_TEXTURED
            vec3 voxelPos = SceneToVoxel(playerPos);
        #else
            vec3 voxelPos = SceneToVoxel(playerPos);
            voxelPos = voxelPos + worldGeoNormal * 0.55; // should be close to 0.5 for ACL_CORNER_LEAK_FIX but 0.5 makes slabs flicker
        #endif

        vec3 specialLighting = vec3(0.0);
        vec4 lightVolume = vec4(0.0);
        if (CheckInsideVoxelVolume(voxelPos)) {
            vec3 voxelPosM = clamp01(voxelPos / vec3(voxelVolumeSize));
            lightVolume = GetLightVolume(voxelPosM);
            lightVolume = sqrt(lightVolume);
            specialLighting = lightVolume.rgb;
        }

        // Add extra articial light for blocks that request it
        lightmapXM = mix(lightmapXM, 10.0, lightVolume.a);
        specialLighting *= 1.0 + 50.0 * lightVolume.a;

        // Color Balance
        specialLighting = lightmapXM * 0.13 * DoLuminanceCorrection(specialLighting + blocklightCol * 0.05);

        // Add some extra non-contrasty detail
        AddSpecialLightDetail(specialLighting, color.rgb, emission);

        #if COLORED_LIGHT_SATURATION != 100
            specialLighting = mix(blockLighting, specialLighting, COLORED_LIGHT_SATURATION * 0.01);
        #endif

        // Serve with distance fade
        vec3 absPlayerPosM = abs(playerPos);
        #if COLORED_LIGHTING_INTERNAL <= 512
            absPlayerPosM.y *= 2.0;
        #elif COLORED_LIGHTING_INTERNAL == 768
            absPlayerPosM.y *= 3.0;
        #elif COLORED_LIGHTING_INTERNAL == 1024
            absPlayerPosM.y *= 4.0;
        #endif
        float maxPlayerPos = max(absPlayerPosM.x, max(absPlayerPosM.y, absPlayerPosM.z));
        float blocklightDecider = pow2(min1(maxPlayerPos / effectiveACLdistance * 2.0));
        //if (heldItemId != 40000 || heldItemId2 == 40000) // Hold spider eye to see vanilla lighting
        blockLighting = mix(specialLighting, blockLighting, blocklightDecider);
        //if (heldItemId2 == 40000 && heldItemId != 40000) blockLighting = lightVolume.rgb; // Hold spider eye to see light volume
    #endif

    #if HELD_LIGHTING_MODE >= 1
        float heldLight = heldBlockLightValue; float heldLight2 = heldBlockLightValue2;

        #ifndef IS_IRIS
            if (heldLight > 15.1) heldLight = 0.0;
            if (heldLight2 > 15.1) heldLight2 = 0.0;
        #endif

        #if COLORED_LIGHTING_INTERNAL == 0
            vec3 heldLightCol = blocklightCol; vec3 heldLightCol2 = blocklightCol;

            if (heldItemId == 45032) heldLight = 15; if (heldItemId2 == 45032) heldLight2 = 15; // Lava Bucket
        #else
            vec3 heldLightCol = GetSpecialBlocklightColor(heldItemId - 44000).rgb;
            vec3 heldLightCol2 = GetSpecialBlocklightColor(heldItemId2 - 44000).rgb;

            if (heldItemId == 45032) { heldLightCol = lavaSpecialLightColor.rgb; heldLight = 15; } // Lava Bucket
            if (heldItemId2 == 45032) { heldLightCol2 = lavaSpecialLightColor.rgb; heldLight2 = 15; }

            #if COLORED_LIGHT_SATURATION != 100
                heldLightCol = mix(blocklightCol, heldLightCol, COLORED_LIGHT_SATURATION * 0.01);
                heldLightCol2 = mix(blocklightCol, heldLightCol2, COLORED_LIGHT_SATURATION * 0.01);
            #endif
        #endif
        
        heldLight = clamp(heldLight, 0.0, 15.0);
        heldLight2 = clamp(heldLight2, 0.0, 15.0);

        vec3 playerPosLightM = playerPos + relativeEyePosition;
        playerPosLightM.y += 0.7;
        float lViewPosL = length(playerPosLightM) + 6.0;
        #if HELD_LIGHTING_MODE == 1
            lViewPosL *= 1.5;
        #endif

        #ifdef SPOOKY
            heldLight *= 1.3;
            heldLight2 *= 1.3;
            lViewPosL *= 1.6;
        #endif

        #ifdef DIRECTIONAL_LIGHTMAP_NORMALS
            vec3 cameraHeldLightPos = (gbufferModelView * vec4(-relativeEyePosition, 1.0)).xyz;
            vec3 worldGeoNormalView = (gbufferModelView * vec4(worldGeoNormal, 1.0)).xyz;

            cameraHeldLightPos.x += 0.66 * (float(heldLight > 0) - float(heldLight2 > 0)); // Held light position offset

            float dirHandLightmap = clamp01(dot(normalize(cameraHeldLightPos - viewPos), normalM)) + 1.0;
            float differenceDir = dirHandLightmap - (clamp01(dot(normalize(cameraHeldLightPos - viewPos), worldGeoNormalView)) + 1.0); // Difference between normal and geo normal

            dirHandLightmap = mix(1.0, dirHandLightmap, differenceDir * DIRECTIONAL_LIGHTMAP_NORMALS_HANDHELD_STRENGTH);
            heldLight *= dirHandLightmap;
            heldLight2 *= dirHandLightmap;
        #endif

        heldLight = pow2(pow2(heldLight * 0.47 / lViewPosL));
        heldLight2 = pow2(pow2(heldLight2 * 0.47 / lViewPosL));

        vec3 heldLighting = pow2(heldLight * DoLuminanceCorrection(heldLightCol + 0.001))
                          + pow2(heldLight2 * DoLuminanceCorrection(heldLightCol2 + 0.001));

        #if COLORED_LIGHTING_INTERNAL > 0
            AddSpecialLightDetail(heldLighting, color.rgb, emission);
        #endif

        #ifdef GBUFFERS_HAND
            blockLighting *= 0.5;
            heldLighting *= 2.0;
        #endif
        #if HAND_BLOCKLIGHT_FLICKERING > 0
            vec2 flickerNoiseHand = texture2D(noisetex, vec2(frameTimeCounter * 0.06)).rb;
            float flickerMix = mix(1.0, min1(max(flickerNoiseHand.r, flickerNoiseHand.g) * 1.7), pow2(HAND_BLOCKLIGHT_FLICKERING * 0.1));

            heldLighting *= flickerMix;
            #ifdef GBUFFERS_HAND
                emission *= mix(1.0, flickerMix, heldLight + heldLight2);
            #endif
        #endif
    #endif

    // Minimum Light
    float fadeMinLightDistance = 1.0;
    #if defined DISTANCE_MIN_LIGHT || defined SPOOKY
        float blockMinLightFadeDistance = 250;
        #ifdef SPOOKY
            blockMinLightFadeDistance = 80;
        #endif
        fadeMinLightDistance = max(1.0 - length(playerPos) / blockMinLightFadeDistance, 0.0);
        fadeMinLightDistance = exp((1.0 - fadeMinLightDistance) * -15.0) * (1.0 - nightVision) + nightVision;
    #endif
    #if !defined END && defined SPOOKY
        vec3 minLighting = vec3(0.045) * fadeMinLightDistance;
    #else
        #if !defined END && MINIMUM_LIGHT_MODE > 0
            #if MINIMUM_LIGHT_MODE == 1
                vec3 minLighting = vec3(0.0038) * fadeMinLightDistance;
            #elif MINIMUM_LIGHT_MODE == 2
                vec3 minLighting = vec3(0.005625 + vsBrightness * 0.043) * fadeMinLightDistance;
            #elif MINIMUM_LIGHT_MODE == 3
                vec3 minLighting = vec3(0.0625) * fadeMinLightDistance;
            #elif MINIMUM_LIGHT_MODE >= 4
                vec3 minLighting = vec3(0.07 * pow2(MINIMUM_LIGHT_MODE - 2.5)) * fadeMinLightDistance;
            #endif
            minLighting *= vec3(0.45, 0.475, 0.6);
            minLighting *= 1.0 - lightmapYM;
        #else
            vec3 minLighting = vec3(0.0);
        #endif
    #endif

    minLighting += nightVision * vec3(0.5, 0.5, 0.75);

    // Lighting Tweaks
    #ifdef OVERWORLD
        ambientMult = mix(lightmapYM, pow2(lightmapYM) * lightmapYM, rainFactor);

        #if SHADOW_QUALITY == -1
            float tweakFactor = 1.0 + 0.6 * (1.0 - pow2(pow2(pow2(noonFactor))));
            lightColorM /= tweakFactor;
            ambientMult *= mix(tweakFactor, 1.0, 0.5 * NdotUmax0);
        #endif

        #if AMBIENT_MULT != 100
            #define AMBIENT_MULT_M (AMBIENT_MULT - 100) * 0.006
            vec3 shadowMultP = shadowMult / (0.1 + 0.9 * sqrt2(max0(NdotLM)));
            ambientMult *= 1.0 + pow2(pow2(max0(1.0 - dot(shadowMultP, shadowMultP)))) * AMBIENT_MULT_M *
                           (0.5 + 0.2 * sunFactor + 0.8 * noonFactor) * (1.0 - rainFactor * 0.5);
        #endif

        if (isEyeInWater != 1) {
            float lxFactor = (sunVisibility2 * 0.4 + (0.6 - 0.6 * pow2(invNoonFactor))) * (6.0 - 5.0 * rainFactor);
            lxFactor *= lightmapY2 + lightmapY2 * 2.0 * pow2(shadowMult.r);
            lxFactor = max0(lxFactor - emission * 1000000.0);
            blockLighting *= pow(lightmapXM / 60.0 + 0.001, 0.09 * lxFactor);

            // Less light in the distance / more light closer to the camera during rain or night to simulate thicker fog
            float rainLF = 0.1 * rainFactor;
            float lightFogTweaks = 1.0 + max0(96.0 - lViewPos) * (0.002 * (1.0 - sunVisibility2) + 0.0104 * rainLF) - rainLF;
            ambientMult *= lightFogTweaks;
            lightColorM *= lightFogTweaks;
        }
    #endif

    #ifdef GBUFFERS_HAND
        ambientMult *= 1.3; // To improve held map visibility
    #endif

    // Directional Shading
    float directionShade = 1.0;
    #ifdef DIRECTIONAL_SHADING
        if (!noDirectionalShading) {
            float NdotE = dot(normalM, eastVec);
            float absNdotE = abs(NdotE);
            float absNdotE2 = pow2(absNdotE);

            #if !defined NETHER
                float NdotUM = 0.75 + NdotU * 0.25;
            #else
                float NdotUM = 0.75 + abs(NdotU + 0.5) * 0.16666;
            #endif
            float NdotNM = 1.0 + 0.075 * absNdotN;
            float NdotEM = 1.0 - 0.1 * absNdotE2;
            directionShade = NdotUM * NdotEM * NdotNM;

            #ifdef OVERWORLD
                lightColorM *= 1.0 + absNdotE2 * 0.75;
            #elif defined NETHER
                directionShade *= directionShade;
                ambientColorM += lavaLightColor * pow2(absNdotN * 0.5 + max0(-NdotU)) * (0.7 + 0.35 * vsBrightness);
            #endif

            #if defined CUSTOM_PBR || defined GENERATED_NORMALS
                float cpbrAmbFactor = NdotN * NPdotU;
                cpbrAmbFactor = 1.0 - 0.3 * cpbrAmbFactor;
                ambientColorM *= cpbrAmbFactor;
                minLighting *= cpbrAmbFactor;
            #endif

            #if defined OVERWORLD && defined PERPENDICULAR_TWEAKS && defined SIDE_SHADOWING
                // Fake bounced light
                ambientColorM = mix(ambientColorM, lightColorM, (0.05 + 0.03 * subsurfaceMode) * absNdotN * lightmapY2);

                // Get a bit more natural looking lighting during noon
                lightColorM *= 1.0 + max0(1.0 - subsurfaceMode) * pow(noonFactor, 20.0) * (pow2(absNdotN) - absNdotE2 * 0.1);
            #endif
        }
    #endif

    #ifdef DREAM_TWEAKED_LIGHTING
        ambientColorM = mix(ambientColorM, lightColorM, 0.25) * 1.5;
        lightColorM = lightColorM * 0.3;
    #endif

    // Scene Lighting Stuff
    vec3 sceneLighting = lightColorM * shadowMult + ambientColorM * ambientMult;
    float dotSceneLighting = dot(sceneLighting, sceneLighting);

    #if HELD_LIGHTING_MODE >= 1
        blockLighting = sqrt(pow2(blockLighting) + heldLighting);
    #endif

    blockLighting *= XLIGHT_I;

    #ifdef LIGHT_COLOR_MULTS
        sceneLighting *= lightColorMult;
    #endif
    #ifdef MOON_PHASE_INF_LIGHT
        sceneLighting *= moonPhaseInfluence;
    #endif

    // Vanilla Ambient Occlusion
    float vanillaAO = 1.0;
    #if VANILLAAO_I > 0
        vanillaAO = glColor.a;

        #if defined DO_PIXELATION_EFFECTS && defined PIXELATED_AO
            vanillaAO = TexelSnap(vanillaAO, pixelationOffset);
        #endif

        if (subsurfaceMode != 0) vanillaAO = mix(min1(vanillaAO * 1.15), 1.0, shadowMult.g);
        else if (!noVanillaAO) {
            #ifdef GBUFFERS_TERRAIN
                vanillaAO = min1(vanillaAO + 0.08);
                #ifdef OVERWORLD
                    vanillaAO = pow(
                        pow1_5(vanillaAO),
                        1.0 + dotSceneLighting * 0.02 + NdotUmax0 * (0.15 + 0.25 * pow2(noonFactor * pow2(lightmapY2)))
                    );
                #elif defined NETHER
                    vanillaAO = pow(
                        pow1_5(vanillaAO),
                        1.0 + NdotUmax0 * 0.5
                    );
                #else
                    vanillaAO = pow(
                        vanillaAO,
                        0.75 + NdotUmax0 * 0.25
                    );
                #endif
            #endif
            vanillaAO = vanillaAO * 0.9 + 0.1;

            #if VANILLAAO_I != 100
                #define VANILLAAO_IM VANILLAAO_I * 0.01
                vanillaAO = pow(vanillaAO, VANILLAAO_IM);
            #endif
        }
    #endif

    #ifdef EPIC_THUNDERSTORM
        vanillaAO += lightningAdd.y * 0.1 * (-vanillaAO + 1);
    #endif

    // Light Highlight
    vec3 lightHighlight = vec3(0.0);
    #ifdef LIGHT_HIGHLIGHT
        float specularHighlight = GGX(normalM, nViewPos, lightVec, NdotLmax0, smoothnessG);

        specularHighlight *= highlightMult;

        lightHighlight = isEyeInWater != 1 ? shadowMult : pow(shadowMult, vec3(0.25)) * 0.35;
        lightHighlight *= (subsurfaceHighlight + specularHighlight) * highlightColor;

        #ifdef LIGHT_COLOR_MULTS
            lightHighlight *= lightColorMult;
        #endif
        #ifdef MOON_PHASE_INF_REFLECTION
            lightHighlight *= pow2(moonPhaseInfluence);
        #endif
        #ifdef SPOOKY
            lightHighlight *= 0.3;
        #endif
    #endif

    // Mix Colors
    vec3 finalDiffuse = pow2(directionShade * vanillaAO) * (blockLighting + pow2(sceneLighting) + minLighting) + pow2(emission);
    finalDiffuse = sqrt(max(finalDiffuse, vec3(0.0))); // sqrt() for a bit more realistic light mix, max() to prevent NaNs

    // Apply Lighting
    color.rgb *= finalDiffuse;
    color.rgb += lightHighlight;
    color.rgb *= pow2(1.0 - darknessLightFactor);
}
