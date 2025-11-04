#ifdef MULTICOLORED_BLOCKLIGHT
    #define OLD_SSBL_ERROR
#endif

#ifdef MC_ANISOTROPIC_FILTERING
    #define OPTIFINE_AF_ERROR
#endif

#if COLORED_LIGHTING > 0 && !defined IS_IRIS
    #define OPTIFINE_ACL_ERROR
#endif

#if COLORED_LIGHTING > 0 && defined MC_OS_MAC
    #define APPLE_ACL_ERROR
#endif

#if defined END_PORTAL_BEAM && !defined IS_IRIS
    #define OPTIFINE_PORTAL_BEAM_ERROR
#endif

#if defined END_PORTAL_BEAM && defined MC_OS_MAC
    #define APPLE_PORTAL_BEAM_ERROR
#endif

#if defined DRAGON_DEATH_EFFECT && !defined IS_IRIS
    #define OPTIFINE_DRAGON_DEATH_ERROR
#endif

#if defined DRAGON_DEATH_EFFECT && defined MC_OS_MAC
    #define APPLE_DRAGON_DEATH_ERROR
#endif

#if END_CRYSTAL_VORTEX > 0 && !defined IS_IRIS
    #define OPTIFINE_END_CRYSTAL_ERROR
#endif

#if END_CRYSTAL_VORTEX > 0 && defined MC_OS_MAC
    #define APPLE_END_CRYSTAL_ERROR
#endif

#if COLORED_LIGHTING_INTERNAL > 0
    #define COORDINATES_ACL_ERROR
    #define SHADOWDISTANCE_ACL_ERROR
#endif

#ifdef OLD_SSBL_ERROR
    #include "/lib/textRendering/old_ssbl_error.glsl"
#elif defined OPTIFINE_AF_ERROR
    #include "/lib/textRendering/error_optifine_af.glsl"
#elif defined APPLE_ACL_ERROR
    #include "/lib/textRendering/error_apple_acl.glsl"
#elif defined OPTIFINE_ACL_ERROR
    #include "/lib/textRendering/error_optifine_acl.glsl"
#elif defined APPLE_PORTAL_BEAM_ERROR
    #include "/lib/textRendering/error_apple_portal_beam.glsl"
#elif defined OPTIFINE_PORTAL_BEAM_ERROR
    #include "/lib/textRendering/error_optifine_portal_beam.glsl"
#elif defined APPLE_DRAGON_DEATH_ERROR
    #include "/lib/textRendering/error_apple_dragon_death.glsl"
#elif defined OPTIFINE_DRAGON_DEATH_ERROR
    #include "/lib/textRendering/error_optifine_dragon_death.glsl"
#elif defined APPLE_END_CRYSTAL_ERROR
    #include "/lib/textRendering/error_apple_end_crystal.glsl"
#elif defined OPTIFINE_END_CRYSTAL_ERROR
    #include "/lib/textRendering/error_optifine_end_crystal.glsl"
#else
    #if defined COORDINATES_ACL_ERROR && !defined ACL_DISTANCE_WARNING_OVERRIDE
        ivec2 absCameraPositionIntXZ = abs(cameraPositionInt.xz);
        if (max(absCameraPositionIntXZ.x, absCameraPositionIntXZ.y) > 8388550) {
            #include "/lib/textRendering/error_coordinates_acl.glsl"
        }
    #endif
    #ifdef SHADOWDISTANCE_ACL_ERROR
        if (COLORED_LIGHTING_INTERNAL > shadowDistance*2) {
            #include "/lib/textRendering/error_shadowdistance_acl.glsl"
        }
    #endif
#endif