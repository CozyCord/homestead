vec3 GetNetherNoise(vec3 viewPos, float VdotU, float dither) {
    float visibility = clamp01(VdotU * 1.875 - 0.225);
    visibility *= 1.0 - VdotU * 0.75 - maxBlindnessDarkness;

    if (visibility > 0.0) {
        vec3 spots = vec3(0.0);

        float eyeAltitude1 = eyeAltitude * 0.005;
        float noiseHeightFactor = max(0.0, 1.5 - eyeAltitude1 / (eyeAltitude1 + 1.0));
        noiseHeightFactor *= noiseHeightFactor;
        float noiseHeight = noiseHeightFactor * 0.5;

        vec3 wpos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
             wpos.xz /= wpos.y;

        vec2 cameraPositionM = cameraPosition.xz * 0.0075;
             cameraPositionM.x += frameTimeCounter * 0.004;

        int sampleCount = 10;
        int sampleCountP = sampleCount + 5;
        float ditherM = dither + 5.0;
        float wind = fract(frameTimeCounter * 0.0125);
        for (int i = 0; i < sampleCount; i++) {
            float current = pow2((i + ditherM) / sampleCountP);

            vec2 planePos = wpos.xz * (0.8 + current) * noiseHeight;
            planePos = (planePos * 0.5 + cameraPositionM * 0.5) * 1.5;
            float noiseSpots = texture2D(noisetex, planePos * 0.5).g;
            vec3 noise = texture2D(noisetex, vec2(noiseSpots) + wind).g * netherColor * 2.5 - netherColor * 1.3;

            float currentM = 1.0 - current;
            spots += noise * currentM * 6.0;
        }

        #ifdef EPIC_THUNDERSTORM
            spots += 2.0 * isLightningActive();
        #endif

        return spots * visibility / sampleCount;
    }

    return vec3(0.0);
}