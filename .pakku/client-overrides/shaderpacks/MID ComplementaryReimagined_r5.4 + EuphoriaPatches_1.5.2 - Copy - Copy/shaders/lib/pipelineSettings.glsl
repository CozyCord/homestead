/*
const int colortex0Format = R11F_G11F_B10F; //main color
const int colortex1Format = RG32F;          //previous depth | Renko's Cut & Long Exposure in Green
const int colortex2Format = RGB16F;         //taa
const int colortex3Format = RGBA8;          //(cloud/water map on deferred/gbuffer) | translucentMult & bloom & final color
const int colortex4Format = R8;             //volumetric cloud linear depth & volumetric light factor
const int colortex5Format = RGBA8_SNORM;    //normalM & scene image for water reflections
const int colortex6Format = RGBA8;          //smoothnessD & materialMask & skyLightFactor & lmCoord.x at (0.0-0.5)
const int colortex7Format = RGBA16F;        //(cloud/water map on gbuffer) | temporal filter
#ifdef SS_BLOCKLIGHT
const int colortex8Format = RGB8;           //colored light
const int colortex9Format = RGB16F;         //colored light
#endif
*/

const bool colortex0Clear = true;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = true;
const bool colortex4Clear = false;
const bool colortex5Clear = false;
const bool colortex6Clear = true;
const bool colortex7Clear = false;
const bool colortex9Clear = false;

const bool shadowHardwareFiltering = true;
const float shadowDistanceRenderMul = 1.0;
#if END_CRYSTAL_VORTEX_INTERNAL == 0 && DRAGON_DEATH_EFFECT_INTERNAL == 0
    const float entityShadowDistanceMul = 0.125; // Iris feature
#else
    const float entityShadowDistanceMul = 1.0; // Iris feature
#endif

const float drynessHalflife = 300.0;
const float wetnessHalflife = 300.0;

const float ambientOcclusionLevel = 1.0;