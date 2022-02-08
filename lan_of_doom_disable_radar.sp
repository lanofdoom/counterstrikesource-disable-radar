#include <sdkhooks>
#include <sourcemod>

public const Plugin myinfo = {
    name = "Disable Radar", author = "LAN of DOOM",
    description = "Disables radar for all players", version = "1.0.0",
    url = "https://github.com/lanofdoom/counterstrikesource-disable-radar"};

static const float kInfinteTime = 3600.0;
static const float kDisableTime = 0.1;
static const float kFlashReduction = 0.1;
static const float kFlashMaxAlpha = 0.5;

static ConVar g_radar_disabled_cvar;

//
// Logic
//

static void HideRadar(int client) {
  PrintToServer("Hide Radar: %f %f", 
                GetEntPropFloat(client, Prop_Send, "m_flFlashDuration"),
                GetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha"));
  SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", kInfinteTime);
  SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", kFlashMaxAlpha);
}

static void ShowRadar(int client) {
  PrintToServer("Show Radar");
  SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", kDisableTime);
  SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", kFlashMaxAlpha);
}

static Action OnBlindEnd(Handle timer, any userid) {
  if (!GetConVarBool(g_radar_disabled_cvar)) {
    return Plugin_Stop;
  }

  int client = GetClientOfUserId(userid);
  if (!client) {
    return Plugin_Stop;
  }

  HideRadar(client);

  return Plugin_Stop;
}

//
// Hooks
//

static void OnPlayerSpawnPost(int client) {
  if (!GetConVarBool(g_radar_disabled_cvar)) {
    return;
  }

  HideRadar(client);
}

static Action OnPlayerSpawn(int client) {
  OnPlayerSpawnPost(client);
  return Plugin_Continue;
}

static void OnPlayerBlind(Handle event, const char[] name, bool dontBroadcast) {
  if (!GetConVarBool(g_radar_disabled_cvar)) {
    return;
  }

  int userid = GetEventInt(event, "userid");
  if (!userid) {
    return;
  }

  int client = GetClientOfUserId(userid);
  if (!client) {
    return;
  }

  float flash_time = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
  if (flash_time > kFlashReduction) {
    flash_time -= kFlashReduction;
  }

  CreateTimer(flash_time, OnBlindEnd, userid, TIMER_FLAG_NO_MAPCHANGE);
}

static void OnCvarChange(Handle convar, const char[] old_value,
                         const char[] new_value) {
  for (int client = 1; client <= MaxClients; client++) {
    if (!IsClientInGame(client)) {
      continue;
    }

    if (GetConVarBool(convar)) {
      HideRadar(client);
    } else {
      ShowRadar(client);
    }
  }
}

//
// Forwards
//

public void OnClientPutInServer(int client) {
  SDKHook(client, SDKHook_SpawnPost, OnPlayerSpawnPost);
  SDKHook(client, SDKHook_Spawn, OnPlayerSpawn);
}

public void OnPluginStart() {
  g_radar_disabled_cvar = CreateConVar("sm_lanofdoom_radar_disabled", "1",
                                       "If true, player radar is disabled.");

  HookConVarChange(g_radar_disabled_cvar, OnCvarChange);
  HookEvent("player_blind", OnPlayerBlind);

  if (!GetConVarBool(g_radar_disabled_cvar)) {
    return;
  }

  for (int client = 1; client <= MaxClients; client++) {
    if (!IsClientInGame(client)) {
      continue;
    }

    HideRadar(client);
  }
}

public void OnPluginEnd() {
  if (!GetConVarBool(g_radar_disabled_cvar)) {
    return;
  }

  for (int client = 1; client <= MaxClients; client++) {
    if (!IsClientInGame(client)) {
      continue;
    }

    ShowRadar(client);
  }
}