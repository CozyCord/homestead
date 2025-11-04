#if NETHER_PORTAL_VARIATION == 1
    lmCoordM = vec2(0.0);
    color = vec4(0.0);

    int sampleCount = 8;

    float multiplier = 0.4 / (-viewVector.z * sampleCount);
    vec2 interval = viewVector.xy * multiplier;
    vec2 coord = signMidCoordPos * 0.5 + 0.5;
    vec2 absMidCoordPos2 = absMidCoordPos * 2.0;
    vec2 midCoord = texCoord - absMidCoordPos * signMidCoordPos;
    vec2 minimumMidCoordPos = midCoord - absMidCoordPos;

    for (int i = 0; i < sampleCount; i++) {
        float portalStep = (i + dither) / sampleCount;
        coord += interval * portalStep;
        vec2 sampleCoord = fract(coord) * absMidCoordPos2 + minimumMidCoordPos;
        vec4 psample = texture2DLod(tex, sampleCoord, 0);

        float factor = 1.0 - portalStep;
        psample *= pow(factor, 0.1);

        emission = max(emission, psample.r);

        color += psample;
    }
    color /= sampleCount;

    color.rgb *= color.rgb * vec3(1.25, 1.0, 0.65);
    color.a = sqrt1(color.a) * 0.8;

    emission *= emission;
    emission *= emission;
    emission *= emission;    emission = clamp(emission * 120.0, 0.03, 1.2) * 8.0;


#else
    #ifdef GENERATED_NORMALS
        noGeneratedNormals = true;
    #endif
    vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos * 1000.0, 1.0)).xyz);
    wpos.xz /= wpos.y;

    vec2 wind = vec2(0.0, frameTimeCounter * 0.03);

    float noise = texture2D(noisetex, wpos.xz * 0.20 + wind * 0.2).r * 0.01;
            noise+= texture2D(noisetex, wpos.xz * 0.15 + wind * 0.15).r * 0.02;
            noise+= texture2D(noisetex, wpos.xz * 0.10 + wind * 0.10).r * 0.06;
            noise+= texture2D(noisetex, wpos.xz * 0.05 + wind * 0.05).r * 0.12;

    color.rgb = vec3(0.4431, 0.102, 0.6118) * noise * 3.0;
    color.rgb *= color.rgb * 24.0;

    float fogFactor = smoothstep(0.0, 1.0, 0.03 / -wpos.y);
    fogFactor += smoothstep(0.0, 1.0, 0.03 / wpos.y);

    vec3 fogColor = vec3(0.3373, 0.0431, 0.1176) * 25.0;
    color.rgb = mix(color.rgb, fogColor, fogFactor);
    color.a = 0.7;
#endif

#define PORTAL_REDUCE_CLOSEUP
#ifdef PORTAL_REDUCE_CLOSEUP
    color.a *= min1(lViewPos - 0.2);
#endif

#ifdef PORTAL_EDGE_EFFECT
    vec3 voxelPos = SceneToVoxel(playerPos);

    if (CheckInsideVoxelVolume(voxelPos)) {
        float portalOffset = 0.0625 * dither;
        vec3[6] portalOffsets = vec3[](
            vec3( portalOffset, 0, 0),
            vec3(-portalOffset, 0, 0),
            vec3( 0, portalOffset, 0),
            vec3( 0,-portalOffset, 0),
            vec3( 0, 0, portalOffset),
            vec3( 0, 0,-portalOffset)
        );

        float edge = 0.0;
        for (int i = 0; i < 6; i++) {
            uint voxel = texelFetch(voxel_sampler, ivec3(voxelPos + portalOffsets[i]), 0).r;
            if (voxel != uint(25)) {
                edge = 1.0; break;
            }
        }

        vec4 edgeColor = vec4(normalize(color.rgb), 1.0);
        edgeColor.b *= 0.8;
        color = mix(color, edgeColor, edge);
        emission = mix(emission, 5.0, edge);
    }
#endif
#if defined NETHER && defined BIOME_COLORED_NETHER_PORTALS
    float luminance = GetLuminance(color.rgb);
    color.rgb = normalize(netherColor) * luminance * 2.5;
#endif