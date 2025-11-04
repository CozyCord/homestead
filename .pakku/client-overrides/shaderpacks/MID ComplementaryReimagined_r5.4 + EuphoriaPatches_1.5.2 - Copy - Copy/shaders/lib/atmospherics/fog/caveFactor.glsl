#ifndef INCLUDE_CAVE_FACTOR
    #define INCLUDE_CAVE_FACTOR

    float GetCaveFactor() {
        return clamp(1.0 - cameraPosition.y / oceanAltitude, 0.0, 1.0 - eyeBrightnessM);
    }

    vec3 caveFogColorRaw = vec3(CAVE_FOG_R, CAVE_FOG_G, CAVE_FOG_B) / 255 * CAVE_FOG_I;
    #if MINIMUM_LIGHT_MODE <= 1
        vec3 caveFogColor = caveFogColorRaw * 0.7;
    #elif MINIMUM_LIGHT_MODE == 2
        vec3 caveFogColor = caveFogColorRaw * (0.7 + 0.3 * vsBrightness); // Default
    #elif MINIMUM_LIGHT_MODE >= 3
        vec3 caveFogColor = caveFogColorRaw;
    #endif
#endif
