#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required
#include <smrpg>

#define UPGRADE_SHORTNAME "Cooperation"
#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "SM:RPG Upgrade > Cooperation ",
	author = "WanekWest",
	description = ".",
	version = PLUGIN_VERSION,
	url = "https://vk.com/wanek_west"
}

ConVar hCvCoopPercentValue, hCvCoopDistance;

float g_hCvCoopPercentValue, g_hCvCoopDistance;

public void OnPluginStart()
{
	LoadTranslations("smrpg_stock_upgrades.phrases");
}

public void OnPluginEnd()
{
	if(SMRPG_UpgradeExists(UPGRADE_SHORTNAME))
		SMRPG_UnregisterUpgradeType(UPGRADE_SHORTNAME);
}

public void OnAllPluginsLoaded()
{
	OnLibraryAdded("smrpg");
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "smrpg"))
	{
		SMRPG_RegisterUpgradeType("Cooperation", UPGRADE_SHORTNAME, "Gain +% bonus exp for their kills/objectives for being close to your teammates.", 10, true, 5, 15, 10);
		SMRPG_SetUpgradeTranslationCallback(UPGRADE_SHORTNAME, SMRPG_TranslateUpgrade);

		hCvCoopPercentValue = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_coop_percent", "0.1", "Percent to give * Level(Min: 0.01, Max: 0.99).", _, true, 0.0);
		hCvCoopPercentValue.AddChangeHook(OnCoopChangePercent);
		g_hCvCoopPercentValue = hCvCoopPercentValue.FloatValue;

		hCvCoopDistance = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_coop_distance", "50.0", "Distance of skill working * Level.", _, true, 0.0);
		hCvCoopDistance.AddChangeHook(OnCoopChangeDistance);
		g_hCvCoopDistance = hCvCoopDistance.FloatValue;
	}
}


public void OnCoopChangePercent(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_hCvCoopPercentValue = hCvar.FloatValue;
}

public void OnCoopChangeDistance(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_hCvCoopDistance = hCvar.FloatValue;
}

public void SMRPG_TranslateUpgrade(int client, const char[] shortname, TranslationType type, char[] translation, int maxlen)
{
	if(type == TranslationType_Name)
		Format(translation, maxlen, "%T", UPGRADE_SHORTNAME, client);
	else if(type == TranslationType_Description)
	{
		char sDescriptionKey[MAX_UPGRADE_SHORTNAME_LENGTH+12] = UPGRADE_SHORTNAME;
		StrCat(sDescriptionKey, sizeof(sDescriptionKey), " description");
		Format(translation, maxlen, "%T", sDescriptionKey, client);
	}
}

public void SMRPG_OnClientExperiencePost(int iClient, int oldexp, int newexp)
{
	if (!SMRPG_IsEnabled())
		return;
		
	if (!SMRPG_IsUpgradeEnabled(UPGRADE_SHORTNAME))
		return;
			
	if (IsFakeClient(iClient) && SMRPG_IgnoreBots())
		return;

	int iClientTeam = GetClientTeam(iClient);

	float iClientPosition[3];
	float jPosition[3];

	GetClientAbsOrigin(iClient, iClientPosition);

	for(int j = 1; j <= MaxClients; ++j)
	{
		if (IsClientConnected(j) && IsClientInGame(j) && !IsClientSourceTV(j) && !IsClientObserver(j) && iClientTeam == GetClientTeam(j))
		{
			int jSkillLevel = SMRPG_GetClientUpgradeLevel(j, UPGRADE_SHORTNAME);
			GetClientAbsOrigin(j, jPosition);

			if (jSkillLevel > 0 && GetVectorDistance(iClientPosition, jPosition, true) <= g_hCvCoopDistance * jSkillLevel) // Проверка дистанции.
			{
				int expToGive = RoundToFloor((newexp - oldexp) * (g_hCvCoopPercentValue * jSkillLevel));
				SMRPG_AddClientExperience(iClient, expToGive, UPGRADE_SHORTNAME, false, -1);
			}
		}
	}
}