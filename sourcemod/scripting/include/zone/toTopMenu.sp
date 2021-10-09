#include <sourcemod>
#include <adminmenu>
#include "csgo_colors.inc"
#pragma tabsize 0
#define FLAG ADMFLAG_ROOT
#define HALF_Hight 25

TopMenu g_hTopMenu = null;
Menu    hCreateZone, hDeleteZone;
KeyValues kv;


/*
    Нельзя одновременно редактировать зоны(?)
*/

enum{
    ED_SET_A,
    ED_SET_B,
    ED_EMPTY,
    ED_SAVE,
    ED_SAVEZONE
};
enum{
    ED_START,
    ED_END
}
int g_EDITOR_fStart[3];
int g_EDITOR_fEnd[3];
int g_EDITOR;
bool g_EDITOR_WAITING_FOR_NAME = false;
char g_EDITOR_ZoneName[16];
public void PreCacheMenu(){
    hCreateZone = new Menu(Handler_ZoneCreate);
    hCreateZone.SetTitle("Добавить зону");
    hCreateZone.AddItem("fStart", "Установить точку А");
    hCreateZone.AddItem("fEnd", "Установить точку Б");
    hCreateZone.AddItem("ghost", "-----------------", ITEMDRAW_DISABLED);
    hCreateZone.AddItem("aOk", "Сохранить");

    hDeleteZone = new Menu(Handler_ZoneDelete);
    hDeleteZone.SetTitle("Удалить зону");
}

public void OnAdminMenuReady(Handle aTopMenu){
    TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);
    if(hTopMenu == g_hTopMenu)
        return;
    g_hTopMenu = hTopMenu;
    
    TopMenuObject hZoneCotrol = g_hTopMenu.AddCategory("zone_admin_category", Handler_ZNAdmin, "zone", FLAG);

    hZoneCotrol = g_hTopMenu.FindCategory("zone_admin_category");

    if(hZoneCotrol != INVALID_TOPMENUOBJECT){
        g_hTopMenu.AddItem("zone_admin_show", Handler_ZoneShow, hZoneCotrol, "zone_show", FLAG);
        g_hTopMenu.AddItem("zone_admin_create", Handler_CreateZone, hZoneCotrol, "zone_create", FLAG);
        g_hTopMenu.AddItem("zone_admin_reload", Handler_RefreshZone, hZoneCotrol, "zone_reload", FLAG);
        g_hTopMenu.AddItem("zone_admin_delete", Handler_DeleteZone, hZoneCotrol, "zone_delete", FLAG);
    }
}
public Action OnClientSayCommand(client, const char[] command, const char[] sArgs)
{
    if(CorrectPlayer(client) && IsPlayerAlive(client))
    {
        char sText[16];
        strcopy(sText, sizeof(sText), sArgs);
        TrimString(sText);
        StripQuotes(sText);
        if(g_EDITOR_WAITING_FOR_NAME && client == g_EDITOR){
            g_EDITOR_ZoneName = sText;
            Handler_EditorCore(client, ED_SAVEZONE);
        }
    }
}
public void Handler_ZNAdmin(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int len){
    switch(action){
        case TopMenuAction_DisplayOption:{
            FormatEx(sBuffer, len, "Управление зонами");
        }
        case TopMenuAction_DisplayTitle:{
            FormatEx(sBuffer, len, "Выберите действие");
        }
    }
}

public void Handler_ZoneShow(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int len){
    switch(action){
        case TopMenuAction_DisplayOption:{
            FormatEx(sBuffer, len, "Показать зоны (10 сек)");
        }
        case TopMenuAction_SelectOption:{
            CPrintToChat(iClient, "{lightgreen}[KA Zone] {default}Показать границы тригерров на {green}10 секунд");
            ZN_ShowAllTriggers(iClient, 10);
        }
    }
}
public void Handler_DeleteZone(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int len){
    switch(action){
        case TopMenuAction_DisplayOption:{
            FormatEx(sBuffer, len, "Удалить зону");
        }
        case TopMenuAction_SelectOption:{
            hDeleteZone.RemoveAllItems();
            char sItemName[32], sZoneName[16];
            for(int i = 0; i < GetArraySize(g_AL_ZoneList); i++){
                GetArrayString(g_AL_ZoneName, i, sZoneName, sizeof(sZoneName))
                FormatEx(sItemName, sizeof(sItemName), "#%i - %s", i, sZoneName);
                hDeleteZone.AddItem("item", sItemName);
            }
            hDeleteZone.DisplayAt(iClient, 0, 20);
        }
    }
}

public void Handler_RefreshZone(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int len){
    switch(action){
        case TopMenuAction_DisplayOption:{
            FormatEx(sBuffer, len, "Перезагрузить зоны");
        }
        case TopMenuAction_SelectOption:{
            for(int i = 0; i < GetArraySize(g_AL_ZoneList); i++){
                int ent = GetArrayCell(g_AL_ZoneList, i, 7);
                if(!IsValidEntity(ent))
                    LogMessage("Invalid entity for delete %i", ent);
                else
                    RemoveEntity(ent);
            }
            ResizeArray(g_AL_ZoneList, 0);
            ResizeArray(g_AL_ZoneName, 0);
            PreCache();
            LoadConfig();

            if(GetArraySize(g_AL_ZoneList) != GetArraySize(g_AL_ZoneName)){
                SetFailState("Size ZoneList is not equal ZoneName")
                return;
            }
            int fStart[3], fEnd[3];
            for(int i = 0; i < GetArraySize(g_AL_ZoneList); i++){
                GetTriggerPointsByID(i, fStart, fEnd);
                SetArrayCell(g_AL_ZoneList, i, MakeATrigger(fStart, fEnd, clb_trigger_on, clb_trigger_off), 7);
            }
            CPrintToChat(iClient, "{lightgreen}[KA Zone] {default} Зоны обновлены");
        }
    }
}
public void Handler_CreateZone(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int len){
    switch(action){
        case TopMenuAction_DisplayOption:{
            FormatEx(sBuffer, len, "Создать новую зону");
        }
        case TopMenuAction_SelectOption:{
            g_EDITOR_fEnd = {0, 0, 0};
            g_EDITOR_fStart = {0, 0, 0};
            Handler_EditorToClient(iClient, ED_START);
            hCreateZone.DisplayAt(iClient, 0, 20)
        }
    }
}
public int Handler_ZoneCreate(Menu hMenu, MenuAction action, int iClient, int iItem){
    switch(action){
        case MenuAction_Cancel:{
            Handler_EditorToClient(iClient, ED_END);
        }
        case MenuAction_End:{
            Handler_EditorToClient(iClient, ED_END);
        }
        case MenuAction_Select:{
            Handler_EditorCore(iClient, iItem);
            if(iItem != ED_SAVE)
                hMenu.DisplayAt(iClient, 0, 20);
            else    
                if((g_EDITOR_fStart[0] == 0 && g_EDITOR_fStart[1] == 0 && g_EDITOR_fStart[2] == 0) || (g_EDITOR_fEnd[0] == 0 && g_EDITOR_fEnd[1] == 0 && g_EDITOR_fEnd[2] == 0))
                    hMenu.DisplayAt(iClient, 0, 20);
        }
    }
}
public int Handler_ZoneDelete(Menu hMenu, MenuAction action, int iClient, int iItem){
    switch(action){
        case MenuAction_Select:{
            int ent = GetArrayCell(g_AL_ZoneList, iItem, 7);

            char sZoneName[16], sMapName[32];
            GetArrayString(g_AL_ZoneName, iItem, sZoneName, sizeof(sZoneName));
            kv.Rewind();
            GetCurrentMap(sMapName, sizeof(sMapName));
            if(!kv.JumpToKey(sMapName)){
                LogMessage("Could not jump into map-key");
            }
            kv.DeleteKey(sZoneName);
            kv.Rewind();
            kv.ExportToFile(sPath);
            if(!kv.JumpToKey(sMapName))
                SetFailState("Could not jump to current map Key");

            
            RemoveFromArray(g_AL_ZoneList, iItem);
            RemoveFromArray(g_AL_ZoneName, iItem);
            if(!IsValidEntity(ent))
                LogMessage("Invalid entity for delete %i", ent);
            else
                RemoveEntity(ent);
            CPrintToChat(iClient, "{lightgreen}[KA Zone] {default} Зона {red}%s{default} удалена", sZoneName);
        }
    }
}
public void Handler_EditorToClient(int iClient, int flag){
    if(!CorrectPlayer(iClient) || !IsPlayerAlive(iClient))
        return;
    g_EDITOR_ZoneName = "";
    switch(flag){
        case ED_START:{
            g_EDITOR = iClient;
            CPrintToChat(iClient, "{lightgreen}[KA Zone] {default}Редактор зон {green}включен");
        }
        case ED_END:{
            g_EDITOR = -1;
            g_EDITOR_fEnd = {0.0, 0.0, 0.0};
            g_EDITOR_fStart = {0.0, 0.0, 0.0};
            g_EDITOR_ZoneName = "";
            CPrintToChat(iClient, "{lightgreen}[KA Zone] {default}Редактор зон {green}выключен"); 
        }
    }
}
public void Handler_EditorCore(int iClient, int iItem){
    if(!CorrectPlayer(iClient) || !IsPlayerAlive(iClient))
            return;   
    float fTemp[3];
    switch(iItem){
        case ED_SET_A:{
            GetClientAbsOrigin(iClient, fTemp);
            g_EDITOR_fStart[0] = RoundToFloor(fTemp[0]);
            g_EDITOR_fStart[1] = RoundToFloor(fTemp[1]);
            g_EDITOR_fStart[2] = RoundToFloor(fTemp[2]) - HALF_Hight;
            
            CPrintToChat(iClient, "{lightgreen}[KA Zone] {default}Точка А установлена {green}[%i, %i, %i]", g_EDITOR_fStart[0], g_EDITOR_fStart[1], g_EDITOR_fStart[2]);
            CreateTimer(0.1, Handle_RedrawGrid, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
        case ED_SET_B:{
            GetClientAbsOrigin(iClient, fTemp);
            g_EDITOR_fEnd[0] = RoundToFloor(fTemp[0]);
            g_EDITOR_fEnd[1] = RoundToFloor(fTemp[1]);
            g_EDITOR_fEnd[2] = RoundToFloor(fTemp[2]) - HALF_Hight;
            
            CPrintToChat(iClient, "{lightgreen}[KA Zone] {default}Точка Б установлена {green}[%i, %i, %i]", g_EDITOR_fEnd[0], g_EDITOR_fEnd[1], g_EDITOR_fEnd[2]);
        }
        case ED_SAVE:{
            if( (g_EDITOR_fStart[0] == 0 && g_EDITOR_fStart[1] == 0 && g_EDITOR_fStart[2] == 0) || (g_EDITOR_fEnd[0] == 0 && g_EDITOR_fEnd[1] == 0 && g_EDITOR_fEnd[2] == 0))
            {
                CPrintToChat(iClient, "{lightgreen}[KA Zone] {default} Выберите точки А и Б");
                return;
            }
            CPrintToChat(iClient, "{lightgreen}[KA Zone] {default}Введите новое имя для зоны(макс. 16 симв): ");
            g_EDITOR_WAITING_FOR_NAME = 1;
            g_EDITOR_ZoneName = "";
        }
        case ED_SAVEZONE:{
            if(!g_EDITOR_WAITING_FOR_NAME || StrEqual(g_EDITOR_ZoneName, ""))
                CPrintToChat(iClient, "{lightgreen}[KA Zone] Имя зоны {default} {red} пустое");
            g_EDITOR_WAITING_FOR_NAME = false;
            SaveZone();
        }
    }
}
public Action Handle_RedrawGrid(Handle timer){
    int old[4];
    old[0] = BORDER_COLOR[0];
    old[1] = BORDER_COLOR[1];
    old[2] = BORDER_COLOR[2];
    old[3] = BORDER_COLOR[3];
    if((g_EDITOR_fEnd[0] == 0 && g_EDITOR_fEnd[1] == 0 && g_EDITOR_fEnd[2] == 0) && (g_EDITOR_fStart[0] != 0 && g_EDITOR_fStart[1] != 0 && g_EDITOR_fStart[2] != 0) && g_EDITOR != -1)
    {
        
        BORDER_COLOR = {255, 0, 0, 255};

        float pos[3];
        GetClientAbsOrigin(g_EDITOR, pos);
        int iPos[3];
        iPos[0] = RoundToFloor(pos[0]);
        iPos[1] = RoundToFloor(pos[1]);
        iPos[2] = RoundToFloor(pos[2]) - HALF_Hight;
        MakeAFrame(g_EDITOR, g_EDITOR_fStart, iPos, 0.1);

        BORDER_COLOR[0] = old[0];
        BORDER_COLOR[1] = old[1];
        BORDER_COLOR[2] = old[2];
        BORDER_COLOR[3] = old[3];
    }
    else{
        BORDER_COLOR[0] = old[0];
        BORDER_COLOR[1] = old[1];
        BORDER_COLOR[2] = old[2];
        BORDER_COLOR[3] = old[3];

        return Plugin_Stop;
    }
    return Plugin_Continue;

}
public void SaveZone(){
    char szMap[32];
    GetCurrentMap(szMap, sizeof(szMap));

    kv.Rewind();
    kv.JumpToKey(szMap, true);
    kv.JumpToKey(g_EDITOR_ZoneName, true);

    float fStart[3], fEnd[3];
    fStart[0] = float(g_EDITOR_fStart[0])
    fStart[1] = float(g_EDITOR_fStart[1])
    fStart[2] = float(g_EDITOR_fStart[2])

    fEnd[0] = float(g_EDITOR_fEnd[0])
    fEnd[1] = float(g_EDITOR_fEnd[1])
    fEnd[2] = float(g_EDITOR_fEnd[2])

    kv.SetVector("start", fStart);
    kv.SetVector("end", fEnd);
    kv.SetString("time", "10");
    kv.Rewind();
    kv.ExportToFile(sPath);
    
    if(!kv.JumpToKey(szMap))
        SetFailState("Could not jump to current map Key");
    
    int iMerge[ZONELIST_CELL_SIZE];
    iMerge[0] = RoundToZero(fStart[0]);
    iMerge[1] = RoundToZero(fStart[1]);
    iMerge[2] = RoundToZero(fStart[2]);
    iMerge[3] = RoundToZero(fEnd[0]);
    iMerge[4] = RoundToZero(fEnd[1]);
    iMerge[5] = RoundToZero(fEnd[2]);
    
    iMerge[6] = 0; 
    iMerge[7] = -1; // Reserved Ent id

    int iZoneID = PushArrayArray(g_AL_ZoneList, iMerge);
    if(iZoneID != PushArrayString(g_AL_ZoneName, g_EDITOR_ZoneName)){
        SetFailState("ZoneID is not Equal with ZoneNameID");
        return;
    }

    
    CPrintToChat(g_EDITOR, "{lightgreen}[KA Zone] зона {red}%s{lightgreen} сохранена. Изменения применяться в следующем раунде", g_EDITOR_ZoneName);

    g_EDITOR_fStart = {0, 0, 0};
    g_EDITOR_fEnd   = {0, 0, 0};
    g_EDITOR_WAITING_FOR_NAME = false;
    g_EDITOR = -1;
}