#if defined LAVA_EDGE_EFFECT && defined GBUFFERS_TERRAIN && !defined WORLD_CURVATURE
    if (mat == 10068){
        vec3 voxelPos = SceneToVoxel(playerPos);

        if (CheckInsideVoxelVolume(voxelPos)) {
            mat2 isSurroundingLava = mat2(0,0,0,0); // Thanks to gri for the help!

            ivec3 coordsLava = ivec3(floor(vec3(voxelPos)));
            ivec3 coords = ivec3(floor(vec3(voxelPos.x - 0.5, voxelPos.y - 0.3, voxelPos.z - 0.5))); // shift coords to the center of the block
            uint lavaVoxel = texelFetch(voxel_sampler, ivec3(coordsLava + ivec3(0, 1, 0)), 0).r; // coords for block above

            if (lavaVoxel != uint(13)){ // check if the above block is not lava, to only have the edge effect on the top most lava layer
                for (int i = 0; i < 2; i++){ // check if the surrounding blocks are lava or not, 1 at the center of a non-lava block, 0 at the center of a lava block
                    for ( int j = 0; j < 2; j++){
                        uint voxel = texelFetch(voxel_sampler, ivec3(coords + ivec3(i, 0, j)), 0).r;
                        isSurroundingLava[i][j] = voxel != uint(13) ? 1 : 0;
                    }
                }
            }
            float edge = mix(
                mix(isSurroundingLava[0][0],
                    isSurroundingLava[0][1],
                    fract(voxelPos.z + 0.5)),
                mix(isSurroundingLava[1][0],
                    isSurroundingLava[1][1],
                    fract(voxelPos.z + 0.5)),
                fract(voxelPos.x + 0.5)
            );

            edge = 1.0 - cos((edge * pi) / 1.5); // ease in towards the centre of the block to create a better shape
            edge *= clamp01(blockUV.y - 0.3) * 10/7; // Gradient towards the bottom, so 0.3 is now 0

            vec3 edgeColor = mix(vec3(0.4, 0.2, 0.1), maxLavaColor, 0.9); // make the color vary depending on the lava noise
            #ifdef SOUL_SAND_VALLEY_OVERHAUL_INTERNAL
                edgeColor = changeColorFunction(edgeColor, 3.0, colorSoul, inSoulValley);
            #elif defined PURPLE_END_FIRE_INTERNAL
                edgeColor = changeColorFunction(sqrt1(edgeColor), 4.0, colorEndBreath, 1.0);
            #endif

            vec3 absPlayerPos = abs(playerPos);
            float maxPlayerPos = max(absPlayerPos.x, max(absPlayerPos.y * 2.0, absPlayerPos.z));
            float edgeDecider = pow2(min1(maxPlayerPos / min(effectiveACLdistance, far) * 2.0)); // this is to make the effect fade at the edge of ACL range

            color.rgb = mix(color.rgb, edgeColor * 3.0, edge * (1.0 - edgeDecider));
            emission = min(mix(emission, 1.3 + emission * 1.1, edge * (1.0 - edgeDecider)), 3.5);
        }
    }
#endif