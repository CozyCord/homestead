vec3 GetEnderStars(vec3 viewPos, float VdotU, float sizeMult, float starAmount) {
    vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos * 1000.0, 1.0)).xyz);
    vec3 starCoord = 0.65 * wpos / (abs(wpos.y) + length(wpos.xz));
    vec2 starCoord2 = starCoord.xz * 0.5 / (END_STAR_SIZE * sizeMult);
    starCoord2 += VdotU < 0.0 ? 100.0 : 0.0;

    const float starFactor = 1024.0;
    vec2 fractPart = fract(starCoord2 * starFactor);
    starCoord2 = floor(starCoord2 * starFactor) / starFactor;

    float star = GetStarNoise(starCoord2.xy) * GetStarNoise(starCoord2.xy+0.1) * GetStarNoise(starCoord2.xy+0.23);

    #if END_STAR_AMOUNT == 0
        star = max0(star - 0.77);
    #elif END_STAR_AMOUNT == 2
        star = max0((star + 0.15) * 0.9 - 0.7);
    #elif END_STAR_AMOUNT == 3
        star = max0((star + 0.4) * 0.8 - 0.7);
    #elif END_STAR_AMOUNT == 4
        star = max0((star + 0.5) * 0.8 - 0.7);
    #else
        star = max0(star - 0.7);
    #endif

    star *= getStarEdgeFactor(fractPart, STAR_ROUNDNESS_OW / 10.0, STAR_SOFTNESS_END);
    star = max0(star - starAmount * 0.1);
    star *= star;

    vec3 starColor = GetStarColor(starCoord2, 
                                  endSkyColor,
                                  vec3(STAR_COLOR_1_END_R, STAR_COLOR_1_END_G, STAR_COLOR_1_END_B),
                                  vec3(STAR_COLOR_2_END_R, STAR_COLOR_2_END_G, STAR_COLOR_2_END_B),
                                  vec3(STAR_COLOR_3_END_R, STAR_COLOR_3_END_G, STAR_COLOR_3_END_B),
                                  STAR_COLOR_VARIATION_END);

    vec3 enderStars = star * starColor * 3000.0 * END_STAR_BRIGHTNESS;

    float VdotUM1 = abs(VdotU);
    float VdotUM2 = pow2(1.0 - VdotUM1);
    enderStars *= VdotUM1 * VdotUM1 * (VdotUM2 + 0.015) + 0.015;

    #if END_TWINKLING_STARS > 0
        enderStars *= getTwinklingStars(starCoord2, float(END_TWINKLING_STARS));
    #endif

    return enderStars;
}