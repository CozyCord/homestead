#include "/lib/colors/skyColors.glsl"

vec2 GetStarCoord(vec3 viewPos, float sphereness) {
    vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos * 1000.0, 1.0)).xyz);
    vec3 starCoord = wpos / (wpos.y + length(wpos.xz) * sphereness);
    starCoord.x += 0.006 * syncedTime;
    return starCoord.xz;
}

vec3 GetStars(vec2 starCoord, float VdotU, float VdotS, float sizeMult, float starAmount) {
    if (VdotU < 0.0) return vec3(0.0);

    float spookyStarSize = 10000.0;
    #ifdef SPOOKY
        spookyStarSize = 0.5;
    #endif

    starCoord *= 0.2 / (min(STAR_SIZE, spookyStarSize) * sizeMult);
    const float starFactor = 1024.0;
    
    vec2 fractPart = fract(starCoord * starFactor);
    
    starCoord = floor(starCoord * starFactor) / starFactor;
    
    float star = GetStarNoise(starCoord.xy) * GetStarNoise(starCoord.xy+0.1) * GetStarNoise(starCoord.xy+0.23);

    #if MORE_STARS_OVERWORLD == 1 || defined SPOOKY
        star = max0((star - 0.5) * 0.55);
    #elif MORE_STARS_OVERWORLD == 2
        star = max0((star - 0.4) * 0.45);
    #elif NIGHT_STAR_AMOUNT == 2
        star = max0(star - 0.7);
    #else
        star = max0((star - 0.6) * 0.65);
    #endif

    star = max0(star - starAmount * 0.1);
    star *= getStarEdgeFactor(fractPart, STAR_ROUNDNESS_OW / 10.0, STAR_SOFTNESS_OW);
    star *= star;

    star *= min1(VdotU * 3.0) * max0(1.0 - pow(abs(VdotS) * 1.002, 100.0));
    #ifndef DAYLIGHT_STARS
        star *= pow2(pow2(invNoonFactor2)) * (1.0 - 0.5 * sunVisibility);
    #endif

    #if defined CLEAR_SKY_WHEN_RAINING || defined NO_RAIN_ABOVE_CLOUDS
        #ifndef CLEAR_SKY_WHEN_RAINING
            star *= mix(1.0, invRainFactor, heightRelativeToCloud);
        #else
            star *= mix(1.0, invRainFactor * 0.8 + 0.2, heightRelativeToCloud);
        #endif
    #else
        star *= invRainFactor;
    #endif

    float spookyStarMult = 0.0;
    #ifdef SPOOKY
        spookyStarMult = 2.0;
    #endif

    const float starBrightness = STAR_BRIGHTNESS > 3.0 ? ((STAR_BRIGHTNESS - 3.0) * 0.1) : STAR_BRIGHTNESS;

    vec3 starColor = GetStarColor(starCoord, 
                                vec3(0.38, 0.4, 0.5),
                                  vec3(STAR_COLOR_1_OW_R, STAR_COLOR_1_OW_G, STAR_COLOR_1_OW_B),
                                  vec3(STAR_COLOR_2_OW_R, STAR_COLOR_2_OW_G, STAR_COLOR_2_OW_B),
                                  vec3(STAR_COLOR_3_OW_R, STAR_COLOR_3_OW_G, STAR_COLOR_3_OW_B),
                                  STAR_COLOR_VARIATION_OW);

    vec3 stars = 40.0 * star * starColor * max(starBrightness, spookyStarMult);

    #if TWINKLING_STARS > 0 || defined SPOOKY
        stars *= getTwinklingStars(starCoord, float(TWINKLING_STARS));
    #endif

    return stars;
}