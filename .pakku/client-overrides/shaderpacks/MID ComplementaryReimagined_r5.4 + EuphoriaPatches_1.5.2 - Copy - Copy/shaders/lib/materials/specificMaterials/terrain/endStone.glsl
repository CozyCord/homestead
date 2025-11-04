#ifdef OBSIDIAN_ENDSTONE
    #ifdef GBUFFERS_TERRAIN
        vec3 worldPos = cameraPosition + playerPos;
        color.rgb *= mix(vec3(0.1686, 0.1216, 0.302), vec3(0.0, 0.0, 0.0), float(hash33(floor(mod(worldPos, vec3(100.0)) * 16 + 0.01) * 16)) * 0.5);
        if (color.r < 0.18) color.rgb *= vec3(0.3843, 0.3294, 0.5176);
        if (color.r < 0.05) color.rgb *= 0.2;
    #else
        color.rgb *= vec3(0.0941, 0.0314, 0.149);
    #endif

    materialMask = OSIEBCA; // Intense Fresnel

    float factor = max0(0.3 - abs(color.r - 0.3)) * 1.5;

    smoothnessG = factor;
    highlightMult = 2.0 + min1(smoothnessG * 2.0) * 1.5;
    smoothnessG = min1(smoothnessG);

    smoothnessD = min1(factor + 0.07);

    #ifdef COATED_TEXTURES
        noiseFactor = 1.25;
    #endif
#else
    float factor = pow2(pow2(color.r));

    smoothnessG = factor * 0.65;
    smoothnessD = smoothnessG * 0.6;

    #ifdef COATED_TEXTURES
        noiseFactor = 0.66;
    #endif
#endif