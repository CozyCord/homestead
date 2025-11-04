smoothnessG = (1.0 - pow(color.g, 64.0) * 0.3) * 0.4;
highlightMult = 2.0;

smoothnessD = smoothnessG;

#ifdef GBUFFERS_TERRAIN
    DoBrightBlockTweaks(color.rgb, 0.5, shadowMult, highlightMult);
#endif

#if RAIN_PUDDLES >= 1 || defined SPOOKY_RAIN_PUDDLE_OVERRIDE
    noPuddles = 1.0;
#endif

#ifdef SSS_SNOW_ICE
    subsurfaceMode = 3, noSmoothLighting = true, noDirectionalShading = true;
#endif