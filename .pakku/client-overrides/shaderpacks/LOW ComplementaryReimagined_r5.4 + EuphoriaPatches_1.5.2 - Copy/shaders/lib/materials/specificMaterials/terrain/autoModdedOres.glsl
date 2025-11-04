float epsilon = 0.00001;
vec2 absMidCoordPosM = absMidCoordPos - epsilon;
vec3 avgBorderColor = vec3(0.0);

avgBorderColor += texture2D(tex, midCoord + vec2( absMidCoordPosM.x, absMidCoordPosM.y)).rgb;
avgBorderColor += texture2D(tex, midCoord + vec2(-absMidCoordPosM.x, absMidCoordPosM.y)).rgb;
avgBorderColor += texture2D(tex, midCoord + vec2( absMidCoordPosM.x,-absMidCoordPosM.y)).rgb;
avgBorderColor += texture2D(tex, midCoord + vec2(-absMidCoordPosM.x,-absMidCoordPosM.y)).rgb;
avgBorderColor += texture2D(tex, midCoord + vec2(epsilon, absMidCoordPosM.y)).rgb;
avgBorderColor += texture2D(tex, midCoord + vec2(epsilon,-absMidCoordPosM.y)).rgb;
avgBorderColor += texture2D(tex, midCoord + vec2( absMidCoordPosM.x, epsilon)).rgb;
avgBorderColor += texture2D(tex, midCoord + vec2(-absMidCoordPosM.x, epsilon)).rgb;
avgBorderColor *= 0.125;

vec3 colorDif = abs(avgBorderColor - color.rgb);
emission = max(colorDif.r, max(colorDif.g, colorDif.b));
emission = pow2(emission * 2.5 - 0.15);