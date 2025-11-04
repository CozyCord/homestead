/////////////////////////////////////
// Complementary Shaders by EminGT //
// With Euphoria Patches by SpacEagle17 //
/////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

noperspective in vec2 texCoord;

//Pipeline Constants//
#include "/lib/pipelineSettings.glsl"

//Common Variables//

//Common Functions//
#if IMAGE_SHARPENING > 0
    vec2 viewD = 1.0 / vec2(viewWidth, viewHeight);

    vec2 sharpenOffsets[4] = vec2[4](
        vec2( viewD.x,  0.0),
        vec2( 0.0,  viewD.x),
        vec2(-viewD.x,  0.0),
        vec2( 0.0, -viewD.x)
    );

    void SharpenImage(inout vec3 color, vec2 texCoordM) {
        #ifdef TAA
            float sharpenMult = IMAGE_SHARPENING;
        #else
            float sharpenMult = IMAGE_SHARPENING * 0.5;
        #endif
        float mult = 0.0125 * sharpenMult;
        color *= 1.0 + 0.05 * sharpenMult;

        for (int i = 0; i < 4; i++) {
            color -= texture2D(colortex3, texCoordM + sharpenOffsets[i]).rgb * mult;
        }
    }
#endif

float retroNoise (vec2 noise) {
    return fract(sin(dot(noise.xy,vec2(10.998,98.233)))*12433.14159265359);
}

vec2 curveDisplay(vec2 texCoord, float curvatureAmount, int screenRoundness) {
    texCoord = texCoord * 2.0 - 1.0;
    vec2 offset = abs(texCoord.yx) * curvatureAmount * 0.5;

    if (screenRoundness == 1) {
        offset *= offset;
    } else if (screenRoundness == 2) {
        offset *= pow2(offset);
    } else if (screenRoundness == 3) {
        offset *= pow3(offset);
    }
    texCoord += texCoord * offset;
    return texCoord * 0.5 + 0.5;
}

vec2 border(vec2 texCoord) {
    const float borderAmount = 2.0 + BORDER_AMOUNT * 0.1;
    texCoord = texCoord * borderAmount - borderAmount * 0.5;
    return texCoord * 0.5 + 0.5;
}

vec3 scanline(vec2 texCoord, vec3 color, float frequency, float intensity, float speed, float amount, vec3 scanlineRGB, bool monochrome, bool flipDirection) {
    if (flipDirection) {
        texCoord = texCoord.yx;
    }

    float count = viewHeight * amount;
    vec2 scanlineColor = vec2(
        sin(mod(texCoord.y + frameTimeCounter * 0.2 * speed, frequency) * count),
        cos(mod(texCoord.y + frameTimeCounter * 0.5 * speed, 0.7 * frequency) * count)
    );

    vec3 scanlines;
    if (monochrome) {
        scanlines = vec3(scanlineColor.y + scanlineColor.x * 0.2);
    } else {
        scanlines = vec3(scanlineColor.x * scanlineRGB.r, scanlineColor.y * scanlineRGB.g, scanlineColor.x * scanlineRGB.b);
    }

    return color += color * scanlines * intensity * 0.1;
}


vec4 samplePixelatedBuffer(sampler2D tex, vec2 coords, int size) { // thanks to belmu for the code (mine had edge artifacts) https://github.com/BelmuTM/Noble/tree/master
    vec2 aspectCorrectedSize = size * vec2(aspectRatio, 1.0);
    return texelFetch(tex, ivec2((floor(coords * aspectCorrectedSize) / aspectCorrectedSize) * viewSize), 0);
}

float halftones(vec2 texCoord, float angle, float scale) { // Thanks to https://www.shadertoy.com/view/4sBBDK by starea
    vec2 coord = texCoord * viewSize;
    vec2 dots = rotate(angle) * coord * scale;
    return sin(dots.x) * sin(dots.y) * 4.0;
}

float noiseSpeedLines(float a, float p, float s) {
    float p1 = hash11Modified(mod(floor(a), p), s);
    float p2 = hash11Modified(mod(floor(a) + 2.0, p), s);
    return smoothstep(0.0, 0.1, mix(p1, p2, smoothstep(0.0, 1.0, fract(a))) - 0.3);
}

float layeredNoiseSpeedLines(float a, float s) {
    return noiseSpeedLines(a, 20.0, s) + noiseSpeedLines(a * 5.0, 20.0 * 5.0, s);
}

float speedLines(vec2 uv) { // Thanks to https://www.shadertoy.com/view/NldyDn by HalbFettKaese - modified a bit
    uv = uv * 2.0 - 1.0;
    float a = atan(uv.x, uv.y) / pi;
    float value = layeredNoiseSpeedLines((a * 17 + velocity * 7.0) * SPEED_LINE_THICKNESS * 1.5, (floor(frameTimeCounter * 10.0 * SPEED_LINES_SPEED) / 10.0 + velocity * 0.1) * 2.0);
    value -= 1.0 / length(uv) * 0.9 * (1.0 - clamp(velocity, 0.0, 0.4));
    return clamp(value, 0.0, 0.1);
}

float randomNoiseOverlay1(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float grid(float uv) {
    float mainLine = smoothstep(0.9995 * (1.0 - MAIN_GRID_INTERVAL * 0.00005), 1.0, cos(uv * tau / (1.0 / MAIN_GRID_INTERVAL))) * 0.3;
    float subLine = smoothstep(0.9998 * (1.0 - SUB_GRID_INTERVAL * 0.00075), 1.0, cos(uv * tau * SUB_GRID_INTERVAL / (1.0 / MAIN_GRID_INTERVAL))) * 0.1;
      return mainLine + subLine;
}

// Function to apply horizontal noise
vec2 applyHorizontalNoise(vec2 texCoordM, float resolution, float intensity, float speed) {
    float horizontalNoiseResolution = resolution * 100.0;
    float horizontalNoiseIntensity = intensity * 0.002;
    float horizontalNoiseSpeed = speed * 0.0001;

    texCoordM.y *= horizontalNoiseResolution;
    texCoordM.y = float(int(texCoordM.y)) * (1.0 / horizontalNoiseResolution);
    float noise = retroNoise(vec2(frameTimeCounter * horizontalNoiseSpeed, texCoordM.y));
    texCoordM.x += noise * horizontalNoiseIntensity;
    return texCoordM;
}

// Function to apply vertical screen displacement
void applyVerticalScreenDisplacement(inout vec2 texCoordM, inout float verticalOffset, float verticalScrollSpeed, float verticalStutterSpeed, float verticalEdgeGlitch, bool isVertical) {
    float displaceEffectOn = 1.0;
    #if defined SPOOKY && (!defined RETRO_ON || !defined VERTICAL_SCREEN_DISPLACEMENT)
        float randomShutterTime = 24000.0 * hash1(worldDay * 5);
        int displaceEffect = int(hash1(worldDay / 2)) % (2 * 24000) + int(randomShutterTime);
        displaceEffectOn = 0.0;
        if (worldTime > displaceEffect && worldTime < displaceEffect + 100.0) {
            displaceEffectOn = 1.0;
        }
    #endif

    float scrollSpeed = verticalScrollSpeed * 2.0;
    float stutterSpeed = verticalStutterSpeed * 0.2;
    float scroll = (1.0 - step(retroNoise(vec2(frameTimeCounter * 0.00002, 8.0)), 0.9 * (1.0 - VERTICAL_SCROLL_FREQUENCY * 0.3))) * scrollSpeed;
    float stutter = (1.0 - step(retroNoise(vec2(frameTimeCounter * 0.00005, 9.0)), 0.8 * (1.0 - VERTICAL_STUTTER_FREQUENCY * 0.3))) * stutterSpeed;
    float stutter2 = (1.0 - step(retroNoise(vec2(frameTimeCounter * 0.00003, 5.0)), 0.7 * (1.0 - VERTICAL_STUTTER_FREQUENCY * 0.3))) * stutterSpeed;
    verticalOffset = sin(frameTimeCounter) * scroll + stutter * stutter2;
    if(isVertical) texCoordM.y = mix(texCoordM.y, mod(texCoordM.y + verticalOffset, verticalEdgeGlitch), displaceEffectOn);
    else texCoordM.x = mix(texCoordM.x, mod(texCoordM.x + verticalOffset, verticalEdgeGlitch), displaceEffectOn);
}

vec4 waterMarkFunction(ivec2 pixelSize, vec2 textCoord, vec2 screenUV, float watermarkSizeMult, bool hideWatermark){
    float watermarkAspectRatio = float(pixelSize.x) / pixelSize.y;
    float watermarkSize = 1 / watermarkSizeMult;

    if (aspectRatio < 3) textCoord += vec2(3 * screenUV.x * watermarkSize * 1.5 - 3 * watermarkSize * 1.5, 1.0 - 3 * watermarkAspectRatio * screenUV.y * watermarkSize * 1.5 / aspectRatio);
    else                 textCoord += vec2(screenUV.x * aspectRatio - aspectRatio, 1.0 - watermarkAspectRatio * screenUV.y);

    // Only sample texture if we're in the valid range
    if (textCoord.x > -1 && textCoord.x < 0 && textCoord.y > 0 && textCoord.y < 1) {
        vec2 texCoordMapped = fract(textCoord);
        ivec2 fetchCoord = ivec2(texCoordMapped * pixelSize);
        vec4 EuphoriaPatchesText = texelFetch(depthtex2, fetchCoord, 0);
        
        float guiIsNotHidden = 1.0;
        if (hideWatermark) {
            #if WATERMARK == 2
                if (hideGUI == 0) guiIsNotHidden = 0.0;
            #elif WATERMARK == 3
                if (hideGUI == 0 || heldItemId != 40000 && heldItemId2 != 40000) guiIsNotHidden = 0.0;
            #endif
        }
        return vec4(EuphoriaPatchesText.rgb, EuphoriaPatchesText.a * guiIsNotHidden);
    }
    return vec4(0.0); // Transparent
}

vec3 staticColor(vec3 color, float staticIntensity, float minStaticStrength, float maxStaticStrength, float staticSpeed) { // credit to arananderson https://www.shadertoy.com/view/tsX3RN
    float maxStrength = max(minStaticStrength, maxStaticStrength);
    float minStrength = min(minStaticStrength, maxStaticStrength);
    float speed = staticSpeed * 10.0;

    vec2 fractCoord = fract(texCoord * fract(sin(frameTimeCounter * speed)));

    maxStrength = clamp(sin(frameTimeCounter * 0.5), minStrength, maxStrength);

    vec3 staticColor = vec3(retroNoise(fractCoord)) * maxStrength;
    return mix(vec3(1.0), color - staticColor, staticIntensity);
}

#include "/lib/textRendering/textRenderer.glsl"

void beginTextM(int textSize, vec2 offset) {
    float scale = 860;
    beginText(ivec2(vec2(scale * viewWidth / viewHeight, scale) * texCoord) / textSize, ivec2(0 + offset.x, scale / textSize - offset.y));
    text.bgCol = vec4(0.0);
}

#include "/lib/misc/potato.glsl"

//Program//
void main() {
    vec3 color = vec3(0.0);
    float viewWidthM = viewWidth;
    float viewHeightM = viewHeight;

    #if BORDER_AMOUNT != 0
        vec2 texCoordM = border(texCoord);
    #else
        vec2 texCoordM = texCoord;
    #endif

    #ifdef CURVE_DISPLAY
        texCoordM = curveDisplay(texCoordM, CURVATURE_AMOUNT, SCREEN_ROUNDNESS);
    #endif

    vec2 texCoordBorder = texCoordM;

    #if CAMERA_NOISE_OVERLAY == 1
        texCoordM += vec2(randomNoiseOverlay1(texCoordM + vec2(0.0, 0.0)), randomNoiseOverlay1(texCoordM + vec2(1.0, 1.0))) * 0.01 * CAMERA_NOISE_OVERLAY_INTENSITY;
    #endif

    #if HORIZONTAL_NOISE > 0 && defined RETRO_ON
        texCoordM = applyHorizontalNoise(texCoordM, HORIZONTAL_NOISE, HORIZONTAL_NOISE_INTENSITY, HORIZONTAL_NOISE_SPEED);
    #endif

    #if (defined VERTICAL_SCREEN_DISPLACEMENT && defined RETRO_ON) || defined SPOOKY
    float verticalOffset = 0.0;
        applyVerticalScreenDisplacement(texCoordM, verticalOffset, VERTICAL_SCROLL_SPEED, VERTICAL_STUTTER_SPEED, VERTICAL_EDGE_GLITCH, true);
    #endif

    #if WATERMARK > 0
        vec4 watermarkColor = waterMarkFunction(ivec2(100, 29), vec2(0.05), texCoordM.xy, WATERMARK_SIZE, true);
    #endif

    #ifdef UNDERWATER_DISTORTION
        if (isEyeInWater == 1)
            texCoordM += WATER_REFRACTION_INTENSITY * 0.00035 * sin((texCoord.x + texCoord.y) * 25.0 + frameTimeCounter * UNDERWATER_DISTORTION_STRENGTH);
    #endif

    #if defined PIXELATE_SCREEN && defined RETRO_ON
        #if LONG_EXPOSURE > 0
        if(hideGUI == 0 || isViewMoving()){ // GUI visible OR moving
        #endif
        color = samplePixelatedBuffer(colortex3, texCoordM, PIXEL_SIZE_SCREEN).rgb;
        #if LONG_EXPOSURE > 0
        } else {
        color = samplePixelatedBuffer(colortex7, texCoordM, PIXEL_SIZE_SCREEN).rgb;
        }
        #endif
    #else
        #if LONG_EXPOSURE > 0
        if(hideGUI == 0 || isViewMoving()){ // GUI visible OR moving
        #endif
            color = texture2D(colortex3, texCoordM).rgb;
        #if LONG_EXPOSURE > 0
        } else { // this is the accumulated one
            color = texture2D(colortex7, texCoordM).rgb;
        }
        #endif
    #endif

    #if CHROMA_ABERRATION > 0 || defined SPOOKY
        vec2 scale = vec2(1.0, viewHeight / viewWidth);
        #ifdef SPOOKY
            float aberrationStrength = max(CHROMA_ABERRATION, playerMood * 10.0);
        #else
            float aberrationStrength = CHROMA_ABERRATION;
        #endif
        vec2 aberration = (texCoordM - 0.5) * (2.0 / vec2(viewWidth, viewHeight)) * scale * aberrationStrength;
        color.rb = vec2(texture2D(colortex3, texCoordM + aberration).r, texture2D(colortex3, texCoordM - aberration).b);
    #endif

    #if LETTERBOXING > 0
        #if BORDER_AMOUNT > 0
            viewWidthM = viewWidth - viewWidth * BORDER_AMOUNT * 0.04;
        #endif
        float letterboxMargin = 0.5 - viewWidthM / (2 * viewHeightM * ASPECT_RATIO);
        #if LETTERBOXING == 2
            letterboxMargin = mix(0.0, letterboxMargin, isSneaking);
        #endif
        
        if (texCoord.y > 1.0 - letterboxMargin || texCoord.y < letterboxMargin) {
            #ifdef EXCLUDE_ENTITIES
                if (int(texelFetch(colortex6, texelCoord, 0).g * 255.1) != 254) color *= 0.0;
            #else
                color *= mix(0.0, 1.0, LETTERBOXING_TRANSPARENCY);
            #endif
        }
    #endif

    #ifdef BAD_APPLE
        color = vec3((int(texelFetch(colortex6, texelCoord, 0).g * 255.1) != 254) ? 0.0 : 1.0);
    #endif
    
    #if DELTARUNE_BATTLE_BACKGROUND > 0
            vec3 deltaruneColor = movingCheckerboard(texCoord, 100.0, 1.0, vec2(0.05, -0.05), vec3(1.0, 0.0, 1.0));
            deltaruneColor += movingCheckerboard(texCoord, 100.0, 1.0, vec2(-0.025, 0.025), vec3(1.0, 0.0, 1.0) * 0.5);
        #if DELTARUNE_BATTLE_BACKGROUND == 1
            if (texture2D(depthtex0, texCoord).r == 1.0) color = deltaruneColor;
        #elif DELTARUNE_BATTLE_BACKGROUND == 2
            if ((int(texelFetch(colortex6, texelCoord, 0).g * 255.1) != 254)) {
                color = deltaruneColor;
            }
        #endif
    #endif

    #if IMAGE_SHARPENING > 0
        #if LONG_EXPOSURE > 0
        if(hideGUI == 0 || isViewMoving()){ // GUI visible OR moving
        #endif
            SharpenImage(color, texCoordM);
        #if LONG_EXPOSURE > 0
        }
        #endif
    #endif

    /*ivec2 boxOffsets[8] = ivec2[8](
        ivec2( 1, 0),
        ivec2( 0, 1),
        ivec2(-1, 0),
        ivec2( 0,-1),
        ivec2( 1, 1),
        ivec2( 1,-1),
        ivec2(-1, 1),
        ivec2(-1,-1)
    );

    for (int i = 0; i < 8; i++) {
        color = max(color, texelFetch(colortex3, texelCoord + boxOffsets[i], 0).rgb);
    }*/

    #if WATERMARK > 0
        color.rgb = mix(color.rgb, watermarkColor.rgb, watermarkColor.a);
    #endif

    #ifdef LET_THERE_BE_COLORS
        color = hash33(color * frameTimeCounter);
    #endif

    #if (STATIC_NOISE > 0 && defined RETRO_ON) || defined SPOOKY
        float staticIntensity = 0.0;
        #ifdef SPOOKY
            if (playerMood > 0.9) staticIntensity = (playerMood * 10.0 - 9.0) * 0.75;
        #else
            staticIntensity = STATIC_NOISE * 0.1;
        #endif
        color *= staticColor(color, staticIntensity, MIN_STATIC_STRENGTH, MAX_STATIC_STRENGTH, STATIC_SPEED); 
    #endif

    #if SCANLINE > 0 && defined RETRO_ON
        color = scanline(texCoord, color, SCANLINE_FREQUENCY, SCANLINE, SCANLINE_SPEED, SCANLINE_AMOUNT, vec3(SCANLINE_R, SCANLINE_G, SCANLINE_B), SCANLINE_NEW_MONOCHROME, SCANLINE_NEW_DIRECTION);
    #endif

    #ifdef HALFTONE
        #ifdef HALFTONE_MONOCHROME
            float colorOld = GetLuminance(color);
        #else
            vec3 colorOld = color;
        #endif
        const float dotAngle = HALFTONE_ANGLE * pi * 0.5;
        const float dotScale = HALFTONE_SCALE;
        const float dotBrightness = HALFTONE_BRIGHTNESS * 2.0;
        color = vec3(colorOld * dotBrightness * 5.0 - 5.0 + halftones(texCoordM, dotAngle, dotScale));
    #endif

    #ifdef SPOOKY
        color.rgb = mix(color.rgb, color.rgb * GetLuminance(color), 0.60);
    #endif

    #if SPEED_LINES > 0
        float speedLines = speedLines(texCoordM);
        speedLines = mix(0.0, speedLines, SPEED_LINES_TRANSPARENCY);
        #if SPEED_LINES == 1
            color += vec3(mix(0.0, speedLines, isSprinting));
        #else
            color += vec3(speedLines);
        #endif
    #endif

    #if MAIN_GRID_INTERVAL > 1
        float grid = max(grid(texCoordM.x), grid(texCoordM.y));
        #if GRID_CONDITION == 0
            color += grid;
        #elif GRID_CONDITION == 1
            color += mix(0.0, grid, isSneaking);
        #elif GRID_CONDITION == 2
            float isHoldingSpyglass = 0.0;
            if (heldItemId == 45013 || heldItemId2 == 45013) isHoldingSpyglass = 1.0; //holding spyglass
            color += mix(0.0, grid, isHoldingSpyglass);
        #endif
    #endif

    #if defined CURVE_DISPLAY || BORDER_AMOUNT != 0
        if (texCoordBorder.x < 0.0 || texCoordBorder.x > 1.0) color = vec3(0.0);
        if (texCoordBorder.y < 0.0 || texCoordBorder.y > 1.0) color = vec3(0.0);
    #endif

    ivec2 pixelToCheck = ivec2(42, 30);
    vec3 potatoColor = vec3(0.0);
    // beginTextM(8, vec2(6, 10)); printVec3(vec3(getPotatoColorInt(pixelToCheck))); endText(color.rgb);
    bool isPotato = checkPotatoPixel(pixelToCheck, ivec3(235, 191, 121), 0.1, potatoColor);
    if(!isPotato) color.rgb = potatoError();
    // color.rgb = potatoColor;

    #include "/lib/textRendering/all_error_messages.glsl"

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0);
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

noperspective out vec2 texCoord;

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif
