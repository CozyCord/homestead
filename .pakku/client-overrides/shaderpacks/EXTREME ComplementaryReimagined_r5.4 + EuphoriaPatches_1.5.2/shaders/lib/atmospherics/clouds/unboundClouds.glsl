#if CLOUD_UNBOUND_SIZE_MULT != 100
    #define CLOUD_UNBOUND_SIZE_MULT_M CLOUD_UNBOUND_SIZE_MULT * 0.01
#endif
const float cloudStretchModified = max(0.25, float(CLOUD_STRETCH) * 1.9 - 0.9);
#if CLOUD_QUALITY_INTERNAL == 1 || !defined DEFERRED1
    const float cloudStretchRaw = 11.0 * cloudStretchModified;
#elif CLOUD_QUALITY_INTERNAL == 2
    const float cloudStretchRaw = 16.0 * cloudStretchModified;
#elif CLOUD_QUALITY_INTERNAL == 3
    const float cloudStretchRaw = 18.0 * cloudStretchModified;
#elif CLOUD_QUALITY_INTERNAL == 4
    const float cloudStretchRaw = 20.0 * cloudStretchModified;
#endif
#if CLOUD_UNBOUND_SIZE_MULT <= 100
    const float cloudStretch = cloudStretchRaw;
#else
    const float cloudStretch = cloudStretchRaw / float(CLOUD_UNBOUND_SIZE_MULT_M);
#endif

const float cloudHeightShader = cloudStretch * 2.0;

float GetCloudNoise(vec3 tracePos, int cloudAltitude, float lTracePosXZ, float cloudPlayerPosY) {
    vec3 tracePosM = tracePos.xyz * 0.00016;
    float wind = 0.0006;
    #if INCREASED_RAIN_STRENGTH == 1
        wind *= mix(1.0, 2.5, rainFactor);
    #elif INCREASED_RAIN_STRENGTH == 2
        if (rainFactor > 0.01) wind *= 2.5;
    #endif
    float noise = 0.0;
    float currentPersist = 1.0;
    float total = 0.0;

    #if CLOUD_SPEED_MULT == 100
        #define CLOUD_SPEED_MULT_M CLOUD_SPEED_MULT * 0.01
        wind *= syncedTime;
    #else
        #define CLOUD_SPEED_MULT_M CLOUD_SPEED_MULT * 0.01
        wind *= frameTimeCounter * CLOUD_SPEED_MULT_M;
    #endif
    #if CLOUD_UNBOUND_SIZE_MULT != 100
        tracePosM *= CLOUD_UNBOUND_SIZE_MULT_M;
        wind *= CLOUD_UNBOUND_SIZE_MULT_M;
    #endif

    #if CLOUD_QUALITY_INTERNAL == 1
        int sampleCount = 2;
        float persistance = 0.6;
        float noiseMult = 0.95;
        tracePosM *= 0.5; wind *= 0.5;
    #elif CLOUD_QUALITY_INTERNAL == 2 || !defined DEFERRED1
        int sampleCount = 4;
        float persistance = 0.5;
        float noiseMult = 1.07;
    #elif CLOUD_QUALITY_INTERNAL == 3
        int sampleCount = 4;
        float persistance = 0.5;
        float noiseMult = 1.0;
    #elif CLOUD_QUALITY_INTERNAL == 4
        int sampleCount = 5;
        float persistance = 0.5;
        float noiseMult = 1.05;
    #endif

    #ifndef DEFERRED1
        noiseMult *= 1.2;
    #endif

    #if CLOUD_DIRECTION == 2
        tracePosM.xz = tracePosM.zx;
    #endif

    for (int i = 0; i < sampleCount; i++) {
        #if CLOUD_QUALITY_INTERNAL >= 2
            noise += Noise3D(tracePosM + vec3(wind, 0.0, 0.0)) * currentPersist;
        #else
            noise += texture2D(noisetex, tracePosM.xz + vec2(wind, 0.0)).b * currentPersist;
        #endif
        total += currentPersist;

        tracePosM *= 3.0;
        wind *= 0.5;
        currentPersist *= persistance;
    }
    noise = pow2(noise / total);

    #ifndef DISTANT_HORIZONS
        #define CLOUD_BASE_ADD 0.65
        #define CLOUD_FAR_ADD 0.01
        #define CLOUD_ABOVE_ADD 0.1
    #else
        #define CLOUD_BASE_ADD 0.9
        #define CLOUD_FAR_ADD -0.005
        #define CLOUD_ABOVE_ADD 0.03
    #endif

    float spookyCloudAdd = 0.0;
    #ifdef SPOOKY
        spookyCloudAdd = 0.5;
    #endif
    float nightCloudRemove = NIGHT_CLOUD_UNBOUND_REMOVE * (1.0 - sunVisibility) * -0.65 + 1.0; // mapped to 1 to 0.65 range

    float seasonCloudAdd = 0.0;
    #if SEASONS > 0
        float autumnOnlyForests = 1.0;
        #ifdef AUTUMN_CONDITION
            autumnOnlyForests = inForest;
        #endif
        float autumnWinterTime = autumnTime + winterTime;
        #if SNOW_CONDITION != 2
            autumnWinterTime *= mix(inSnowy + autumnOnlyForests, inSnowy, winterTime); // make only appear in cold biomes during winter
        #endif
        #if SNOW_CONDITION == 0
            autumnWinterTime *= mix(rainFactor + autumnOnlyForests, rainFactor, winterTime); // make only appear in rain during winter
        #endif
        seasonCloudAdd += mix(0.0, 0.35, autumnWinterTime);
        seasonCloudAdd += mix(0.0, -0.2, summerTime);
    #endif

    noiseMult *= CLOUD_BASE_ADD
                + CLOUD_FAR_ADD * sqrt(lTracePosXZ + 10.0) // more/less clouds far away
                + CLOUD_ABOVE_ADD * clamp01(-cloudPlayerPosY / cloudHeightShader) // more clouds when camera is above them
                + CLOUD_UNBOUND_RAIN_ADD * rainFactor + spookyCloudAdd + seasonCloudAdd; // more clouds during rain, Spooky and seasons
    noise *= noiseMult * CLOUD_UNBOUND_AMOUNT * nightCloudRemove;

    float threshold = clamp(abs(cloudAltitude - tracePos.y) / cloudStretch, 0.001, 0.999);
    threshold = pow2(pow2(pow2(threshold)));
    return noise - (threshold * 0.2 + 0.25);
}

vec4 GetVolumetricClouds(int cloudAltitude, float distanceThreshold, inout float cloudLinearDepth, float skyFade, float skyMult0, vec3 cameraPos, vec3 nPlayerPos, float lViewPosM, float VdotS, float VdotU, float dither) {
    vec4 volumetricClouds = vec4(0.0);

    float higherPlaneAltitude = cloudAltitude + cloudStretch;
    float lowerPlaneAltitude  = cloudAltitude - cloudStretch;

    float lowerPlaneDistance  = (lowerPlaneAltitude - cameraPos.y) / nPlayerPos.y;
    float higherPlaneDistance = (higherPlaneAltitude - cameraPos.y) / nPlayerPos.y;
    float minPlaneDistance = min(lowerPlaneDistance, higherPlaneDistance);
          minPlaneDistance = max(minPlaneDistance, 0.0);
    float maxPlaneDistance = max(lowerPlaneDistance, higherPlaneDistance);
    if (maxPlaneDistance < 0.0) return vec4(0.0);
    float planeDistanceDif = maxPlaneDistance - minPlaneDistance;

    #ifndef DEFERRED1
        float stepMult = 32.0;
    #elif CLOUD_QUALITY_INTERNAL == 1
        float stepMult = 16.0;
    #elif CLOUD_QUALITY_INTERNAL == 2
        float stepMult = 24.0;
    #elif CLOUD_QUALITY_INTERNAL == 3
        float stepMult = 16.0;
    #elif CLOUD_QUALITY_INTERNAL == 4
        float stepMult = 24.0;
    #endif

    #if CLOUD_UNBOUND_SIZE_MULT > 100
        stepMult = stepMult / sqrt(float(CLOUD_UNBOUND_SIZE_MULT_M));
    #endif

    int sampleCount = int(planeDistanceDif / stepMult + dither + 1);
    vec3 traceAdd = nPlayerPos * stepMult;
    vec3 tracePos = cameraPos + minPlaneDistance * nPlayerPos;
    tracePos += traceAdd * dither;
    tracePos.y -= traceAdd.y;

    float firstHitPos = 0.0;
    float VdotSM1 = max0(sunVisibility > 0.5 ? VdotS : - VdotS);
    float VdotSM1M = VdotSM1 * invRainFactor;
    float VdotSM2 = pow2(VdotSM1) * abs(sunVisibility - 0.5) * 2.0;
    float VdotSM3 = VdotSM2 * (2.5 + rainFactor) + 1.5 * rainFactor;

    #ifdef FIX_AMD_REFLECTION_CRASH
        sampleCount = min(sampleCount, 30); //BFARC
    #endif

    for (int i = 0; i < sampleCount; i++) {
        tracePos += traceAdd;

        if (abs(tracePos.y - cloudAltitude) > cloudStretch) break;

        vec3 cloudPlayerPos = tracePos - cameraPos;
        float lTracePos = length(cloudPlayerPos);
        float lTracePosXZ = length(cloudPlayerPos.xz);
        float cloudMult = 1.0;
        if (lTracePosXZ > distanceThreshold) break;
        if (lTracePos > lViewPosM) {
            if (skyFade < 0.7) continue;
            else cloudMult = skyMult0;
        }

        float cloudNoise = GetCloudNoise(tracePos, cloudAltitude, lTracePosXZ, cloudPlayerPos.y);

        if (cloudNoise > 0.00001) {
            #if defined CLOUD_CLOSED_AREA_CHECK && SHADOW_QUALITY > -1
                float shadowLength = min(shadowDistance, far) * 0.9166667; //consistent08JJ622
                if (shadowLength < lTracePos)
                if (GetShadowOnCloud(tracePos, cameraPos, cloudAltitude, lowerPlaneAltitude, higherPlaneAltitude)) {
                    if (eyeBrightness.y != 240) continue;
                }
            #endif

            if (firstHitPos < 1.0) {
                firstHitPos = lTracePos;
                #if CLOUD_QUALITY_INTERNAL == 1 && defined DEFERRED1
                    tracePos.y += 4.0 * (texture2D(noisetex, tracePos.xz * 0.001).r - 0.5);
                #endif
            }

            float opacityFactor = min1(cloudNoise * 8.0) * CLOUD_TRANSPARENCY;

            float cloudShading = 1.0 - (higherPlaneAltitude - tracePos.y) / cloudHeightShader;
            cloudShading *= 1.0 + 0.75 * VdotSM3 * (1.0 - opacityFactor);

            vec3 colorSample = cloudAmbientColor * (0.7 + 0.3 * cloudShading) + cloudLightColor * cloudShading;
            //vec3 colorSample = 2.5 * cloudLightColor * pow2(cloudShading); // <-- Used this to take the Unbound logo
            #ifdef EPIC_THUNDERSTORM
                vec3 lightningPos = getLightningPos(tracePos - cameraPosition, lightningBoltPosition.xyz, false);
                vec2 lightningAdd = lightningFlashEffect(lightningPos, vec3(1.0), 550.0, 0.0, 0) * isLightningActive() * 10.0;
                colorSample += lightningAdd.y;
            #endif
            vec3 cloudSkyColor = GetSky(VdotU, VdotS, dither, true, false);
            #ifdef ATM_COLOR_MULTS
                cloudSkyColor *= sqrtAtmColorMult; // C72380KD - Reduced atmColorMult impact on some things
            #endif
            float distanceRatio = (distanceThreshold - lTracePosXZ) / distanceThreshold;
            float cloudDistanceFactor = clamp(distanceRatio, 0.0, 0.8) * 1.25;
            #ifndef DISTANT_HORIZONS
                float cloudFogFactor = cloudDistanceFactor;
            #else
                float cloudFogFactor = clamp(distanceRatio, 0.0, 1.0);
            #endif
            float skyMult1 = 1.0 - 0.2 * (1.0 - skyFade) * max(sunVisibility2, nightFactor);
            float skyMult2 = 1.0 - 0.33333 * skyFade;
            colorSample = mix(cloudSkyColor, colorSample * skyMult1, cloudFogFactor * skyMult2 * 0.72);
            colorSample *= pow2(1.0 - maxBlindnessDarkness);

            volumetricClouds.rgb = mix(volumetricClouds.rgb, colorSample, 1.0 - min1(volumetricClouds.a));
            volumetricClouds.a += opacityFactor * pow(cloudDistanceFactor, 0.5 + 10.0 * pow(abs(VdotSM1M), 90.0)) * cloudMult;

            if (volumetricClouds.a > 0.9) {
                volumetricClouds.a = 1.0;
                break;
            }
        }
    }

    if (volumetricClouds.a > 0.5) cloudLinearDepth = sqrt(firstHitPos / renderDistance);

    return volumetricClouds;
}