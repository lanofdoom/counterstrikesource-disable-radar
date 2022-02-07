#include <sourcemod>

public const Plugin myinfo = {
    name = "Disable Radar", author = "LAN of DOOM",
    description = "Disables radar for all players", version = "1.0.0",
    url = "https://github.com/lanofdoom/counterstrikesource-disable-radar"};

static const float kInfinteTime = 3600.0;
static const float kDisableTime = 0.1;
static const float kFlashReduction = 0.1;
static const float kFlashMaxAlpha = 0.5;

static ConVar g_friendlyfire_cvar;

//
// Logic
//

static void HideRadar(int client) {
  SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", kInfinteTime);
  SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", kFlashMaxAlpha);
}

static void ShowRadar(int client) {
  SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", kDisableTime);
  SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", kFlashMaxAlpha);
}

static Action OnBlindEnd(Handle timer, any userid) {
  if (!GetConVarBool(g_friendlyfire_cvar)) {
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

static Action OnPlayerSpawn(Handle event, const char[] name,
                            bool dontBroadcast) {
  if (!GetConVarBool(g_friendlyfire_cvar)) {
    return Plugin_Continue;
  }

  int userid = GetEventInt(event, "userid");
  if (!userid) {
    return Plugin_Continue;
  }

  int client = GetClientOfUserId(userid);
  if (!client) {
    return Plugin_Continue;
  }

  HideRadar(client);

  return Plugin_Continue;
}

static void OnPlayerBlind(Handle event, const char[] name, bool dontBroadcast) {
  if (!GetConVarBool(g_friendlyfire_cvar)) {
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

public void OnPluginStart() {
  g_friendlyfire_cvar = FindConVar("mp_friendlyfire");

  if (!g_friendlyfire_cvar) {
    ThrowError("Initialization failed");
  }

  HookConVarChange(g_friendlyfire_cvar, OnCvarChange);
  HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
  HookEvent("player_blind", OnPlayerBlind);

  if (!GetConVarBool(g_friendlyfire_cvar)) {
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
  if (!GetConVarBool(g_friendlyfire_cvar)) {
    return;
  }

  for (int client = 1; client <= MaxClients; client++) {
    if (!IsClientInGame(client)) {
      continue;
    }

    ShowRadar(client);
  }
}