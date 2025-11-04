color.rgb = mix(color.rgb, vec3(0.0), 0.65);

beginTextM(8, vec2(6, 10));
    text.fgCol = vec4(1.0, 0.0, 0.0, 1.0);
    printString((_I, _m, _p, _o, _r, _t, _a, _n, _t, _space, _E, _r, _r, _o, _r));
endText(color.rgb);

beginTextM(4, vec2(15, 36));
    printLine();
    text.fgCol = vec4(vec3(1.0), 1.0);
    printString((
        _C, _o, _l, _o, _r, _e, _d, _space, _L, _i, _g, _h, _t, _i, _n, _g, _space, _i, _s, _space,
        _n, _o, _t, _space
    ));
    printLine();
    printString((
        _s, _u, _p, _p, _o, _r, _t, _e, _d, _space, _o, _n, _space, _O, _p, _t, _i, _f, _i, _n, _e,
        _dot, _space, _Y, _o, _u, _space, _n, _e, _e, _d
    ));
    printLine();
    printString((
        _t, _o, _space, _s, _w, _i, _t, _c, _h, _space, _t, _o, _space, _t, _h, _e, _space,
        _quote, _I, _r, _i, _s, _quote, _space, _m, _o, _d, _dot
    ));
    printLine();
    printString((
        _D, _o, _w, _n, _l, _o, _a, _d, _colon, _space,
        _w, _w, _w, _dot, _i, _r, _i, _s, _s, _h, _a, _d, _e, _r, _s, _dot, _d, _e, _v
    ));
endText(color.rgb);

beginTextM(2, vec2(30, 155));
    printLine();
    text.fgCol = vec4(vec3(0.65), 1.0);
    printString((
        _O, _p, _t, _i, _f, _i, _n, _e, _space,
        _d, _o, _e, _s, _space, _n, _o, _t, _space, _h, _a, _v, _e, _space, _t, _h, _e, _space,
        _f, _u, _n, _c, _t, _i, _o, _n, _a, _l, _i, _t, _y, _space, _t, _h, _a, _t, _space,
        _C, _o, _m, _p, _l, _e, _m, _e, _n, _t, _a, _r, _y, _space
    ));
    printLine();
    printString((
        _u, _s, _e, _s, _space, _t, _o, _space, _p, _r, _o, _v, _i, _d, _e, _space, _y, _o, _u, _space,
        _a, _space, _f, _u, _l, _l, _y, _space, _f, _l, _e, _d, _g, _e, _d, _space,
        _c, _o, _l, _o, _r, _e, _d, _space, _l, _i, _g, _h, _t, _i, _n, _g, _space,
        _e, _x, _p, _e, _r, _i, _e, _n, _c, _e, _dot
    ));
    printLine();
    printString((
        _T, _h, _e, _space, _I, _r, _i, _s, _space, _m, _o, _d, _space, _i, _s, _space, _a, _space,
        _m, _u, _c, _h, _space, _b, _e, _t, _t, _e, _r, _space, _a, _l, _t, _e, _r, _n, _a, _t, _i, _v, _e,
        _space, _t, _h, _a, _t, _space, _p, _r, _o, _v, _i, _d, _e, _s, _space, _a, _space,
        _l, _o, _t, _space, _o, _f
    ));
    printLine();
    printString((
        _a, _d, _d, _i, _t, _i, _o, _n, _a, _l, _space, _s, _h, _a, _d, _e, _r, _space,
        _f, _e, _a, _t, _u, _r, _e, _s, _comma, _space, _l, _e, _s, _s, _space, _b, _u, _g, _s,
        _comma, _space, _a, _n, _d, _space, _m, _o, _r, _e, _space,
        _p, _e, _r, _f, _o, _r, _m, _a, _n, _c, _e, _dot
    ));
    printLine();
    printLine();
    printString((
        _O, _r, _space, _D, _i, _s, _a, _b, _l, _e, _space, _i, _t, _space, _u, _n, _d, _e, _r, _colon, _space
    ));
    printLine();
    printString((
        _S, _h, _a, _d, _e, _r, _space, _S, _e, _t, _t, _i, _n, _g, _s,
        _space, _gt, _space, _P, _e, _r, _f, _o, _r, _m, _a, _n, _c, _e, _space, _gt, _space,
        _A, _d, _v, _a, _n, _c, _e, _d, _space, _C, _o, _l, _o, _r, _e, _d, _space, _L, _i, _g, _h, _t, _i, _n, _g
    ));
    printLine();
    printLine();
    text.fgCol = vec4(1.0, 0.0, 1.0, 1.0);
    printString((
        _E, _u, _p, _h, _o, _r, _i, _a, _space, _P, _a, _t, _c, _h, _e, _s
    ));
    text.fgCol = vec4(vec3(0.65), 1.0);
    printString((_space, _h, _a, _s, _space,
        _a, _space, _s, _c, _r, _e, _e, _n, _s, _p, _a, _c, _e, _space,
        _c, _o, _l, _o, _r, _e, _d, _space, _l, _i, _g, _h, _t, _i, _n, _g, _space, _o, _p, _t, _i, _o, _n
    ));
    printLine();
    printString((
        _w, _h, _i, _c, _h, _space, _w, _o, _r, _k, _s, _space, _o, _n, _space, _O, _p, _t, _i, _F, _n, _e, _dot
    ));
    printLine();
    printLine();
    printString((
        _A, _v, _a, _i, _l, _a, _b, _l, _e, _space, _u, _n, _d, _e, _r, _colon
    ));
    printLine();
    printString((
        _E, _u, _p, _h, _o, _r, _i, _a, _space, _P, _a, _t, _c, _h, _e, _s, _space, _S, _e, _t, _t, _i, _n, _g, _s,
        _space, _gt, _space, _P, _o, _p, _u, _l, _a, _r, _space, _S, _e, _t, _t, _i, _n, _g, _s, _space, _gt, _space,
        _E, _u, _p, _h, _o, _r, _i, _a, _space, _C, _o, _l, _o, _r, _e, _d, _space, _L, _i, _g, _h, _t, _i, _n, _g
    ));
    printLine();
    printLine();
    text.fgCol = vec4(vec3(0.6, 0.8196, 0.8549), 1.0);
    printString((
        _P, _l, _e, _a, _s, _e, _space, _n, _o, _t, _e, _space, _t, _h, _a, _t, _space,
        _u, _s, _i, _n, _g, _space, _a, _n, _space, _o, _l, _d, _space, _I, _r, _i, _s, _space,
        _v, _e, _r, _s, _i, _o, _n, _space, _w, _i, _l, _l, _space, _n, _o, _t, _space
    ));
    printLine();
    printString((
        _w, _o, _r, _k, _space, _a, _n, _d, _space, _m, _a, _y, _space,
        _s, _t, _i, _l, _l, _space, _c, _a, _u, _s, _e, _space, _t, _h, _i, _s, _space,
        _e, _r, _r, _o, _r, _space, _t, _o, _space, _a, _p, _p, _e, _a, _r, _dot
    ));
endText(color.rgb);