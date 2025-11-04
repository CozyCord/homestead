float animation = min(starter * 0.3, 0.1) * 10.0;
color.rgb = mix(mix(vec3(GetLuminance(color.rgb)), vec3(0.0), 0.65), color.rgb, animation);

beginTextM(4, vec2(20, 90));
    text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);
    printString((
        _P, _l, _e, _a, _s, _e, _space, _g, _o, _space, _t, _o, _space,
        _t, _h, _e, _space, _dot, _m, _i, _n, _e, _c, _r, _a, _f, _t, _gt, _s, _h, _a, _d, _e, _r, _p, _a, _c, _k, _s,_space, _F, _o, _l, _d, _e, _r, _space, _minus, _space
    ));
    printLine();
    printString((
        _O, _p, _e, _n, _space, _t, _h, _e, _space, _S, _e, _t, _t, _t, _i, _n, _s, _dot, _t, _x, _t, _space, _F, _i, _l, _e, _space, _minus, _space
    ));
    printLine();
    printString((
        _C, _o, _m, _p, _l, _e, _m, _e, _n, _t, _a, _r, _y, _V, _I, _S, _U, _A, _L, _S, _T, _Y, _L, _E, _under, _r, _X, _dot, _x, _space, _plus, _space, _E, _u, _p, _h, _o, _r, _i, _a, _P, _a, _t, _c, _h, _e, _s, _under, _Y, _dot, _y, _dot, _t, _x, _t, _space, _minus, _space
    ));
    printLine();
    printString((
        _a, _n, _d, _space, _r, _e, _m, _o, _v, _e, _space, _t, _h, _e, _space, _l, _i, _n, _e, _space, _quote, _M, _U, _L, _T, _I, _C, _O, _L, _O, _R, _E, _D, _under, _B, _L, _O, _C, _K, _L, _I, _G, _H, _T, _equal, _t, _r, _u, _e, _quote, _space
    ));
    vec3 textColor = color.rgb;
endText(textColor);
color.rgb = mix(textColor, color.rgb, animation);