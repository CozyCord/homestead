vec2 getOverlayNoise(float sideIntensity, bool noLightCheck, bool decreaseWithDepth, float meltingRadius, int pixelSize, vec3 worldPos, float noiseTransparency, float removeIntensity) {
    float overlayNoiseVariable;
    float topCheck = abs(clamp01(dot(normal, upVec))); // normal check for top surfaces
    if (topCheck > 0.99) {
        overlayNoiseVariable = 0.0;
        overlayNoiseVariable += topCheck;
    } else {
        overlayNoiseVariable = sideIntensity;
    }

    //noise
    int noiseSize = 0;
    // #if SNOW_SIZE > 0 || MOSS_SIZE > 0 || SAND_SIZE > 0
    noiseSize = pixelSize;
    // #else
    //     noiseSize = pixelTexSize.x + 1; // only commented out for nostalgia :p
    // #endif
    float noise = float(hash33(floor(mod(worldPos, vec3(100.0)) * noiseSize + 0.03) * noiseSize)) * 0.25; // pixel-locked procedural noise

    //make patches of terrain that don't have noise
    float removeNoise1 = 1.0 - Noise3D(worldPos * 0.0005) * removeIntensity * 1.2;
    float removeNoise2 = 1.0 - Noise3D(worldPos * 0.005) * removeIntensity;
    float removeNoise3 = Noise3D(worldPos * 0.02) * removeIntensity;
    float removeNoise = clamp01(2.0 * removeNoise1 + 0.70 * removeNoise2 + 0.2 * removeNoise3);
    overlayNoiseVariable *= removeNoise;

    // light check so noise is not in caves (near light sources)
    overlayNoiseVariable = clamp01(overlayNoiseVariable); // to prevent stuff breaking, like the fucking bamboo sapling!!!!
    if (!noLightCheck) {
        overlayNoiseVariable *= (1.0 - pow(lmCoord.x, 1.0 / meltingRadius * 2.5) * 4.3) * pow(lmCoord.y, 14.0); // first part to turn off at light sources, second part to turn off if under blocks
    }
    float depthTransparency = 1.0;
    if (decreaseWithDepth) {
        depthTransparency = 10.0 / abs(min(worldPos.y, 0.001)) - 0.3 + clamp(removeNoise * 1.3, 0.0, 0.1); // increase transparency beginning at y=0 at increasing with decreasing y level
    }
    overlayNoiseVariable = clamp(overlayNoiseVariable, 0.0, min1(log(noiseTransparency + 3.0) - 0.6) * depthTransparency); // to prevent artifacts near light sources

    vec2 result = vec2(overlayNoiseVariable, noise);
    return result;
}