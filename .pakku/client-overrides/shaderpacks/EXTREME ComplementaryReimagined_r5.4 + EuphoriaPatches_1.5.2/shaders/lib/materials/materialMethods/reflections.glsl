#ifdef OVERWORLD
    #include "/lib/atmospherics/sky.glsl"
    #ifdef OVERWORLD_BEAMS
        #include "/lib/atmospherics/overworldBeams.glsl"
    #endif
    #ifdef END_PORTAL_BEAM_INTERNAL
        #include "/lib/atmospherics/endPortalBeam.glsl"
    #endif
#endif
#ifdef END
    #ifdef DEFERRED1
        #include "/lib/atmospherics/enderBeams.glsl"
    #endif
    #if END_CRYSTAL_VORTEX_INTERNAL > 0 || DRAGON_DEATH_EFFECT_INTERNAL > 0
        #include "/lib/atmospherics/endCrystalVortex.glsl"
    #endif
#endif

#if defined ATM_COLOR_MULTS || defined SPOOKY
    #include "/lib/colors/colorMultipliers.glsl"
#endif
#ifdef MOON_PHASE_INF_ATMOSPHERE
    #include "/lib/colors/moonPhaseInfluence.glsl"
#endif

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec3 refPos = vec3(0.0);

vec4 GetReflection(vec3 normalM, vec3 viewPos, vec3 nViewPos, vec3 playerPos, float lViewPos, float z0,
                   sampler2D depthtex, float dither, float skyLightFactor, float fresnel,
                   float smoothness, vec3 geoNormal, vec3 color, vec3 shadowMult, float highlightMult) {
    // Step 1: Prepare
    vec2 rEdge = vec2(0.6, 0.55);
    vec3 normalMR = normalM;

    #if defined GBUFFERS_WATER && WATER_STYLE == 1 && defined GENERATED_NORMALS
        normalMR = mix(geoNormal, normalM, 0.05);
    #endif

    vec3 nViewPosR = reflect(nViewPos, normalMR);
    float RVdotU = dot(normalize(nViewPosR), upVec);
    float RVdotS = dot(normalize(nViewPosR), sunVec);
    vec3 worldRefDir = 0.5 * far * (mat3(gbufferModelViewInverse) * nViewPosR);

    #if defined GBUFFERS_WATER && WATER_STYLE >= 2
        normalMR = mix(geoNormal, normalM, 0.8);
    #endif
    // End Step 1

    // Step 2: Calculate Terrain Reflection and Alpha
    vec4 reflection = vec4(0.0);
    #if defined DEFERRED1 || WATER_REFLECT_QUALITY >= 1
        #if (defined DEFERRED1 || WATER_REFLECT_QUALITY >= 2) && (!defined DH_WATER || DETAIL_QUALITY >= 3)
            // Method 1: Ray Marched Reflection //

            // Ray Marching
            vec3 start = viewPos + normalMR * (lViewPos * 0.025 * (1.0 - fresnel) + 0.05);
            #if defined GBUFFERS_WATER && WATER_STYLE >= 2
                vec3 vectorBase = reflect(nViewPos, normalize(normalMR)); // Not using nViewPosR because normalMR changed
            #else
                vec3 vectorBase = nViewPosR;
            #endif
            //vector = normalize(vector - 0.5 * (1.0 - smoothness) * (1.0 - fresnel) * normalMR); // reflection anisotropy test
            //vector = normalize(vector - 0.075 * dither * (1.0 - pow2(pow2(fresnel))) * normalMR);
            vectorBase *= 0.5;
            vec3 viewPosRTBase = viewPos + vectorBase;

            vec3 vector = vec3(0.0);
            vec3 viewPosRT = vec3(0.0);

            float dist = 0.0;
            vec3 rfragpos = vec3(0.0);

            // Normal pass
            {
                vector = vectorBase;
                viewPosRT = viewPosRTBase;

                vec3 tvector = vector;
                int sr = 0;
                for (int i = 0; i < 30; i++) {
                    refPos = nvec3(gbufferProjection * vec4(viewPosRT, 1.0)) * 0.5 + 0.5;
                    if (abs(refPos.x - 0.5) > rEdge.x || abs(refPos.y - 0.5) > rEdge.y) break;

                    rfragpos = vec3(refPos.xy, texture2D(depthtex, refPos.xy).r);
                    rfragpos = nvec3(gbufferProjectionInverse * vec4(rfragpos * 2.0 - 1.0, 1.0));
                    dist = length(start - rfragpos);

                    float err = length(viewPosRT - rfragpos);

                    if (err < length(vector) * 3.0) {
                        sr++;
                        if (sr >= 6) break;
                        tvector -= vector;
                        vector *= 0.1;
                    }
                    vector *= 2.0;
                    tvector += vector * (0.95 + 0.1 * dither);
                    viewPosRT = start + tvector;
                }
            }
            
            // DH pass on non-DH (if there is nothing blocking)
            #if defined DISTANT_HORIZONS && !defined DH_WATER && DETAIL_QUALITY >= 3
                if (refPos.z > 0.99997) {
                    vector = vectorBase;
                    viewPosRT = viewPosRTBase;
                    
                    vec3 tvector = vector;
                    int sr = 0;
                    for (int i = 0; i < 30; i++) {
                        refPos = nvec3(dhProjection * vec4(viewPosRT, 1.0)) * 0.5 + 0.5;
                        if (abs(refPos.x - 0.5) > rEdge.x || abs(refPos.y - 0.5) > rEdge.y) break;

                        rfragpos = vec3(refPos.xy, texture2D(dhDepthTex1, refPos.xy).r);
                        rfragpos = nvec3(dhProjectionInverse * vec4(rfragpos * 2.0 - 1.0, 1.0));
                        dist = length(start - rfragpos);

                        float err = length(viewPosRT - rfragpos);

                        if (err < length(vector) * 3.0) {
                            sr++;
                            if (sr >= 6) break;
                            tvector -= vector;
                            vector *= 0.1;
                        }
                        vector *= 2.0;
                        tvector += vector * (0.95 + 0.1 * dither);
                        viewPosRT = start + tvector;
                    }
                    
                    if (texture2D(depthtex, refPos.xy).r < 0.99997) refPos.z = 1.0;
                }
            #endif

            // Finalizing Terrain Reflection and Alpha 
            if (refPos.z < 0.99997) {
                vec2 absPos = abs(refPos.xy - 0.5);
                vec2 cdist = absPos / rEdge;
                float border = clamp(1.0 - pow(max(cdist.x, cdist.y), 50.0), 0.0, 1.0);
                reflection.a = border;

                float lViewPosRT = length(rfragpos);

                if (reflection.a > 0.001) {
                    vec2 edgeFactor = pow2(pow2(pow2(cdist)));
                    refPos.y += (dither - 0.5) * (0.05 * (edgeFactor.x + edgeFactor.y));

                    #ifdef DEFERRED1
                        float smoothnessDM = pow2(smoothness);
                        float lodFactor = 1.0 - exp(-0.125 * (1.0 - smoothnessDM) * dist);
                        float lod = log2(viewHeight / 8.0 * (1.0 - smoothnessDM) * lodFactor) * 0.45;
                        if (z0 <= 0.56) lod *= 2.22; // Using more lod to compensate for less roughness noise on held items
                        lod = max(lod - 1.0, 0.0);

                        reflection.rgb = texture2DLod(colortex0, refPos.xy, lod).rgb;
                    #else
                        reflection = texture2D(gaux2, refPos.xy);
                        reflection.rgb = pow2(reflection.rgb + 1.0);
                    #endif

                    float skyFade = 0.0;
                    DoFog(reflection.rgb, skyFade, lViewPosRT, ViewToPlayer(rfragpos.xyz), RVdotU, RVdotS, dither);

                    edgeFactor.x = pow2(edgeFactor.x);
                    edgeFactor = 1.0 - edgeFactor;
                    reflection.a *= pow(edgeFactor.x * edgeFactor.y, 2.0 + 3.0 * GetLuminance(reflection.rgb));
                }

                float posDif = lViewPosRT - lViewPos;
                reflection.a *= clamp(posDif + 3.0, 0.0, 1.0);
            }
            #if defined DEFERRED1 && defined TEMPORAL_FILTER
                else refPos.z = 1.0;
            #endif
            #if !defined DEFERRED1 && defined DISTANT_HORIZONS && DETAIL_QUALITY < 3
                else
            #endif
        #endif
        #if !defined DEFERRED1 && (WATER_REFLECT_QUALITY < 2 || (defined DISTANT_HORIZONS && DETAIL_QUALITY < 3))
        {   // Method 2: Mirorred Image Reflection //

            #if WATER_REFLECT_QUALITY < 2
                float verticalStretch = 0.013; // for potato quality reflections
            #else
                float verticalStretch = 0.0025; // for distant horizons reflections
            #endif

            vec4 clipPosR = gbufferProjection * vec4(nViewPosR + verticalStretch * viewPos, 1.0);
            vec3 screenPosR = clipPosR.xyz / clipPosR.w * 0.5 + 0.5;
            vec2 screenPosRM = abs(screenPosR.xy - 0.5);

            if (screenPosRM.x < rEdge.x && screenPosRM.y < rEdge.y) {
                vec2 edgeFactor = pow2(pow2(pow2(screenPosRM / rEdge)));
                screenPosR.y += (dither - 0.5) * (0.03 * (edgeFactor.x + edgeFactor.y) + 0.004);

                screenPosR.z = texture2D(depthtex1, screenPosR.xy).x;
                vec3 viewPosR = ScreenToView(screenPosR);
                if (lViewPos <= 2.0 + length(viewPosR)) {
                    reflection = texture2D(gaux2, screenPosR.xy);
                    reflection.rgb = pow2(reflection.rgb + 1.0);
                }

                edgeFactor.x = pow2(edgeFactor.x);
                edgeFactor = 1.0 - edgeFactor;
                reflection.a *= edgeFactor.x * edgeFactor.y;
            }

            reflection.a *= reflection.a;
            reflection.a *= clamp01((dot(nViewPos, nViewPosR) - 0.45) * 10.0); // Fixes perpendicular ref
        }
        #endif
    #endif
    // End Step 2

    // Step 3: Add Sky Reflection
    #if defined DEFERRED1 || WATER_REFLECT_QUALITY >= 1
        if (reflection.a < 1.0)
    #endif
    {
        #ifdef OVERWORLD
            #if defined DEFERRED1 || WATER_REFLECT_QUALITY >= 2
                vec3 skyReflection = GetSky(RVdotU, RVdotS, dither, true, true);
            #else
                vec3 skyReflection = GetLowQualitySky(RVdotU, RVdotS, dither, true, true);
            #endif

            #if defined ATM_COLOR_MULTS || defined SPOOKY
                skyReflection *= atmColorMult;
            #endif
            #ifdef MOON_PHASE_INF_ATMOSPHERE
                skyReflection *= moonPhaseInfluence;
            #endif

            #ifdef DEFERRED1
                skyReflection *= skyLightFactor;
                #ifdef OVERWORLD_BEAMS
                    skyReflection += DrawOverworldBeams(RVdotU, playerPos, viewPos).rgb * 0.01;
                #endif
            #else
                float specularHighlight = GGX(normalM, nViewPos, lightVec, max(dot(normalM, lightVec), 0.0), smoothness);
                skyReflection += specularHighlight * highlightColor * shadowMult * highlightMult * invRainFactor;
                
                #if WATER_REFLECT_QUALITY >= 1
                    #ifdef SKY_EFFECT_REFLECTION
                        float cloudLinearDepth = 1.0;
                        float skyFade = 1.0;
                        vec3 auroraBorealis = vec3(0.0);
                        vec3 nightNebula = vec3(0.0);

                        #if AURORA_STYLE > 0
                            auroraBorealis = GetAuroraBorealis(nViewPosR, RVdotU, dither);
                            skyReflection += auroraBorealis;
                        #endif
                        #ifdef NIGHT_NEBULA
                            nightNebula += GetNightNebula(nViewPosR, RVdotU, RVdotS);
                            skyReflection += nightNebula;
                        #endif
                        #ifdef OVERWORLD_BEAMS
                            skyReflection += (DrawOverworldBeams(RVdotU, playerPos, viewPos) * 0.4 + 0.6).rgb * 0.08;
                        #endif

                        vec2 starCoord = GetStarCoord(nViewPosR, 0.5);
                        #if STAR_BRIGHTNESS != 3
                            vec3 starColor = GetStars(starCoord, RVdotU, RVdotS, 1.0, 0.0);

                            #define ADD_STAR_LAYER_OW1 (STAR_LAYER_OW == 1 || STAR_LAYER_OW == 3)
                            #define ADD_STAR_LAYER_OW2 (STAR_LAYER_OW == 2 || STAR_LAYER_OW == 3)

                            #if ADD_STAR_LAYER_OW1
                                starColor = max(starColor, GetStars(starCoord, RVdotU, RVdotS, 0.66, 0.0));
                            #endif
                            
                            #if ADD_STAR_LAYER_OW2
                                starColor = max(starColor, GetStars(starCoord, RVdotU, RVdotS, 2.2, 0.45));
                            #endif

                            skyReflection += starColor;
                        #endif

                        #ifdef VL_CLOUDS_ACTIVE
                            vec3 worldNormalMR = normalize(mat3(gbufferModelViewInverse) * normalMR);
                            vec3 RCameraPos = cameraPosition + 2.0 * worldNormalMR * dot(playerPos, worldNormalMR);
                            vec3 RPlayerPos = normalize(mat3(gbufferModelViewInverse) * nViewPosR);
                            float RlViewPos = 100000.0;

                            vec4 clouds = GetClouds(cloudLinearDepth, skyFade, RCameraPos, RPlayerPos,
                                                    viewPos, RlViewPos, RVdotS, RVdotU, dither, auroraBorealis, nightNebula);

                            skyReflection = mix(skyReflection, clouds.rgb, clouds.a);
                        #endif
                    #endif

                    skyReflection = mix(color * 0.5, skyReflection, skyLightFactor);
                #else
                    skyReflection = mix(color, skyReflection, skyLightFactor * 0.5);
                #endif
            #endif
        #elif defined END
            #if defined DEFERRED1 && defined END_BEAMS
                vec3 skyReflection = (endSkyColor + 0.4 * DrawEnderBeams(RVdotU, playerPos)) * skyLightFactor;
            #else
                vec3 skyReflection = endSkyColor * shadowMult;
            #endif

            #if defined ATM_COLOR_MULTS || defined SPOOKY
                skyReflection *= atmColorMult;
            #endif
        #else
            vec3 skyReflection = vec3(0.0);
        #endif

        #if RETRO_LOOK == 1
            color.rgb *= vec3(RETRO_LOOK_R, RETRO_LOOK_G, RETRO_LOOK_B) * 0.5 * RETRO_LOOK_I;
        #elif RETRO_LOOK == 2
            color.rgb *= mix(vec3(1.0), vec3(RETRO_LOOK_R, RETRO_LOOK_G, RETRO_LOOK_B) * 0.5 * RETRO_LOOK_I, nightVision);
        #endif

        reflection.rgb = mix(skyReflection, reflection.rgb, reflection.a);
    }
    // End Step 3

    // Step 4: Add volumetrics to reflection
    {
        #if (defined DEFERRED1 || (WATER_REFLECT_QUALITY >= 2 && defined SKY_EFFECT_REFLECTION)) && (END_CRYSTAL_VORTEX_INTERNAL > 0 || DRAGON_DEATH_EFFECT_INTERNAL > 0)
            reflection.rgb += EndCrystalVortices(playerPos, worldRefDir, dither).rgb;
        #endif
        #if (defined DEFERRED1 || (WATER_REFLECT_QUALITY >= 2 && defined SKY_EFFECT_REFLECTION)) && defined END_PORTAL_BEAM_INTERNAL
            vec4 refPosPlayer = gbufferModelViewInverse * (gbufferProjectionInverse * vec4(refPos * 2.0 - 1.0, 1.0));
            refPosPlayer /= refPosPlayer.w;
            reflection.rgb += sqrt(GetEndPortalBeam(playerPos, refPosPlayer.xyz * reflection.a - playerPos).rgb);
        #endif
    }

    return reflection;
}