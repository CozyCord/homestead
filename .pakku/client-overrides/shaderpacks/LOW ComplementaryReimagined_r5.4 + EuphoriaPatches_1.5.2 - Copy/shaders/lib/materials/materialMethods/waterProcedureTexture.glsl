float random (in float x) { return fract(sin(x)*1e4);}
float random (in vec2 st) {return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* 43758.5453123);}
vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec4 hash4( vec2 p ) { return fract(sin(vec4( 1.0+dot(p,vec2(37.0,17.0)),
                                              2.0+dot(p,vec2(11.0,47.0)),
                                              3.0+dot(p,vec2(41.0,29.0)),
                                              4.0+dot(p,vec2(23.0,31.0))))*103.0); }

vec4 textureNoTile( sampler2D samp, in vec2 uv )
{
    vec2 iuv = floor( uv );
    vec2 fuv = fract( uv );

// #ifdef USEHASH
//     // generate per-tile transform (needs GL_NEAREST_MIPMAP_LINEARto work right)
//     vec4 ofa = texture( samp, (iuv + vec2(0.5,0.5))/256.0 );
//     vec4 ofb = texture( samp, (iuv + vec2(1.5,0.5))/256.0 );
//     vec4 ofc = texture( samp, (iuv + vec2(0.5,1.5))/256.0 );
//     vec4 ofd = texture( samp, (iuv + vec2(1.5,1.5))/256.0 );
// #else
    // generate per-tile transform
    vec4 ofa = hash4( iuv + vec2(0.0,0.0) );
    vec4 ofb = hash4( iuv + vec2(1.0,0.0) );
    vec4 ofc = hash4( iuv + vec2(0.0,1.0) );
    vec4 ofd = hash4( iuv + vec2(1.0,1.0) );
//#endif

    vec2 ddx = dFdx( uv );
    vec2 ddy = dFdy( uv );

    // transform per-tile uvs
    ofa.zw = sign(ofa.zw-0.5);
    ofb.zw = sign(ofb.zw-0.5);
    ofc.zw = sign(ofc.zw-0.5);
    ofd.zw = sign(ofd.zw-0.5);

    // uv's, and derivarives (for correct mipmapping)
    vec2 uva = uv*ofa.zw + ofa.xy; vec2 ddxa = ddx*ofa.zw; vec2 ddya = ddy*ofa.zw;
    vec2 uvb = uv*ofb.zw + ofb.xy; vec2 ddxb = ddx*ofb.zw; vec2 ddyb = ddy*ofb.zw;
    vec2 uvc = uv*ofc.zw + ofc.xy; vec2 ddxc = ddx*ofc.zw; vec2 ddyc = ddy*ofc.zw;
    vec2 uvd = uv*ofd.zw + ofd.xy; vec2 ddxd = ddx*ofd.zw; vec2 ddyd = ddy*ofd.zw;

    // fetch and blend
    vec2 b = smoothstep(0.25,0.75,fuv);

    return mix( mix( textureGrad( samp, uva, ddxa, ddya ),
                     textureGrad( samp, uvb, ddxb, ddyb ), b.x ),
                mix( textureGrad( samp, uvc, ddxc, ddyc ),
                     textureGrad( samp, uvd, ddxd, ddyd ), b.x), b.y );
}

vec3 voronoi( in vec2 x, float rnd ) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    // first pass: regular voronoi
    vec2 mg, mr;
    float md = 8.0;
    for (int j=-1; j<=1; j++ ) {
        for (int i=-1; i<=1; i++ ) {
            vec2 g = vec2(float(i),float(j));
            vec2 o = random2( n + g )*rnd;
            o = 0.5 + 0.5*sin( frameTimeCounter + 6.2831*o );
            vec2 r = g + o - f;
            float d = dot(r,r);

            if( d<md ) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }

    // second pass: distance to borders
    md = 8.0;
    for (int j=-2; j<=2; j++ ) {
        for (int i=-2; i<=2; i++ ) {
            vec2 g = mg + vec2(float(i),float(j));
            vec2 o = random2(n + g)*rnd;
            o = 0.5 + 0.5*sin( frameTimeCounter + 6.2831*o );
            vec2 r = g + o - f;

            if( dot(mr-r,mr-r)>0.00001 )
            md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
        }
    }
    return vec3( md, mr );
}

vec3 waterMaskFunc(vec3 worldPos, const float water_scroll_speed, vec3 waterColor, int mat, vec3 normal) {
    const float foam_speed = 0.05;
    const float water_warp = 0.005;
    vec3 water_color = vec3(0);
    if (mat == 10049) { // Water Cauldron
        water_color = saturateColors(waterColor, 0.3) * 0.7;
    } else {
        water_color = mix(waterColor * 0.4, vec3(0.22, 0.22, 0.22), 0.5);
    }

    //pixelated coord to created pixelated visual
    vec3 uv = worldPos;
    uv = (uv-.5)*.25+.5;
    float pixelWaterSize = 16;
    uv = floor(uv * (pixelWaterSize * 4)) / (pixelWaterSize * 4);

    float d = dot(uv.xz-0.5,uv.xz-0.5);
    vec3 c = voronoi(5.0*uv.xz, pow(d,.6) );

    vec2 water_pos = vec2(frameTimeCounter) * water_scroll_speed;
    vec3 foamNoise = textureNoTile(noisetex, uv.xz + vec2(frameTimeCounter) * foam_speed).xyz;

    vec3 result = vec3(0.0);
    // borders
    vec3 waterMask = mix(vec3(1.00), vec3(0.0), smoothstep( 0.04, 0.06, c.x ));
    vec3 foam = waterMask * vec3(foamNoise.y - 0.55);
    foam = clamp(foam, vec3(0.02), vec3(1.0));
    foam *= 1.3;

    //not regular structure water
    float water_sample = floor(texture2D(noisetex, uv.xz * 0.25 + foamNoise.xz * water_warp + water_pos).r * 16) / 16;
    vec3 water = mix(water_color, vec3(0.001), water_sample * float(foam));

    // small particles in water
    // Grid
    vec2 st = uv.xz;
    st *= vec2(100.0,100.);
    vec2 ipos = floor(st);  // integer
    vec2 vel = vec2(frameTimeCounter); // time
    vel *= vec2(-1.,0.); // direction
    vel *= (step(1.0, mod(ipos.y,5.024))-0.5)*2.; // Oposite directions
    vel *= vec2(-1.,0.); // direction
    vel *= random(ipos.y); // random speed

    //Creating particles
    vec3 pixelParticle = vec3(1.0);
    pixelParticle *= random(floor(vec2(st.x*0.32, st.y)+vel));
    float mixFactor = clamp((sin(frameTimeCounter*0.1) + 1.0)*0.5, 0.005, 0.15);
    pixelParticle = smoothstep(0.0,mixFactor,pixelParticle);
    pixelParticle = (1.0 - pixelParticle) *  (foamNoise.y - 0.55);
    pixelParticle = clamp(pixelParticle, vec3(0.02), vec3(1.0));

    result = foam * 2.0 + pixelParticle * 2.0 + water;
    //result = vec3(foamNoise.y - 0.55);
    return result;
}