#pragma semicolon 1

#include <sourcemod>
#include <SteamWorks>
#include <webfix>
#include <multicolors>
#include <autoexecconfig>

#pragma newdecls required

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))

bool g_bStatus[MAXPLAYERS + 1] = { false, ... };

ConVar g_cGroupID = null;
ConVar g_cGroupURL = null;

public Plugin myinfo =
{
    name = "[Outbreak] Group Status",
    author = "Bara",
    description = "",
    version = "1.0.0",
    url = "outbreak.community"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("GroupStatus_IsClientInGroup", Native_InGroup);
    RegPluginLibrary("groupstatus");

    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("groupstatus.phrases");

    RegConsoleCmd("sm_group", Command_Group);
    RegConsoleCmd("sm_join", Command_Group);
    RegConsoleCmd("sm_refresh", Command_Refresh);


    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("plugin.groupstatus");
    g_cGroupID = AutoExecConfig_CreateConVar("groupstatus_id", "", "ID of the group");
    g_cGroupURL = AutoExecConfig_CreateConVar("groupstatus_url", "", "Custom url name of the group");
    g_cFlag = AutoExecConfig_CreateConVar("groupstatus_flag","f","Wich CustomFlag should the client have when joined the group.")
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    AutoExecConfig();

    CreateTimer(30.0, Timer_CheckStatus, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public void OnClientPostAdminCheck(int client)
{
    UpdateGroupStatus(client);
}

public int Native_InGroup(Handle plugin, int numParams)
{
    return g_bStatus[GetNativeCell(1)];
}

public Action Timer_CheckStatus(Handle timer)
{
    LoopClients(client)
    {
        SteamWorks_GetUserGroupStatus(client, g_cGroupID.IntValue);
    }
}

public Action Command_Group(int client, int args)
{
    if (!IsClientValid(client))
    {
        return Plugin_Continue;
    }

    char sURL[128], sName[32];
    g_cGroupURL.GetString(sName, sizeof(sName));
    Format(sURL, sizeof(sURL), "https://steamcommunity.com/groups/%s", sName);
    WebFix_OpenUrl(client, "Easy Web Shortcuts", sURL);

    return Plugin_Continue;
}

public Action Command_Refresh(int client, int args)
{
    if (!IsClientValid(client))
    {
        return Plugin_Continue;
    }

    UpdateGroupStatus(client);

    return Plugin_Continue;
}

bool UpdateGroupStatus(int client)
{
    SteamWorks_GetUserGroupStatus(client, g_cGroupID.IntValue);
}

stock bool IsClientValid(int client, bool bots = false)
{
    if (client > 0 && client <= MaxClients)
    {
        if(IsClientInGame(client) && (bots || !IsFakeClient(client)) && !IsClientSourceTV(client))
        {
            return true;
        }
    }
    
    return false;
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupid, bool isMember, bool isOfficer)
{
    int client = GetUserAuthID(authid);

    if (!IsClientValid(client))
    {
        return;
    }

    if (groupid == g_cGroupID.IntValue && (isMember || isOfficer) && !g_bStatus[client])
    {
        g_bStatus[client] = true;
        CPrintToChat(client, "%T", "In Group: Yes", client);
        AddUserFlags(client, g_cFlag);
    }
    else if (g_bStatus[client] && !isMember && !isOfficer)
    {
        g_bStatus[client] = false;
        CPrintToChat(client, "%T", "In Group: No", client);
    }
}

int GetUserAuthID(int authid)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientValid(i))
        {
            char[] charauth = new char[64];
            char[] authchar = new char[64];
            GetClientAuthId(i, AuthId_Steam3, charauth, 64);
            IntToString(authid, authchar, 64);
            if (StrContains(charauth, authchar) != -1)
            {
                return i;
            }
        }
    }

    return -1;
}
