#include "/lib/materials/specificMaterials/terrain/obsidian.glsl"

highlightMult *= 0.5;

float factor0 = sqrt2(max0(color.b - color.g * 6.0));
float factor1 = pow2(color.b);
emission = 1.35 + pow2(pow2(factor1)) * 7.5;
emission *= factor0;
color.r *= 1.15;

maRecolor = vec3(factor0 * min(max0(factor1 * 0.7 - 0.1) * 1.3, 0.5));

#if defined NETHER && defined BIOME_COLORED_NETHER_PORTALS
    color.rgb = mix(color.rgb, vec3(GetLuminance(color.rgb)), 0.88);
    color.rgb = normalize(netherColor) * luminance * 2.0;
#endif
overlayNoiseIntensity = 0.65;
overlayNoiseEmission = 0.6;