int                     hBeam = -1; 
int	    BORDER_COLOR[]	= {127, 31, 1, 255};

void MakeAFrame(int client, int fStart[3], int fEnd[3], float fTime){
        int tP[3], tD[3];
        tP = fStart;
        tD[0] = fEnd[0];
        tD[1] = fStart[1];
        tD[2] = fStart[2];
        TE_CreateBeam(client, tP, tD, fTime); 

        tP = tD;
        tD[0] = fEnd[0];
        tD[1] = fStart[1];
        tD[2] = fEnd[2];
        TE_CreateBeam(client, tP, tD, fTime);

        tP = tD;
        tD[0] = fEnd[0];
        tD[1] = fEnd[1];
        tD[2] = fEnd[2];
        TE_CreateBeam(client, tP, tD, fTime);

        tP = tD;
        tD[0] = fStart[0];
        tD[1] = fEnd[1];
        tD[2] = fEnd[2];
        TE_CreateBeam(client, tP, tD, fTime); 

        tP = tD;
        tD[0] = fStart[0];
        tD[1] = fEnd[1];
        tD[2] = fStart[2];
        TE_CreateBeam(client, tP, tD, fTime); 

        tP = tD;
        tD[0] = fStart[0];
        tD[1] = fStart[1];
        tD[2] = fStart[2];
        TE_CreateBeam(client, tP, tD, fTime); 

        tP = tD;
        tD[0] = fStart[0];
        tD[1] = fStart[1];
        tD[2] = fEnd[2];
        TE_CreateBeam(client, tP, tD, fTime); 


        tP = tD;
        tD[0] = fStart[0];
        tD[1] = fEnd[1];
        tD[2] = fEnd[2];
        TE_CreateBeam(client, tP, tD, fTime);
    
        

        tP[0] = fStart[0];
        tP[1] = fStart[1];
        tP[2] = fEnd[2];
        tD[0] = fEnd[0];
        tD[1] = fStart[1];
        tD[2] = fEnd[2];
        TE_CreateBeam(client, tP, tD, fTime);
    
        

        tP[0] = fEnd[0];
        tP[1] = fEnd[1];
        tP[2] = fEnd[2];
        tD[0] = fEnd[0];
        tD[1] = fEnd[1];
        tD[2] = fStart[2];
        TE_CreateBeam(client, tP, tD, fTime); 
 

        tP = tD;
        tD[0] = fStart[0];
        tD[1] = fEnd[1];
        tD[2] = fStart[2]
        TE_CreateBeam(client, tP, tD, fTime); 
      

        tP[0] = fEnd[0];
        tP[1] = fEnd[1];
        tP[2] = fStart[2];
        tD[0] = fEnd[0];
        tD[1] = fStart[1];
        tD[2] = fStart[2];
        TE_CreateBeam(client, tP, tD, fTime);  

        //LogMessage("Created for %f", fTime)
}
int Abs(int i){if(i < 0)return i * -1;return i;}
void TE_CreateBeam(int client, int origin[3], int destination[3], float time){
    if(CorrectPlayer(client) && IsPlayerAlive(client)){
        float fO[3],fD[3];

        fO[0] = float(origin[0]);
        fO[1] = float(origin[1]);
        fO[2] = float(origin[2]);

        fD[0] = float(destination[0]);
        fD[1] = float(destination[1]);
        fD[2] = float(destination[2]);
        TE_SetupBeamPoints(fO, fD, hBeam, 0, 0, 0, time, 3.0, 3.0, 1, 0.0, BORDER_COLOR, 0);
        TE_SendToClient(client);
    }
}
void PreCache(){
    if(!PrecacheModel("models/error.mdl", true)){
        SetFailState("Error.mdl not found");
        return;
    }
    if(!PrecacheModel("models/odessa.mdl", true)){
        SetFailState("odessa.mdl not found");
        return;
    }

    Handle hGameConfig = LoadGameConfigFile("funcommands.games");
	if (!hGameConfig)
	{
		SetFailState("Unable to load game config funcommands.games from stock sourcemod plugin for beam materials.");
		return;
	}
    char buffer[PLATFORM_MAX_PATH];
	Handle cfg = LoadGameConfigFile("funcommands.games");
	if(cfg == null) SetFailState("Unable to load game config 'funcommands.games'!");
	if(GameConfGetKeyValue(cfg, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0]) hBeam = PrecacheModel(buffer, true);
	CloseHandle(cfg);
}
int MakeATrigger(int fStart[3], int fEnd[3], EntityOutput clb_on, EntityOutput clb_out){
    float vMin[3];
    float vMax[3];
    float vCentre[3];

    int w, h, d;

    w = (fEnd[0]) - (fStart[0]);
    h = (fEnd[1] - fStart[1]);
    d = (fEnd[2] - fStart[2]);

    // Высчитывается центр триггера
    w /= 2;
    h /= 2;
    d /= 2;

    // vMin и vMax
    vMin[0] = float(-(Abs(w)));
    vMin[1] = float(-(Abs(h)));
    vMin[2] = float(-(Abs(d)));

    vMax[0] = float(Abs(w));
    vMax[1] = float(Abs(h));
    vMax[2] = float(Abs(d));

    int x, y, z;

    x = fEnd[0] - (w);
    y = fEnd[1] - (h);
    z = fEnd[2] - (d);

    vCentre[0] = float(x);
    vCentre[1] = float(y);
    vCentre[2] = float(z);

    /*LogMessage("vCentre %f %f %f", vCentre[0] , vCentre[1], vCentre[2]);
    LogMessage("vMin =  %f %f %f", vMin[0], vMin[1], vMin[2]);
    LogMessage("vMax =  %f %f %f", vMax[0], vMax[1], vMax[2]);*/
 
    int ent = CreateEntityByName("trigger_multiple");
    DispatchKeyValue(ent, "spawnflags", "1");
    DispatchKeyValue(ent, "wait", "0");
    DispatchSpawn(ent);
    ActivateEntity(ent);
    TeleportEntity(ent, vCentre, NULL_VECTOR, NULL_VECTOR); // Тут указывай место положение зоны.
    SetEntityModel(ent, "models/error.mdl");
    SetEntPropVector(ent, Prop_Send, "m_vecMins", vMin); // Тут укажи размер минимального значения.
    SetEntPropVector(ent, Prop_Send, "m_vecMaxs", vMax); // Тут укажи размер максимального значения.
    SetEntProp(ent, Prop_Send, "m_nSolidType", 2);
            
    HookSingleEntityOutput(ent, "OnStartTouch", clb_on);
    HookSingleEntityOutput(ent, "OnEndTouch", clb_out);

    return ent;
}