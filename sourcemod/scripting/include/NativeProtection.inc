// Возвращает состояние игрока в игре - true защищен, false нет
native int SP_GetClientProtectionState(int client);
// Устанавливает/убирает защиту с игрока
native void SP_SetClientProtectionState(int client, bool state, float time = 0.0);


new RenderOffs;

enum Team{
    TeamSpec = 1,
    TeamT,
    TeamCT
};

enum FX
{
	FxNone = 0,
	FxPulseFast,
	FxPulseSlowWide,
	FxPulseFastWide,
	FxFadeSlow,
	FxFadeFast,
	FxSolidSlow,
	FxSolidFast,
	FxStrobeSlow,
	FxStrobeFast,
	FxStrobeFaster,
	FxFlickerSlow,
	FxFlickerFast,
	FxNoDissipation,
	FxDistort,               // Distort/scale/translate flicker
	FxHologram,              // kRenderFxDistort + distance fade
	FxExplode,               // Scale up really big!
	FxGlowShell,             // Glowing Shell
	FxClampMinScale,         // Keep this sprite from getting very small (SPRITES only!)
	FxEnvRain,               // for environmental rendermode, make rain
	FxEnvSnow,               //  "        "            "    , make snow
	FxSpotlight,     
	FxRagdoll,
	FxPulseFastWider,
};

enum Render
{
	Normal = 0, 		// src
	TransColor, 		// c*a+dest*(1-a)
	TransTexture,		// src*a+dest*(1-a)
	Glow,				// src*a+dest -- No Z buffer checks -- Fixed size in screen space
	TransAlpha,			// src*srca+dest*(1-srca)
	TransAdd,			// src*a+dest
	Environmental,		// not drawn, used for environmental effects
	TransAddFrameBlend,	// use a fractional frame value to blend between animation frames
	TransAlphaAdd,		// src + dest*(1-a)
	WorldGlow,			// Same as kRenderGlow but not fixed size in screen space
	None,				// Don't render.
};