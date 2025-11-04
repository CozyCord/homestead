#ifdef SOUL_SAND_VALLEY_OVERHAUL_INTERNAL
	#ifdef SPOOKY
		vec3 blocklightCol = mix(vec3(0.2, 0.1098, 0.0431) * vec3(XLIGHT_R, XLIGHT_G, XLIGHT_B), vec3(0.05, 0.22, 0.25), inSoulValley);
	#else
		vec3 blocklightCol = mix(vec3(0.1775, 0.108, 0.0775) * vec3(XLIGHT_R, XLIGHT_G, XLIGHT_B), vec3(0.05, 0.22, 0.25), inSoulValley);
	#endif
    vec3 fireSpecialLightColorGradient = mix(vec3(2.0, 0.87, 0.27) * 3.8, mix(vec3(2.5, 0.87, 0.27), vec3(0.5, 1.9, 2.1) * 3.8, 0.3), inSoulValley);
    vec3 torchBlockSpecialLightColor = mix(vec3(2.0, 0.87, 0.27) * 3.8, mix(vec3(2.5, 0.87, 0.27), vec3(0.5, 1.9, 2.1) * 3.8, 0.5), inSoulValley);
    vec3 lanternBlockSpecialLightColor = mix(vec3(2.0, 0.87, 0.27) * 3.8, mix(vec3(2.5, 0.87, 0.27), vec3(0.5, 1.9, 2.1) * 3.8, 0.4), inSoulValley);
	vec3 fireSpecialLightColor = mix(vec3(2.0, 0.87, 0.27) * 3.8, vec3(0.5, 1.9, 2.1) * 3.8, inSoulValley);
	vec4 lavaSpecialLightColor = vec4(mix(vec3(3.0, 0.9, 0.2) * 4.0, vec3(0.5, 1.9, 2.1) * 4.0, inSoulValley), 0.0);
	vec4 brewingStandSpecialLightColor = vec4(mix(vec3(2.5, 1.2, 0.4) * 0.1, vec3(0.5, 1.9, 2.1) * 0.1, inSoulValley), 0.1);
#elif defined PURPLE_END_FIRE_INTERNAL
	#ifdef SPOOKY
		vec3 blocklightCol = vec3(0.2, 0.1098, 0.0431) * vec3(XLIGHT_R, XLIGHT_G, XLIGHT_B);
	#else
		vec3 blocklightCol = vec3(0.1775, 0.108, 0.0775) * vec3(XLIGHT_R, XLIGHT_G, XLIGHT_B);
	#endif
    vec3 fireSpecialLightColor = vec3(0.6, 0.3, 2.4) * 3.8;
	vec3 fireSpecialLightColorGradient = mix(vec3(2.0, 0.77, 0.17) * 3.8, fireSpecialLightColor, clamp01(0.7 + max(0.0, clamp01(sin(pow2(texture2D(noisetex, vec2(frameTimeCounter * 0.01)).r))))));
	vec3 torchBlockSpecialLightColor = mix(vec3(2.0, 0.87, 0.27), fireSpecialLightColor, 0.75);
	vec3 lanternBlockSpecialLightColor = fireSpecialLightColor;
	vec4 lavaSpecialLightColor = vec4(vec3(1.0, 0.5, 4.0) * 4.0, 0.5);
	vec4 brewingStandSpecialLightColor = vec4(vec3(0.10, 0.05, 0.4) * 0.4, 0.1);
#else
	#ifdef SPOOKY
		vec3 blocklightCol = vec3(0.2, 0.1098, 0.0431) * vec3(XLIGHT_R, XLIGHT_G, XLIGHT_B);
	#else
		vec3 blocklightCol = vec3(0.1775, 0.108, 0.0775) * vec3(XLIGHT_R, XLIGHT_G, XLIGHT_B);
	#endif
	vec3 fireSpecialLightColor = vec3(2.0, 0.87, 0.27) * 3.8;
	vec3 fireSpecialLightColorGradient = fireSpecialLightColor;
	vec3 torchBlockSpecialLightColor = fireSpecialLightColor;
	vec3 lanternBlockSpecialLightColor = fireSpecialLightColor;
	vec4 lavaSpecialLightColor = vec4(vec3(3.0, 0.9, 0.2) * 4.0, 0.0);
	vec4 brewingStandSpecialLightColor = vec4(vec3(2.5, 1.2, 0.4) * 0.1, 0.1);
#endif
#if defined NETHER && defined BIOME_COLORED_NETHER_PORTALS
	vec3 netherPortalSpecialLightColor = normalize(netherColor) * 2.0;
	vec3 respawnAnchorSpecialLightColor = normalize(netherColor) * 2.0;
#else
	vec3 netherPortalSpecialLightColor = vec3(1.8, 0.4, 2.2) * 0.8;
	vec3 respawnAnchorSpecialLightColor = vec3(1.7, 0.9, 0.4) * 2.0;
#endif
vec3 redstoneSpecialLightColor = vec3(4.0, 0.1, 0.1);
vec4 soulFireSpecialColor = vec4(vec3(0.3, 2.0, 2.2) * 1.0, 0.3);
float candleColorMult = 2.0;
float candleExtraLight = 0.004;
#if END_ROD_COLOR_PROFILE == 1
	vec3 endRodSpacialColor = vec3(END_ROD_R, END_ROD_G, END_ROD_B) / 255 * END_ROD_I;
#elif (END_ROD_COLOR_PROFILE == 2 || (END_ROD_COLOR_PROFILE == 3 && defined OVERWORLD)) && COLORED_LIGHTING_INTERNAL > 0
	vec3 endRodSpacialColor = vec3(pow2(getRainbowColor(vec2(0.0), float(END_ROD_RAINBOW_ANIMATE))));
#else
	#ifdef END
		vec3 endRodSpacialColor = vec3(1.25, 0.5, 1.25); // End Rod in the End dimension
	#else
		vec3 endRodSpacialColor = vec3(1.0, 1.0, 1.0);
	#endif
#endif
#ifdef EMISSIVE_ENCHANTING_TABLE
	vec3 enchantingTableSpecialLightColor = vec3(0.5, 2.0, 2.0) * 0.4;
#else
	vec3 enchantingTableSpecialLightColor = vec3(1.4, 1.1, 0.5);
#endif
void AddSpecialLightDetail(inout vec3 light, vec3 albedo, float emission) {
	vec3 lightM = max(light, vec3(0.0));
	lightM /= (0.2 + 0.8 * GetLuminance(lightM));
	lightM *= (1.0 / (1.0 + emission)) * 0.22;
	light *= 0.9;
	light += pow2(lightM / (albedo + 0.1));
}
vec4 GetSpecialBlocklightColor(int mat) {
	/* Please note that these colors do not determine the intensity of the
	final light. Instead; higher values of color change how long the color
	will travel, and also how dominant it will be next to other colors.*/
	/* Additional feature: An alpha value bigger than 0 will make that
	block cast extra light regardless of the vanilla lightmap. Use this
	with caution though because our floodfill isn't as accurate as vanilla.*/

	if (mat < 50) {
		if (mat < 26) {
			if (mat < 14) {
				if (mat < 8) {
					if (mat == 2) return vec4(torchBlockSpecialLightColor, 0.0); // Torch
					if (mat == 3) return vec4(endRodSpacialColor * 4.0, 0.0); // End Rod - This is the base for all lights. Total value 12. vec3(1.0, 1.0, 1.0) * 4.0
					if (mat == 4) return vec4(vec3(1.0, 1.5, 2.0) * 3.0, 0.0); // Beacon
					if (mat == 5) return vec4(fireSpecialLightColorGradient, 0.0); // Fire
					if (mat == 6) return vec4(vec3(0.7, 1.5, 1.5) * 1.7, 0.0); // Sea Pickle:Waterlogged
					if (mat == 7) return vec4(pow(vec3(1.1, 0.85, 0.35), vec3(FROGLIGHT_SATURATION * 0.5 + 0.5)) * 5.0, 0.0); // Ochre Froglight
				} else {
					if (mat == 8) return vec4(pow(vec3(0.6, 1.3, 0.6), vec3(FROGLIGHT_SATURATION * 0.5 + 0.5)) * 4.5, 0.0); // Verdant Froglight
					if (mat == 9) return vec4(pow(vec3(1.1, 0.5, 0.9), vec3(FROGLIGHT_SATURATION * 0.5 + 0.5)) * 4.5, 0.0); // Pearlescent Froglight
					if (mat == 10) return vec4(vec3(1.7, 0.9, 0.4) * 4.0, 0.0); // Glowstone
					if (mat == 11) return vec4(fireSpecialLightColor, 0.0); // Jack o'Lantern
					if (mat == 12) return vec4(lanternBlockSpecialLightColor, 0.0); // Lantern
					if (mat == 13) return lavaSpecialLightColor; // Lava
				}
			} else {
				if (mat < 20) {
					if (mat == 14) return vec4(lavaSpecialLightColor.rgb, 0.0); // Lava Cauldron
					if (mat == 15) return vec4(fireSpecialLightColorGradient, 0.0); // Campfire:Lit
					if (mat == 16) return vec4(vec3(1.7, 0.9, 0.4) * 4.0, 0.0); // Redstone Lamp:Lit
					if (mat == 17) return vec4(respawnAnchorSpecialLightColor, 0.0); // Respawn Anchor:Lit
					if (mat == 18) return vec4(vec3(1.0, 1.25, 1.5) * 3.4, 0.0); // Sea Lantern
					if (mat == 19) return vec4(vec3(3.0, 0.9, 0.2) * 3.0, 0.0); // Shroomlight
				} else {
					if (mat == 20) return vec4(vec3(2.3, 0.9, 0.2) * 3.4, 0.0); // Cave Vines:With Glow Berries
					if (mat == 21) return vec4(fireSpecialLightColor * 0.7, 0.0); // Furnace:Lit
					if (mat == 22) return vec4(fireSpecialLightColor * 0.7, 0.0); // Smoker:Lit
					if (mat == 23) return vec4(fireSpecialLightColor * 0.7, 0.0); // Blast Furnace:Lit
					if (mat == 24) return vec4(fireSpecialLightColor * 0.25 * candleColorMult, candleExtraLight); // Standard Candles:Lit
					if (mat == 25) return vec4(netherPortalSpecialLightColor * 2.0, 0.4); // Nether Portal
				}
			}
		} else {
			if (mat < 38) {
				if (mat < 32) {
					if (mat == 26) return vec4(netherPortalSpecialLightColor, 0.0); // Crying Obsidian
					if (mat == 27) return soulFireSpecialColor; // Soul Fire
					if (mat == 28) return soulFireSpecialColor; // Soul Torch
					if (mat == 29) return soulFireSpecialColor; // Soul Lantern
					if (mat == 30) return soulFireSpecialColor; // Soul Campfire:Lit
					if (mat == 31) return vec4(redstoneSpecialLightColor * 0.5, 0.1); // Redstone Ores:Lit
				} else {
					if (mat == 32) return vec4(redstoneSpecialLightColor * 0.3, 0.1); // Redstone Ores:Unlit
					if (mat == 33) return vec4(enchantingTableSpecialLightColor, 0.0); // Enchanting Table
                    #if GLOWING_LICHEN > 0
						if (mat == 34) return vec4(vec3(0.8, 1.1, 1.1), 0.05); // Glow Lichen with IntegratedPBR
					#else
						if (mat == 34) return vec4(vec3(0.4, 0.55, 0.55), 0.0); // Glow Lichen vanilla
					#endif
					if (mat == 35) return vec4(redstoneSpecialLightColor * 0.25, 0.0); // Redstone Torch
					if (mat == 36) return vec4(vec3(0.325, 0.15, 0.425) * 2.0, 0.05); // Amethyst Cluster, Amethyst Buds, Calibrated Sculk Sensor
					if (mat == 37) return vec4(lavaSpecialLightColor.rgb * 0.1, 0.1); // Magma Block
				}
			} else {
				if (mat < 44) {
					#ifdef EMISSIVE_DRAGON_EGG
					if (mat == 38) return vec4(vec3(2.0, 0.5, 1.5) * 0.3, 0.1); // Dragon Egg
					#endif
					if (mat == 39) return vec4(vec3(2.0, 1.0, 1.5) * 0.25, 0.1); // Chorus Flower
					if (mat == 40) return brewingStandSpecialLightColor; // Brewing Stand
					if (mat == 41) return vec4(redstoneSpecialLightColor * 0.4, 0.15); // Redstone Block
					if (mat == 42) return vec4(vec3(0.75, 0.75, 3.0) * 0.277, 0.15); // Lapis Block
					if (mat == 43) return vec4(vec3(1.7, 0.9, 0.4) * 0.45, 0.05); // Iron Ores
				} else {
					if (mat == 44) return vec4(vec3(1.7, 1.1, 0.2) * 0.45, 0.1); // Gold Ores
					if (mat == 45) return vec4(vec3(1.7, 0.8, 0.4) * 0.45, 0.05); // Copper Ores
					if (mat == 46) return vec4(vec3(0.75, 0.75, 3.0) * 0.2, 0.1); // Lapis Ores
					if (mat == 47) return vec4(vec3(0.5, 3.5, 0.5) * 0.3, 0.1); // Emerald Ores
					if (mat == 48) return vec4(vec3(0.5, 2.0, 2.0) * 0.4, 0.15); // Diamond Ores
					if (mat == 49) return vec4(vec3(1.5, 1.5, 1.5) * 0.3, 0.05); // Nether Quartz Ore
				}
			}
		}
	} else {
		if (mat < 74) {
			if (mat < 62) {
				if (mat < 56) {
					if (mat == 50) return vec4(vec3(1.7, 1.1, 0.2) * 0.45, 0.05); // Nether Gold Ore
					if (mat == 51) return vec4(vec3(1.7, 1.1, 0.2) * 0.45, 0.05); // Gilded Blackstone
					if (mat == 52) return vec4(vec3(1.8, 0.8, 0.4) * 0.6, 0.15); // Ancient Debris
					if (mat == 53) return vec4(vec3(1.4, 0.2, 1.4) * 0.3, 0.05); // Spawner
					if (mat == 54) return vec4(vec3(3.1, 1.1, 0.3) * 1.0, 0.1); // Trial Spawner:NotOminous:Active, Vault:NotOminous:Active
					if (mat == 55) return vec4(vec3(1.7, 0.9, 0.4) * 4.0, 0.0); // Copper Bulb:BrighterOnes:Lit
				} else {
					if (mat == 56) return vec4(vec3(1.7, 0.9, 0.4) * 2.0, 0.0); // Copper Bulb:DimmerOnes:Lit
					if (mat == 57) return vec4(vec3(0.1, 0.3, 0.4) * 0.5, 0.0005); // Sculk++
					if (mat == 58) return vec4(vec3(0.0, 1.4, 1.4) * 4.0, 0.15); // End Portal Frame:Active
					if (mat == 59) return vec4(0.0); // Bedrock
					if (mat == 60) return vec4(vec3(3.1, 1.1, 0.3) * 0.125, 0.0125); // Command Block
					if (mat == 61) return vec4(vec3(3.0, 0.9, 0.2) * 0.125, 0.0125); // Warped Fungus, Crimson Fungus
				}
			} else {
				if (mat < 68) {
					if (mat == 62) return vec4(vec3(3.5, 0.6, 0.4) * 0.3, 0.05); // Crimson Stem, Crimson Hyphae
					if (mat == 63) return vec4(vec3(0.3, 1.9, 1.5) * 0.3, 0.05); // Warped Stem, Warped Hyphae
					if (mat == 64) return vec4(vec3(1.1, 0.7, 1.1) * 0.45, 0.1); // Structure Block, Jigsaw Block
					if (mat == 65) return vec4(vec3(3.0, 0.9, 0.2) * 0.125, 0.0125); // Weeping Vines Plant
					if (mat == 66) return vec4(redstoneSpecialLightColor * 0.05, 0.002); // Redstone Wire:Lit, Comparator:Unlit:Subtract
					if (mat == 67) return vec4(redstoneSpecialLightColor * 0.125, 0.0125); // Repeater:Lit, Comparator:Lit
				} else {
					if (mat == 68) return vec4(vec3(0.75), 0.0); // Vault:Inactive
					if (mat == 69) return vec4(vec3(1.3, 1.6, 1.6) * 1.0, 0.1); // Trial Spawner:Ominous:Active, Vault:Ominous:Active
					if (mat == 70) return vec4(vec3(1.0, 0.1, 0.1) * candleColorMult, candleExtraLight); // Red Candles:Lit
					if (mat == 71) return vec4(vec3(1.0, 0.4, 0.1) * candleColorMult, candleExtraLight); // Orange Candles:Lit
					if (mat == 72) return vec4(vec3(1.0, 1.0, 0.1) * candleColorMult, candleExtraLight); // Yellow Candles:Lit
					if (mat == 73) return vec4(vec3(0.1, 1.0, 0.1) * candleColorMult, candleExtraLight); // Lime Candles:Lit
				}
			}
		} else {
			if (mat < 86) {
				if (mat < 80) {
					if (mat == 74) return vec4(vec3(0.3, 1.0, 0.3) * candleColorMult, candleExtraLight); // Green Candles:Lit
					if (mat == 75) return vec4(vec3(0.3, 0.8, 1.0) * candleColorMult, candleExtraLight); // Cyan Candles:Lit
					if (mat == 76) return vec4(vec3(0.5, 0.65, 1.0) * candleColorMult, candleExtraLight); // Light Blue Candles:Lit
					if (mat == 77) return vec4(vec3(0.1, 0.15, 1.0) * candleColorMult, candleExtraLight); // Blue Candles:Lit
					if (mat == 78) return vec4(vec3(0.7, 0.3, 1.0) * candleColorMult, candleExtraLight); // Purple Candles:Lit
					if (mat == 79) return vec4(vec3(1.0, 0.1, 1.0) * candleColorMult, candleExtraLight); // Magenta Candles:Lit
				} else {
					if (mat == 80) return vec4(vec3(1.0, 0.4, 1.0) * candleColorMult, candleExtraLight); // Pink Candles:Lit
					if (mat == 81) return vec4(vec3(2.8, 1.1, 0.2) * 0.125, 0.0125); // Open Eyeblossom
					if (mat == 82) return vec4(vec3(2.8, 1.1, 0.2) * 0.3, 0.05); // Creaking Heart: Active
					if (mat == 83) return vec4(0.0);
					if (mat == 84) return vec4(0.0);
					if (mat == 85) return vec4(0.0);
				}
			} else {
				if (mat < 92) {
					if (mat == 86) return vec4(0.0);
					if (mat == 87) return vec4(0.0);
					if (mat == 88) return vec4(0.0);
					if (mat == 89) return vec4(0.0);
					if (mat == 90) return vec4(0.0);
					if (mat == 91) return vec4(0.0);
				} else {
					if (mat == 92) return vec4(0.0);
					if (mat == 93) return vec4(0.0);
					if (mat == 94) return vec4(0.0);
					if (mat == 95) return vec4(0.0);
					if (mat == 96) return vec4(0.0);
					if (mat == 97) return vec4(vec3(1.0, 1.0, 1.0) * 4.0, candleExtraLight); // Modded White Light Source
				}
			}
		}
	}

	return vec4(blocklightCol * 20.0, 0.0);
}

vec3[] specialTintColor = vec3[](
	// 200: White
	vec3(1.0),
	// 201: Orange
	vec3(1.0, 0.3, 0.1),
	// 202: Magenta
	vec3(1.0, 0.1, 1.0),
	// 203: Light Blue
	vec3(0.5, 0.65, 1.0),
	// 204: Yellow
	vec3(1.0, 1.0, 0.1),
	// 205: Lime
	vec3(0.1, 1.0, 0.1),
	// 206: Pink
	vec3(1.0, 0.4, 1.0),
	// 207: Gray
	vec3(1.0),
	// 208: Light Gray
	vec3(1.0),
	// 209: Cyan
	vec3(0.3, 0.8, 1.0),
	// 210: Purple
	vec3(0.7, 0.3, 1.0),
	// 211: Blue
	vec3(0.1, 0.15, 1.0),
	// 212: Brown
	vec3(1.0, 0.75, 0.5),
	// 213: Green
	vec3(0.3, 1.0, 0.3),
	// 214: Red
	vec3(1.0, 0.1, 0.1),
	// 215: Black
	vec3(1.0),
	// 216: Ice
	vec3(0.5, 0.65, 1.0),
	// 217: Glass
	vec3(1.0),
	// 218: Glass Pane
	vec3(1.0),
	// 219++
	vec3(0.0)
);