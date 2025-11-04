// Tweak to prevent the animation of lava causing brightness pulsing
vec3 avgColor = vec3(0.0);
ivec2 itexCoordC = ivec2(midCoord * atlasSize + 0.0001);
for (int x = -8; x < 8; x += 2) {
    for (int y = -8; y < 8; y += 2) {
        avgColor += texelFetch(tex, itexCoordC + ivec2(x, y), 0).rgb;
    }
}
color.rgb /= max(GetLuminance(avgColor) * 0.0390625, 0.001);
noDirectionalShading = true;
lmCoordM = vec2(0.0);
emission = GetLuminance(color.rgb) * 6.5;

vec3 worldPos = playerPos + cameraPosition;
vec2 lavaPos = (floor(worldPos.xz * 16.0) + worldPos.y * 32.0) * 0.000666;
vec2 wind = vec2(frameTimeCounter * 0.012, 0.0);

#ifdef NETHER
    float noiseSample = texture2D(noisetex, lavaPos + wind).g;
    noiseSample = noiseSample - 0.5;
    noiseSample *= 0.1;
    color.rgb = pow(color.rgb, vec3(1.0 + noiseSample));
#endif

vec3 previousLavaColor = color.rgb;

#ifdef SOUL_SAND_VALLEY_OVERHAUL_INTERNAL
    color.rgb = changeColorFunction(color.rgb, 3.0, colorSoul, inSoulValley);
    color.rgb = mix(color.rgb, (color.rgb - 0.5) * 1.35 + 0.5, inSoulValley); // increase contrast
#endif
#ifdef PURPLE_END_FIRE_INTERNAL
    color.rgb = changeColorFunction(color.rgb, 2.5, colorEndBreath * 1.4, 1.0);
    color.rgb = (color.rgb - 0.5) * 1.3 + 0.5;
#endif

vec3 lavaNoiseColor = color.rgb;

#if LAVA_VARIATION > 0
    if (mat == 10068 || mat == 10070) { // Lava
        #include "/lib/materials/specificMaterials/terrain/lavaNoise.glsl"
        color.rgb = lavaNoiseColor;
    }
#else
    maRecolor = vec3(clamp(pow2(pow2(pow2(smoothstep1(emission * 0.28)))), 0.12, 0.4) * 1.3) * vec3(1.0, vec2(0.7));
    if (LAVA_TEMPERATURE != 0.0) maRecolor += LAVA_TEMPERATURE * 0.5 - 0.2;
    lavaNoiseColor *= 1.3;
#endif

vec3 maxLavaColor = max(previousLavaColor, lavaNoiseColor);

#if RAIN_PUDDLES >= 1 || defined SPOOKY_RAIN_PUDDLE_OVERRIDE
    noPuddles = 1.0;
#endif

#include "/lib/materials/specificMaterials/terrain/lavaEdge.glsl"

emission *= LAVA_EMISSION;