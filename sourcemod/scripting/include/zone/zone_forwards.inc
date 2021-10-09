enum{
    TRIGGER_IN = 0,
    TRIGGER_OUT
}


forward void ZN_OnTrigger(int iClient, int iEvent, int iID, char[] sName);

native void ZN_ShowTrigger(int iClient, int iID);
native void ZN_ShowAllTriggers(int iClient, int time);
native float ZN_GetZoneFeaturesFloat(int iID, char[] sFName);