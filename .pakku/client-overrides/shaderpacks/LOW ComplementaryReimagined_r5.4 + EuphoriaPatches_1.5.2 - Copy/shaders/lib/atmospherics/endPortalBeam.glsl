#ifndef ENDCRYSTAL_SAMPLER_DEFINE
    uniform isampler2D endcrystal_sampler;
#endif

vec2 RayAABoxIntersection(vec2 start, vec2 dir, vec2 lower, vec2 upper) {
    dir += 0.000001 * vec2(equal(dir, vec2(0)));
    vec2 front = mix(upper, lower, 0.5 * sign(dir) + 0.5);
    vec2 back  = mix(lower, upper, 0.5 * sign(dir) + 0.5);
    vec2 front_iscts = (front - start) / dir;
    vec2 back_iscts  = (back  - start) / dir;
    float front_isct = max(front_iscts.x, front_iscts.y);
    float back_isct  = min(back_iscts.x , back_iscts.y );
    return front_isct < back_isct ? vec2(front_isct, back_isct) : vec2(-1);
}

vec4 GetEndPortalBeamNoise(vec3 relPos) {
    float colMixFactor = texture(noisetex, (relPos.xz + 0.1 * frameTimeCounter * vec2(-0.5, 1.5)) * 10.0 / noiseTextureResolution).r;
    float strengthMul = texture(noisetex, (relPos.xz + 0.1 * frameTimeCounter * vec2(1.5, -1.0)) * 5.0 / noiseTextureResolution + 0.2).r;
    colMixFactor = pow2(pow2(colMixFactor));
    strengthMul = pow2(strengthMul);
    vec3 col = mix(vec3(0.1137, 0.5569, 0.5255), vec3(0.3725, 0.8863, 0.749), colMixFactor);
    float strength
        = float(relPos.y > 0 && relPos.y < 2)
        * (2 - relPos.y)
        / (3 * relPos.y*relPos.y*relPos.y + 1)
        * (strengthMul + 0.5);
    return pow2(vec4(col, 1) * strength);
}

vec4 GetEndPortalBeam(vec3 start, vec3 dir) {
    if (texelFetch(endcrystal_sampler, ivec2(35, 4), 0).r == 1) {
        ivec4 rawPortalPos = ivec4(
            texelFetch(endcrystal_sampler, ivec2(35, 5), 0).r,
            texelFetch(endcrystal_sampler, ivec2(35, 6), 0).r,
            texelFetch(endcrystal_sampler, ivec2(35, 7), 0).r,
            texelFetch(endcrystal_sampler, ivec2(35, 8), 0).r
        );
        if (rawPortalPos.w > 0) {
            vec3 portalPos = floor(vec3(rawPortalPos.xyz) / max(1, rawPortalPos.w) + 0.5) + 0.5 - cameraPositionFract;
            vec2 iscts = RayAABoxIntersection(start.xz, dir.xz, portalPos.xz - 1.49, portalPos.xz + 1.49);
            int validIsctCount = 0;
            vec3[2] isctPositions;
            for (int k = 0; k < 2; k++) {
                if (iscts[k] > 0.0 && iscts[k] < 1.0) {
                    isctPositions[validIsctCount++] = start + iscts[k] * dir;
                }
            }
            vec4 col = vec4(0.0);
            for (int k = 0; k < validIsctCount; k++) {
                col += GetEndPortalBeamNoise(isctPositions[k] - portalPos);
            }

            vec3 absDir = abs(dir);
            float maxDir = max(absDir.x, max(absDir.y, absDir.z));
            float transition = 1.0 - pow3(min1(maxDir / mix(40, 10, maxBlindnessDarkness) * 2.0)); // fade to 0 when close to the range limit (32 blocks)

            col *= transition;

            return col;
        }
    }
    return vec4(0.0);
}