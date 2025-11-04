vec3 GetBedrockNoise(vec3 viewPos, float VdotU, float dither) {
    float eyeAltitude1 = eyeAltitude * 0.005;
    float visibility = clamp01(-VdotU * 1.875 - 0.225) * (1.0 - maxBlindnessDarkness);
    visibility *= 1.0 + VdotU * 0.75;
   
   // Calculate the distance from the player to the bedrockLevel
    float distanceToBedrock = max(0.0, bedrockLevel - eyeAltitude);

    // Calculate the noiseHeightFactor based on the distance, starting large and decreasing as you approach bedrockLevel
    float maxNoiseHeight = 2.0;  // Maximum noise height when far from bedrockLevel
    float noiseHeight = maxNoiseHeight / (1.0 + exp((distanceToBedrock - 90.0) / 120.0));

    visibility *= -eyeAltitude1 * 3.0 + (bedrockLevel / 66.6) + 2.0;
    if (visibility > 0.0) {
        vec3 spots = vec3(0.0);

        vec3 wpos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
             wpos /= (abs(wpos.y) + length(wpos.xz) * 0.5);

        vec2 cameraPositionM = cameraPosition.xz * 0.0075;
             cameraPositionM.x += frameTimeCounter * 0.004;

        float VdotUM = 1.0 - VdotU * VdotU;

        vec2 starCoord = noiseHeight * wpos.xz * 0.2 + cameraPositionM * 0.1;
        float starFactor = 1024.0;
        starCoord = floor(starCoord * starFactor) / starFactor;
        float star = 1.0;
        star *= GetStarNoise(starCoord.xy);
        star *= GetStarNoise(starCoord.xy+0.1);
        star *= GetStarNoise(starCoord.xy+0.23);
        star -= 0.4;
        star *= 6.0;
        star = max0(star);
        star *= star;

        vec3 stars = star * vec3(0.1765, 0.1569, 0.1804);
        stars *= (VdotUM + 0.3); // remove stars below the player

        float wind = fract((frameTimeCounter) * 0.0125);

        int sampleCount = 1;
        int sampleCountP = sampleCount + 5;
        float ditherM = dither + 5.0;

        for (int i = 0; i < sampleCount; i++) {
            float current = pow2((i + ditherM) / sampleCountP);

            vec2 planePos = wpos.xz * (0.5 + current) * noiseHeight;
            planePos = (planePos * 0.5 + cameraPositionM * 0.5) * 20;
            float noiseSpots = texture2D(noisetex, floor(planePos) * 0.1).g;
            vec3 noise = texture2D(noisetex, vec2(noiseSpots) + wind * 0.3).b * vec3(0.3);

            float currentM = 1.0 - current;
            spots += noise * currentM * 6.0;
        }
        #ifdef OVERWORLD
            spots = (spots - 0.5) * 1.5 + 0.5; // contrast
        #else
            spots = (spots - 0.5) * 3.5 + 0.5; // contrast
        #endif
        spots += stars;
        return spots * visibility / sampleCount * clamp01(noiseHeight) + clamp01(noiseHeight) -1.0;
    }
    return vec3(0.0);
}