#include "NativeProtection.inc"
#include "csgo_colors.inc"
#pragma tabsize 0

Handle SpawnProtectionTime;
Handle SpawnProtectionNotify;
Handle SpawnProtectionColor;
Handle SpawnModelColoringTeam;

int g_ClientState[MAXPLAYERS];

public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] sError, int iErrmax){
    CreateNative("SP_GetClientProtectionState", Native_GetClientProtectionState);
    CreateNative("SP_SetClientProtectionState", Native_SetClientProtectionState)
    

    RegPluginLibrary("Native_Protection");

    return APLRes_Success;
}
public bool correctPlayer(int client){
    if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
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
                ApplyProtection(client, time, true);
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
	SpawnProtectionTime			= CreateConVar("prot_spawn_protection_time", "8", "Время защиты при возрождении / Time of spawn protection");
	SpawnProtectionNotify		= CreateConVar("prot_notify", "1", "Включить уведомления для игрока / Notify player about protection");
	SpawnProtectionColor		= CreateConVar("prot_color", "0 0 0 0", "Цвет моделек игрока во воремя защиты / Player`s model color (RGBA)");
    SpawnModelColoringTeam      = CreateConVar("prot_after_coloring_team", "1", "Включить окрашивание игроков по командам / Enable team-color");
	
	AutoExecConfig(true, "native_protection");
    LoadTranslations("NativeProtection.phrases");
	
	RenderOffs					= FindSendPropInfo("CBasePlayer", "m_clrRender");
    
	HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("round_prestart", OnRoundStart);
}

public Action OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast){
    for(int i = 0; i < MAXPLAYERS; i++){
        g_ClientState[i] = false;
    }
}

public Action OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client 	= GetClientOfUserId(GetEventInt(event, "userid"));
    float Time = float(GetConVarInt(SpawnProtectionTime));
    if(Time == float(0.0) || Time < float(0.0)) {
        RemoveProtection(client);
        return Plugin_Continue;
    }

    ApplyProtection(client, Time, true);
    return Plugin_Continue;
}
public bool ApplyProtection(client, float time, bool isClientVisible){  
    if(time == float(0.0) || time < float(0.0))
         return true;
         
    if(IsPlayerAlive(client) && (GetClientTeam(client) != TeamSpec) && correctPlayer(client) && !g_ClientState[client])
    {
        char SzColor[32];
        char SetColors[4][4];

        GetConVarString(SpawnProtectionColor, SzColor, sizeof(SzColor));
        ExplodeString(SzColor, " ", SetColors, 4, 4);
            
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        set_rendering(client, FxDistort, StringToInt(SetColors[0]), StringToInt(SetColors[1]), StringToInt(SetColors[2]), (isClientVisible) ? Normal : None, StringToInt(SetColors[3]));
 
        CreateTimer(time, TimerRemoveProtection, client);
        if(GetConVarInt(SpawnProtectionNotify) > 0)
            CGOPrintToChat(client, "{LIGHTGREEN}[KNP Protection] %t", "PROTECTION_START", RoundToNearest(time)); 

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
        if(GetConVarInt(SpawnProtectionNotify) > 0 && g_ClientState[client])
            CGOPrintToChat(client, "{LIGHTGREEN}[KNP Protection] %t", "PROTECTION_END");
    }
    g_ClientState[client] = false;
}
public Action TimerRemoveProtection(Handle:timer, any:client)
{
    if(correctPlayer(client) &&IsPlayerAlive(client))
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