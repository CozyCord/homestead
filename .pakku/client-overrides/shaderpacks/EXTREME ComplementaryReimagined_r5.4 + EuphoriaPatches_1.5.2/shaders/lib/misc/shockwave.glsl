// SDF from https://iquilezles.org/articles/distfunctions2d/
float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float getOffsetStrength(float animation, vec2 dir, float maxRadius) {
    #if SHOCKWAVE == 1
        float wave = sdCircle(vec2(dir / aspectRatio), animation * maxRadius);
    #elif SHOCKWAVE == 2
        float wave = sdBox(dir / aspectRatio, vec2(animation * maxRadius));
    #endif
    
    wave *= 1.0 - smoothstep(0.0, 0.2, abs(wave)); // Mask the ripple
    
    wave *= smoothstep(0.0, 0.2, animation); // Smooth intro
    wave *= 1.0 - smoothstep(0.5, 1.0, animation); // Smooth outro
    return wave * 0.05;
}

vec4 doShockwave(vec3 playerPos, vec2 texCoord){ // Based on https://editor.p5js.org/BarneyCodes/sketches/ELbA93Ugb by BarneyCodes
    vec2 centre = playerPos.xz + 0.4;
    vec2 dir = centre - texCoord;
    float animation = pow(isShockwave, 1.0 / 1.2);
    vec4 shockwaveColor = vec4(0);
    float maxRadius = 4;
    
    // Chromatic aberration
    float aberrationOffset = 0.05 * sin(animation * pi);
    float rWave = getOffsetStrength(animation + aberrationOffset, dir, maxRadius);
    float gWave = getOffsetStrength(animation, dir, maxRadius);
    float bWave = getOffsetStrength(animation - aberrationOffset, dir, maxRadius);
    
    dir = normalize(dir);

    float value = 1.0;
    #if defined GBUFFERS_TERRAIN || defined GBUFFERS_WATER
        float blockRes = absMidCoordPos.x * atlasSize.x;
        vec2 signMidCoordPosM = abs((floor((signMidCoordPos + 1.0) * blockRes) + 0.5) / blockRes - 1.0);
        value = 1.0 - max(signMidCoordPosM.x, signMidCoordPosM.y); // Prevent from distorting into a different atlas texture
    #endif

    float waveFactor = abs(max(gWave, max(rWave, bWave)) * 100.0);

    value *= step(0.01, animation);

    #if ANISOTROPIC_FILTER != 0 && defined GBUFFERS_TERRAIN
        float r = waveFactor > 0.0001 ? texture2D(tex, texCoord + dir * rWave * value).r : textureAF(tex, texCoord).r;
        float g = waveFactor > 0.0001 ? texture2D(tex, texCoord + dir * gWave * value).g : textureAF(tex, texCoord).g;
        float b = waveFactor > 0.0001 ? texture2D(tex, texCoord + dir * bWave * value).b : textureAF(tex, texCoord).b;
        float a = waveFactor > 0.0001 ? texture2D(tex, texCoord).a : textureAF(tex, texCoord).a; // Use the non AF method during the wave
    #else
        float r = texture2D(tex, texCoord + dir * rWave * value).r;
        float g = texture2D(tex, texCoord + dir * gWave * value).g;
        float b = texture2D(tex, texCoord + dir * bWave * value).b;
        float a = texture2D(tex, texCoord).a;
    #endif
    
    float shading = gWave * 15.0; // use gWave as it has no chromatic aberration

    shockwaveColor = vec4(r, g, b, a);
    shockwaveColor.rgb += shading * 1.5;
    // shockwaveColor += waveFactor > 0.0001 ? vec4(3,0,0,1) : vec4(0,0,0,0); // Debugging
    return shockwaveColor;
}