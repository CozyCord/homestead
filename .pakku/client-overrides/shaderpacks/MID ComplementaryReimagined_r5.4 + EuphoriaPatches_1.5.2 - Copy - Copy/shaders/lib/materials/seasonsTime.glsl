#if SEASONS == 1
    #if SEASON_LENGTH >= 24000
        int seasonLength = SEASON_LENGTH;
    #else
        int seasonLength = SEASON_LENGTH * 24000;
    #endif

    float YearLoop = (worldDay * 24000 + worldTime + SEASON_START * seasonLength) % (seasonLength * 4);

    float summer = max(0.0, (1.0 + SEASON_TRANSITION_START)       * (clamp(YearLoop - seasonLength * 0, 0, seasonLength) / seasonLength) - SEASON_TRANSITION_START);
    float autumn = max(0.0, (1.0 + SEASON_TRANSITION_START * 2.5) * (clamp(YearLoop - seasonLength * 1, 0, seasonLength) / seasonLength) - SEASON_TRANSITION_START * 2.5); // 2.5 to make snow appear sooner 
    float winter = max(0.0, (1.0 + SEASON_TRANSITION_START)       * (clamp(YearLoop - seasonLength * 2, 0, seasonLength) / seasonLength) - SEASON_TRANSITION_START);
    float spring = max(0.0, (1.0 + SEASON_TRANSITION_START)       * (clamp(YearLoop - seasonLength * 3, 0, seasonLength) / seasonLength) - SEASON_TRANSITION_START);

    float summerTime = spring - summer + 1.0;
    float autumnTime = summer - autumn;
    float winterTime = autumn - winter;
    float springTime = winter - spring;

#elif SEASONS == 2
    float summerTime = 1.0;
    float autumnTime = 0.0;
    float winterTime = 0.0;
    float springTime = 0.0;
#elif SEASONS == 3
    float summerTime = 0.0;
    float autumnTime = 1.0;
    float winterTime = 0.0;
    float springTime = 0.0;
#elif SEASONS == 4
    float summerTime = 0.0;
    float autumnTime = 0.0;
    float winterTime = 1.0;
    float springTime = 0.0;
#elif SEASONS == 5
    float summerTime = 0.0;
    float autumnTime = 0.0;
    float winterTime = 0.0;
    float springTime = 1.0;
#endif