#ifndef ENDCRYSTAL_SAMPLER_DEFINE
    uniform isampler2D endcrystal_sampler;
#endif

const float healing_boundRadius = 6.0;
const float healing_ballRadius = 3.5;
const float healing_beamRadius = 0.6;
const float vortex_cylinderRadius = 3.0;
const float vortex_ballRadius = 5.0;
const float death_radius = 70.0;

#ifndef INCLUDE_ENDER_BEAMS
    #ifdef GBUFFERS_WATER
        float vlFactor = 0.5;
    #endif
    vec3 endDragonCol = vec3(E_DRAGON_BEAM_R, E_DRAGON_BEAM_G, E_DRAGON_BEAM_B) / 255.0 * E_DRAGON_BEAM_I;
    vec3 beamCol = normalize(endColorBeam * endColorBeam * endColorBeam) * (2.5 - 1.0 * vlFactor) * E_BEAM_I;
#endif

vec3 endDragonColM = sqrt(endDragonCol);
vec3 beamColM = sqrt(beamCol);

float GetBallRadius(float state) {
    return vortex_ballRadius * (1.0 + 4.0 * sqrt(1.0 - state));
}

float VortexWidth(float x, float ballRadius) {
    if (x > 0.5 * ballRadius) {
        float expScale = sqrt(0.75) * ballRadius - vortex_cylinderRadius;
        return vortex_cylinderRadius + expScale * exp( -sqrt(1.0/3.0) / expScale * (x - 0.5 * ballRadius));
    } else if (x > -ballRadius) {
        return sqrt(pow2(ballRadius) - pow2(x));
    }
    return 0.0;
}

vec4 SampleEndCrystalVortex(vec3 relPos, vec2 state, vec2 noiseOffset) {
    float thisBallRadius = GetBallRadius(state.s);

    float beamFactor = smoothstep(-thisBallRadius, thisBallRadius, relPos.y);
    float featureWidth = VortexWidth(relPos.y, thisBallRadius);
    vec2 horizontalScaledPos = featureWidth > 0.0 ? relPos.xz / featureWidth : vec2(2.0);
    float featureDist = length(horizontalScaledPos);
    if (length(relPos.xz) > featureWidth) {
        return vec4(0);
    }
    float beamStrength = 2.5 * beamFactor * (cos(featureDist * 3.1416) * 0.5 + 0.5) * pow2(max(0.0, 1 - pow2(0.005 / (0.9 * state.x + 0.1) / pow2(pow2(state.y)) * relPos.y))) * state.x;
    float spiralStrength = 200 * beamFactor * pow(featureDist, 7) * pow2(1.0 - featureDist) * pow2(max(0.0, 1 - pow2(0.02 / (0.6 * state.x * state.x + 0.4) / state.y * relPos.y)));
    float spiralAngle = (0.4 / vortex_cylinderRadius * relPos.y - 0.2 * pow2(min(0.0, -2.5 + relPos.y / thisBallRadius))) / (state.x + 0.2);
    vec2 spiralPos = mat2(cos(spiralAngle), -sin(spiralAngle), sin(spiralAngle), cos(spiralAngle)) * horizontalScaledPos;
    vec4 beamNoise = texture2D(noisetex, noiseOffset + 5.0 / noiseTextureResolution * horizontalScaledPos);
    vec4 beamNoise2 = texture2D(noisetex, noiseOffset + 5.0 / noiseTextureResolution * vec2(relPos.y * 0.02 + 2.7 * beamNoise.gb - 3.6 * frameTimeCounter * 0.5));
    vec4 spiralNoise = texture2D(noisetex, noiseOffset + 5.0 / noiseTextureResolution * spiralPos);
    vec4 spiralNoise2 = texture2D(noisetex, noiseOffset + 20.0 / noiseTextureResolution * spiralPos);
    return vec4(beamStrength * beamNoise.r * beamNoise2.r * endDragonColM + spiralStrength * pow2(spiralNoise.r) * (0.5 + spiralNoise2.r) * beamColM, beamStrength + spiralStrength) * 0.3;
}

vec4 SingleEndCrystalVortex(vec3 start, vec3 direction, vec3 center, vec2 state, float dither) {
    const float stepSize = 0.5;
    float invHorizontalDirLen = 1.0 / length(direction.xz);
    float thisBallRadius = GetBallRadius(state.x);
    float closestProgress = clamp(
        dot(center.xz - start.xz, direction.xz) * pow2(invHorizontalDirLen),
        -thisBallRadius * invHorizontalDirLen,
        1.0 + thisBallRadius * invHorizontalDirLen);
    vec3 closestPos = start + closestProgress * direction;
    float closestDist = length(closestPos.xz - center.xz);
    if (closestDist > thisBallRadius) {
        return vec4(0);
    }
    float startProgress = closestProgress - sqrt((thisBallRadius * thisBallRadius - closestDist * closestDist)) * invHorizontalDirLen;
    float endProgress = min(1.0, 2 * closestProgress - startProgress);
    startProgress = max(0.0, startProgress);
    vec2 noiseOffset = (center.xz + cameraPosition.xz + vec2(3.0, 1.6) * frameTimeCounter) * 0.005;
    vec4 colour = vec4(0);
    float dist = startProgress + dither * invHorizontalDirLen * stepSize;
    for (int k = 0; k < 100; k++) {
        if (dist > endProgress) break;
        colour += SampleEndCrystalVortex(start + dist * direction - center, state, noiseOffset);
        dist += invHorizontalDirLen * stepSize;
    }
    return colour * stepSize * smoothstep(0.0, 1.0, state.x);
}

float EndCrystalBeamWidth(float x, float len) {
    x = 0.5 * len - abs(x - 0.5 * len);
    if (x <= -healing_ballRadius) return 0.0;
    if (x < 0.5 * healing_ballRadius) return sqrt(pow2(healing_ballRadius) - pow2(x));
    float expScale = sqrt(0.75) * healing_ballRadius - healing_beamRadius;
    return healing_beamRadius + expScale * exp( -sqrt(1.0/3.0) / expScale * (x - 0.5 * healing_ballRadius));
}

vec4 SampleEndCrystalBeam(vec3 relPos, float len) {
    float beamWidth = EndCrystalBeamWidth(relPos.x, len);

    if (beamWidth > 0.0001) {
        float beamFactor = smoothstep(0.0, 2.0 * healing_ballRadius, 0.5 * len - abs(relPos.x - 0.5 * len));
        float noisyTime = frameTimeCounter + 0.4 * texture2D(noisetex, vec2(3.0 / noiseTextureResolution, frameTimeCounter / (0.45 * noiseTextureResolution))).r;

        relPos.yz /= beamWidth;
        float strength = 0.0;
        vec3 healBeamColor = vec3(0);
        for (int k = 0; k < 3; k++) {
            vec2 noiseCoords = vec2(0.2 / noiseTextureResolution * relPos.x, 0 + vec2(k, 6 * k) / noiseTextureResolution);
            vec4 zapNoise0 = texture2D(noisetex, noiseCoords + floor(8.0 * noisyTime) / noiseTextureResolution);
            vec4 zapNoise1 = texture2D(noisetex, 3.3 * noiseCoords + floor(8.0 * noisyTime));
            vec4 zapNoise2 = texture2D(noisetex, 6.8 * noiseCoords + (15.0 * frameTimeCounter));
            vec2 thisRelPos = relPos.yz + beamFactor / beamWidth * (6.0 * zapNoise0.rb + 1.6 * zapNoise1.rb + 1.2 * zapNoise2.rb - (3.0 + 0.8 + 0.6));
            vec4 sideNoise = texture2D(noisetex, (7.0 * thisRelPos.xy) / noiseTextureResolution);
            vec3 colorNoise = texture2D(noisetex, 4.0 * noiseCoords + floor(12.0 * noisyTime) / noiseTextureResolution).rgb;
            float centerDist0 = length(thisRelPos.xy);

            float centerDist = centerDist0 - 1.2;
            strength = max(strength, clamp( -centerDist, 0.0, 0.2) * pow2(max(0.0, 1.0 - pow2((centerDist0 - 1.0) * beamWidth * 0.5))) * mix(1.0, sideNoise.b, beamWidth / healing_ballRadius));
            healBeamColor = mix(clamp01(saturateColors(beamColM, 0.8) - sideNoise.rgb * 0.08), saturateColors(beamColM, 1.3) * 1.3, colorNoise);
        }
        return strength / beamWidth * vec4(healBeamColor * 0.5, 1.0) + 0.2 * beamFactor * exp(-6.0 * dot(relPos.yz, relPos.yz)) * vec4(endDragonColM * 2.2, 1.0);
    }
    return vec4(0.0);
}


vec4 EndCrystalBeam(vec3 start, vec3 direction, vec3 startPos, vec3 endPos, float dither) {
    vec3 startDiff = start - startPos;
    vec3 beamDirection = endPos - startPos;
    mat3 rotMat;
    rotMat[0] = normalize(beamDirection);
    rotMat[1] = normalize(cross(beamDirection, vec3(-2e-4, 1, 1e-5)));
    rotMat[2] = cross(rotMat[0], rotMat[1]);
    start *= rotMat;
    startPos *= rotMat;
    beamDirection *= rotMat;
    direction *= rotMat;
    const float stepSize = 0.5;
    float invHorizontalDirLen = 1.0 / length(direction.yz);
    float closestProgress = clamp(
        dot(startPos.yz - start.yz, direction.yz) * pow2(invHorizontalDirLen),
        -healing_boundRadius * invHorizontalDirLen,
        1.0 + healing_boundRadius * invHorizontalDirLen);
    vec3 closestPos = start + closestProgress * direction;
    float closestDist = length(closestPos.yz - startPos.yz);
    if (closestDist > healing_boundRadius) {
        return vec4(0);
    }
    float startProgress = closestProgress - sqrt((healing_boundRadius * healing_boundRadius - closestDist * closestDist)) * invHorizontalDirLen;
    float endProgress = min(1.0, 2 * closestProgress - startProgress);
    startProgress = max(0.0, startProgress);
    vec4 colour = vec4(0);
    float dist = startProgress + dither * invHorizontalDirLen * stepSize;
    for (int k = 0; k < 100; k++) {
        if (dist > endProgress) break;
        colour += SampleEndCrystalBeam(start + dist * direction - startPos, beamDirection.x);
        dist += invHorizontalDirLen * stepSize;
    }
    return 3.0 * log(length(colour) * stepSize + 1.0) * normalize(colour + 0.0000001);
}

float GetDragonDeathFactor(float dragonDeathTime) {
    return 0.02 * dragonDeathTime * exp(0.1 * dragonDeathTime);
}

vec4 SampleDeathBuildup(vec3 relPos, float dragonDeathTime) {
    float effectFactor = GetDragonDeathFactor(dragonDeathTime);
    float effectRadius = death_radius * effectFactor;
    float sizeNoiseFactor = 1.0 + 0.3 * texture2D(noisetex, vec2(0.2, dragonDeathTime * 5.0 / noiseTextureResolution)).r;
    float centerDist = length(relPos) / effectRadius;
    relPos *= sizeNoiseFactor;
    float angle = centerDist * 5.0 / log(dragonDeathTime * 0.6 + 1.0);
    mat2 rotMat = mat2(
        cos(angle), sin(angle),
       -sin(angle), cos(angle)
    );
    relPos.xz = rotMat * relPos.xz;
    vec2 val = pow(fract(hash23(floor(0.8 * relPos + 2.7 * sign(relPos) * exp(0.3 * dragonDeathTime)))), vec2(40.0 * pow2(centerDist))) * (1.0 - centerDist);
    return 0.1 * (vec4(beamColM, 1.0) * (val.x + 0.4 * exp(-8.0 * pow2(centerDist))) + vec4(endDragonColM, 1.0) * (val.y + 0.1 * exp(-3.0 * pow2(centerDist))));
}

vec4 DragonDeathAnimation(vec3 start, vec3 direction, vec3 dragonPos, float dragonDeathTime, float dragonDeathFactor, float dither) {
    float dirLen = length(direction);
    float closestProgress = dot(dragonPos - start, direction) / pow2(dirLen);
    vec4 colour = vec4(0);
    if (dragonDeathFactor >= 0.99) {
        float effectRadius = death_radius * GetDragonDeathFactor(dragonDeathTime);
        vec3 closestPos = start + closestProgress * direction;
        float closestDist = length(closestPos - dragonPos);
        if (closestDist >= effectRadius) return vec4(0.0);
        float stepSize = 0.5 / dirLen;
        float startProgress = closestProgress - sqrt(pow2(effectRadius) - pow2(closestDist)) / dirLen;
        float endProgress = min(1.0, 2.0 * closestProgress - startProgress);
        startProgress = max(0.0, startProgress);
        float dist = startProgress + stepSize * dither;
        for (int k = 0; k < 150; k++) {
            if (dist > endProgress) break;
            colour += SampleDeathBuildup(start + dist * direction - dragonPos, dragonDeathTime);
            dist += stepSize;
        }
        colour *= stepSize * dirLen;
    } else {
        vec3 closestPos = start + clamp(closestProgress, 0.0, 1.0) * direction;
        float closestDist = length(dragonPos - closestPos);
        colour = vec4(endDragonColM + 0.5 * beamColM, 1.0) * (0.4 * death_radius * (1.0 - exp(-dirLen/(4.0 * death_radius))) * exp(-10.0 * (1.0 - dragonDeathFactor) - closestDist * closestDist / (death_radius * death_radius)) * dragonDeathFactor);
    }
    return colour;
}

vec4 EndCrystalVortices(vec3 start, vec3 direction, float dither) {
    vec4 color = vec4(0);
    #if END_CRYSTAL_VORTEX_INTERNAL / 2 == 1 || DRAGON_DEATH_EFFECT_INTERNAL > 0
        ivec4 rawDragonPos = ivec4(
            texelFetch(endcrystal_sampler, ivec2(35, 5), 0).r,
            texelFetch(endcrystal_sampler, ivec2(35, 6), 0).r,
            texelFetch(endcrystal_sampler, ivec2(35, 7), 0).r,
            texelFetch(endcrystal_sampler, ivec2(35, 8), 0).r
        );
        vec3 dragonPos = rawDragonPos.xyz != ivec3(0) ? 0.0001 * rawDragonPos.xyz : vec3(0.5, 80.5, 0.5) - cameraPosition;
    #endif
    #if END_CRYSTAL_VORTEX_INTERNAL / 2 == 1
        vec3[15] healBeamEndPositions;
        int isTarget = 0;
        int healBeamCount = 15;
        for (int k = 0; k < 15; k++) {
            ivec4 rawPos = ivec4(
                texelFetch(endcrystal_sampler, ivec2(20 + k, 5), 0).r,
                texelFetch(endcrystal_sampler, ivec2(20 + k, 6), 0).r,
                texelFetch(endcrystal_sampler, ivec2(20 + k, 7), 0).r,
                texelFetch(endcrystal_sampler, ivec2(20 + k, 8), 0).r
            );
            if (rawPos.w == 0) {
                healBeamCount = k;
                break;
            }
            healBeamEndPositions[k] = vec3(rawPos.xyz) / rawPos.w;
            isTarget |= (length(healBeamEndPositions[k].xz + cameraPosition.xz - 0.5) < 4.5 || length(dragonPos - healBeamEndPositions[k]) < 5.0) ? 1 << k : 0;
        }
    #endif
    #if END_CRYSTAL_VORTEX_INTERNAL % 2 == 1
        for (int k = 0; k < 20; k++) {
            if (texelFetch(endcrystal_sampler, ivec2(k, 8), 0).r <= 0) continue;
            ivec4 rawPos = ivec4(
                texelFetch(endcrystal_sampler, ivec2(k, 5), 0).r,
                texelFetch(endcrystal_sampler, ivec2(k, 6), 0).r,
                texelFetch(endcrystal_sampler, ivec2(k, 7), 0).r,
                texelFetch(endcrystal_sampler, ivec2(k, 8), 0).r
            );
            if (rawPos.w <= 0) {
                continue;
            }
            int age = texelFetch(endcrystal_sampler, ivec2(k, 9), 0).r;
            vec3 pos = rawPos.xyz * 0.0001;
            #if END_CRYSTAL_VORTEX_INTERNAL / 2 == 1
                for (int i = 0; i < healBeamCount; i++) {
                    isTarget |= length(pos - healBeamEndPositions[i]) < 4.5 ? 1<<(i+15) : 0;
                }
            #endif
            vec2 state = vec2(clamp(rawPos.w / 15000.0, 0.0, 1.0), 1.00001 - exp(-0.0001 * age));
            color += pow2(SingleEndCrystalVortex(start, direction, pos, state, dither));
        }
    #endif
    #if END_CRYSTAL_VORTEX_INTERNAL / 2 == 1
        for (int k = 0; k < healBeamCount; k++) {
            for (int l = k+1; l < healBeamCount; l++) {
                if (
                    ((isTarget >> k & 1) == 0 ^^ (isTarget >> l & 1) == 0)
                    #if END_CRYSTAL_VORTEX_INTERNAL % 2 == 1
                        && ((isTarget >> k + 15 & 1) == 0 ^^ (isTarget >> l + 15 & 1) == 0)
                    #endif
                ) {
                    vec3 pos0 = healBeamEndPositions[k];
                    vec3 pos1 = healBeamEndPositions[l];
                    if (pos0.y > pos1.y) {
                        vec3 tmp = pos0;
                        pos0 = pos1;
                        pos1 = tmp;
                    }
                    color += pow2(EndCrystalBeam(start, direction, pos0, pos1, dither));
                }
            }
        }
    #endif
    #if DRAGON_DEATH_EFFECT_INTERNAL > 0
        int isDying = texelFetch(endcrystal_sampler, ivec2(35, 0), 0).r;
        float dragonDeathTime = 0.0001 * rawDragonPos.w;
        float dragonDeathFactor = 0.0001 * isDying;
        // dragonDeathTime = mod(frameTimeCounter, 22.0);
        // dragonDeathFactor = 2.2 - 0.1 * dragonDeathTime;
        // dragonPos = vec3(0, 80, 0) - cameraPosition;
        if (dragonDeathFactor > 0.001) {
            color += pow2(DragonDeathAnimation(start, direction, dragonPos, dragonDeathTime, dragonDeathFactor, dither));
        }
    #endif
    return sqrt(color) * (1.0 - maxBlindnessDarkness);
}