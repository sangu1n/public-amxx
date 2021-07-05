#pragma semicolon 1
#pragma ctrlchar '\'

#include <amxmodx>
#include <cstrike>
#include <fakemeta>

#define OFFSET_MENU	205


public plugin_init() 
{
  register_plugin("MIX TEAM FIX", "1.0", "senoramxx");
	register_clcmd("joinclass", "clcmd_joinclass");
	register_clcmd("menuselect", "clcmd_menuselect");
}

public clcmd_joinclass(id)
{
	new CsTeams:teamId = cs_get_user_team(id);
	if(teamId != CS_TEAM_T && teamId != CS_TEAM_CT)	return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public clcmd_menuselect(id)
{
	new iMenu = get_pdata_int(id, OFFSET_MENU);
	if(iMenu == 3)
	{
		new CsTeams:teamId = cs_get_user_team(id);
		if(teamId != CS_TEAM_T && teamId != CS_TEAM_CT)	set_pdata_int(id, OFFSET_MENU, 0);	return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
