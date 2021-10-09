#include "NativeProtection.inc"
#include "csgo_colors.inc"
#pragma tabsize 0

enum ETeam{
    TeamSpec = 1,
    TeamT,
    TeamCT
}

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

Handle SpawnProtectionTime;
Handle SpawnProtectionNotify;
Handle SpawnProtectionColor;
Handle SpawnModelColoringTeam;

int RenderOffs;
int g_ClientState[MAXPLAYERS];

public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] sError, int iErrmax){
    CreateNative("SP_GetClientProtectionState", Native_GetClientProtectionState);
    CreateNative("SP_SetClientProtectionState", Native_SetClientProtectionState)
    

    RegPluginLibrary("Native_Protection");

    return APLRes_Success;
}
public bool correctPlayer(int client){
    if(client > 0 && client <= MaxClients && IsClientInGame(client))
        return true;
    return false;
}
public int Native_GetClientProtectionState(Handle hPlugin, int iNumParams){
    int client = GetNativeCell(1);
    if(correctPlayer(client)){
        return g_ClientState[client];
    }
    return -1;
}
public int Native_SetClientProtectionState(Handle hPlugin, int iNumParams){
    int client = GetNativeCell(1);
    int state  = GetNativeCell(2);
    float time   = GetNativeCell(3);
    if(correctPlayer(client)) {
        if(state){
            if(!g_ClientState[client]){
                if(time <= 0)
                    SetFailState("Time of protection is smaller or equal 0");
                ApplyProtection(client, time);
            }
        }else{
            if(g_ClientState[client])
                RemoveProtection(client);
        }
    }
}

public void OnClientConnected(client){
    g_ClientState[client] = false;
}
public void OnClientDisconnect(client){
    g_ClientState[client] = false;
}

public Plugin:myinfo = {
    name = "Native Lib for Protection State",
    author = ".KarmA(Based on Fredd's SpawnProtection)",
    description = "",
    version = "1.0",
    url = "https://steamcommunity.com/id/i_t_s_Karma/"
};

public void OnPluginStart(){	
	SpawnProtectionTime			= CreateConVar("prot_spawn_protection_time", "5", "Время защиты при возрождении / Time of spawn protection");
	SpawnProtectionNotify		= CreateConVar("prot_notify", "1", "Включить уведомления для игрока / Notify player about protection");
	SpawnProtectionColor		= CreateConVar("prot_color", "0 255 0 120", "Цвет моделек игрока во воремя защиты / Player`s model color (RGBA)");
    SpawnModelColoringTeam      = CreateConVar("prot_after_coloring_team", "1", "Включить окрашивание игроков по командам / Enable team-color");
	
	AutoExecConfig(true, "native_protection");
	
	RenderOffs					= FindSendPropInfo("CBasePlayer", "m_clrRender");
    
	HookEvent("player_spawn", OnPlayerSpawn);
}

public Action OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client 	= GetClientOfUserId(GetEventInt(event, "userid"));
    float Time = float(GetConVarInt(SpawnProtectionTime));
    if(Time == float(0.0) && Time < float(0.0)) return Plugin_Continue;
    ApplyProtection(client, Time)
    return Plugin_Continue;
}
public bool ApplyProtection(client, float time){
    if(time == float(0.0) && time < float(0.0)) return true;
    int Team = GetClientTeam(client);
    if(IsPlayerAlive(client) && (Team != TeamSpec) && !g_ClientState[client] && correctPlayer(client))
    {
        char SzColor[32];
        
        char SetColors[4][4];
        GetConVarString(SpawnProtectionColor, SzColor, sizeof(SzColor));
        ExplodeString(SzColor, " ", SetColors, 4, 4);
            
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        set_rendering(client, FxDistort, StringToInt(SetColors[0]), StringToInt(SetColors[1]), StringToInt(SetColors[2]), RENDER_TRANSADD, StringToInt(SetColors[3]));
        g_ClientState[client] = true;
        CreateTimer(time, TimerRemoveProtection, client);
        if(GetConVarInt(SpawnProtectionNotify) > 0)
            CPrintToChat(client, "{lightgreen}[KNP Protection] {default} Вы под защитой от урона на {lightgreen}%i {default}секунд", RoundToNearest(time)); 
        g_ClientState[client] = true;
        return true;
    }
    return false;
}
public void RemoveProtection(int client){
    if(correctPlayer(client)){
        SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
        int Color[4] = {255, 255, 255, 255};
        if(GetConVarInt(SpawnModelColoringTeam) > 0){
            switch(GetClientTeam(client)){
                case TeamT:{
                    Color = {255, 0, 0, 255};
                }
                case TeamCT:{
                    Color = {0, 0, 255, 255};
                }
            }
        }
        set_rendering(client, FxDistort, Color[0], Color[1], Color[2], RENDER_TRANSADD, Color[3]);
        if(GetConVarInt(SpawnProtectionNotify) > 0)
            CPrintToChat(client, "{lightgreen}[KNP Protection] {default} Защита урона отключена{lightgreen}..");
    }
    g_ClientState[client] = false;
}
public Action TimerRemoveProtection(Handle:timer, any:client)
{
    if(correctPlayer(client) &&IsPlayerAlive(client) && g_ClientState[client])
        RemoveProtection(client);
}
stock set_rendering(index, FX:fx=FxNone, r=255, g=255, b=255, Render:render=Normal, amount=255)
{
	SetEntProp(index, Prop_Send, "m_nRenderFX", _:fx, 1);
	SetEntProp(index, Prop_Send, "m_nRenderMode", _:render, 1);	
	SetEntData(index, RenderOffs, r, 1, true);
	SetEntData(index, RenderOffs + 1, g, 1, true);
	SetEntData(index, RenderOffs + 2, b, 1, true);
	SetEntData(index, RenderOffs + 3, amount, 1, true);	
}