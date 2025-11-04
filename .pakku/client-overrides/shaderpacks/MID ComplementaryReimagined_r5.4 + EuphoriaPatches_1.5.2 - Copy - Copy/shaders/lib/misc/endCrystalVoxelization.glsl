layout(r32i) uniform iimage2D endcrystal_img;

void UpdateEndCrystalMap(vec3 pos) {
    int packedPos = int(pos.x + 512.5) + (int(pos.y + 512.5) << 10) + (int(pos.z + 512.5) << 20);
    for (int k = 0; k < 20; k++) {
        int registeredPos = imageAtomicCompSwap(endcrystal_img, ivec2(k, 0), 0, packedPos);
        vec3 otherPos = vec3(ivec3(registeredPos) >> ivec3(0, 10, 20) & 1023) - 512.0;
        if (registeredPos == 0 || length((otherPos - pos) * vec3(1, 0.3, 1)) < 2.3) {
            ivec4 addData = ivec4(10 * pos.x + 5120.5, 10 * pos.y + 5120.5, 10 * pos.z + 5120.5, 5130) - 5120;
            for (int i = 0; i < 4; i++) {
                imageAtomicAdd(endcrystal_img, ivec2(k, i+1), addData[i]);
            }
            break;
        }
    }
}

void UpdateBeamMap(vec3 pos) {
    int packedPos = int(pos.x + 512.5) + (int(pos.y + 512.5) << 10) + (int(pos.z + 512.5) << 20);
    for (int k = 20; k < 35; k++) {
        int registeredPos = imageAtomicCompSwap(endcrystal_img, ivec2(k, 0), 0, packedPos);
        vec3 otherPos = vec3(ivec3(registeredPos) >> ivec3(0, 10, 20) & 1023) - 512.0;
        if (registeredPos == 0 || length((otherPos - pos)) < 10.0) {
            ivec4 addData = ivec4(10 * pos.x + 5120.5, 10 * pos.y + 5120.5, 10 * pos.z + 5120.5, 5130) - 5120;
            for (int i = 0; i < 4; i++) {
                imageAtomicAdd(endcrystal_img, ivec2(k, i+1), addData[i]);
            }
            break;
        }
    }
}

void UpdateDragonPos(vec3 pos) {
    ivec4 addData = ivec4(10 * pos.x + 5120.5, 10 * pos.y + 5120.5, 10 * pos.z + 5120.5, 5130) - 5120;
    for (int i = 0; i < 4; i++) {
        imageAtomicAdd(endcrystal_img, ivec2(35, i+1), addData[i]);
    }
}

void SetEndDragonDeath() {
    imageAtomicExchange(endcrystal_img, ivec2(35, 0), 10000 + int(3000 * frameTime));
}

void SetEndPortalLoc(vec3 pos) {
    ivec4 coords = ivec4(pos + at_midBlock.xyz / 64.0 + cameraPositionFract + 1000, 1001) - 1000;
    for (int k = 0; k < 4; k++) {
        imageAtomicAdd(endcrystal_img, ivec2(35, k), coords[k]);
    }
}