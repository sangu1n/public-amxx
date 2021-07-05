#include <amxmodx>
#include <fun>
#include <cstrike>
#include <amxmisc>


#define ACCESS ADMIN_KICK

#define CHAT_PREFIX "^4[^3LALEAGANE.RO^4]^1"

#define TASKID 969696

#define VAR_SIZE 33

enum _: PlayerData
{
	szNamePlayer[VAR_SIZE],
	szNameAdmin[VAR_SIZE],
	szSteamID[32],
	szIP[30]
}

new g_ePlayerData[MAX_PLAYERS + 1][PlayerData]
new cvar_max_ss, cvar_green_ss_start, cvar_drop_ban_time
new iSS, iMaxSS
new copy_arg
new FadeMSG
new bool: is_SSed[33]

public plugin_init()
{
	register_plugin("SS Laleagane", "1.0", "SenorAMXX")
	register_concmd("amx_ss", "screenShotMain", ACCESS, "<nume> - faci poze unui jucator")

	cvar_max_ss = register_cvar("max_ss", "10")
	cvar_green_ss_start = register_cvar("green_start", "6")
	cvar_drop_ban_time = register_cvar("durata_ban_drop_ss", "0") 

	/*
	* cvar_green_ss_start inseamna de la a cata poza sa inceapa cele verzi ! Adica daca ai setat "cvar_max_ss" pe 5 si "cvar_green_ss_start" pe 2 , atunci de la al doilea ss pana la al 5-lea vor fi verzi
	*/
	
	FadeMSG = get_user_msgid("ScreenFade")


}
public client_connect(id) is_SSed[id] = false

public client_disconnected(id)
{
	get_user_name(copy_arg, g_ePlayerData[copy_arg][szNamePlayer], charsmax(g_ePlayerData[][szNamePlayer]))
	get_user_ip(copy_arg, g_ePlayerData[copy_arg][szIP], charsmax(g_ePlayerData[][szIP]), 1)
	get_user_authid(copy_arg,  g_ePlayerData[copy_arg][szSteamID], charsmax(g_ePlayerData[][szSteamID]))

	new ip = g_ePlayerData[copy_arg][szIP]

	new ban_time = get_pcvar_num(cvar_drop_ban_time)

	if(is_SSed[copy_arg])
	{
		colorx(0, "%s %s (^3%s ^4| ^3%s^1) a dat drop cand i s-au cerut poze si a primit ban ^3%d ^1minute !",CHAT_PREFIX, g_ePlayerData[copy_arg][szNamePlayer], g_ePlayerData[copy_arg][szIP], g_ePlayerData[copy_arg][szSteamID], ban_time)
		server_cmd("addip %d %s;wait;writeip",ban_time,ip)
	}
	is_SSed[copy_arg] = false
}

public screenShotMain(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED

	new szArg[VAR_SIZE]
	read_argv(1, szArg, charsmax(szArg))
	

	new iPlayer = cmd_target(id, szArg, 4)

	if(!iPlayer) return PLUGIN_HANDLED

	if(!is_user_alive(iPlayer)
	||is_user_bot(iPlayer)
	||is_user_hltv(iPlayer)) return PLUGIN_HANDLED

	iSS = 0
	iMaxSS = get_pcvar_num(cvar_max_ss)

	get_user_name(iPlayer, g_ePlayerData[iPlayer][szNamePlayer], charsmax(g_ePlayerData[][szNamePlayer]))
	get_user_authid(iPlayer,  g_ePlayerData[iPlayer][szSteamID], charsmax(g_ePlayerData[][szSteamID]))
	get_user_ip(iPlayer, g_ePlayerData[iPlayer][szIP], charsmax(g_ePlayerData[][szIP]), 1)

	colorx(id,"%s I-ai facut ^4%d ^1poze lui [^3%s / %s / %s^1]", CHAT_PREFIX, iMaxSS, g_ePlayerData[iPlayer][szNamePlayer],g_ePlayerData[iPlayer][szSteamID],g_ePlayerData[iPlayer][szIP])

	for(new spam = 0; spam < 3; spam++)	client_cmd(id,"say_team @ I-am facut poze lui %s", g_ePlayerData[iPlayer][szNamePlayer])

	is_SSed[iPlayer] = true

	new szHostName[64], szGetTime[32]

	get_user_name(id, g_ePlayerData[id][szNameAdmin], charsmax(g_ePlayerData[][szNameAdmin]))
	get_cvar_string("hostname", szHostName, charsmax(szHostName))
	get_time("%d/%m/%Y - %H:%M:%S", szGetTime, charsmax(szGetTime))

	client_print(iPlayer, print_center, "[STAMPILA 1]^r** [POZA : #%d] **", iSS + 1)

	colorx(iPlayer, "^1----------------------[^3LALEAGANE^1]----------------------")
	colorx(iPlayer, "^3[*]^1 ADMIN NAME : ^3%s", g_ePlayerData[iPlayer][szNameAdmin])
	colorx(iPlayer, "^3[*]^1 YOUR STATS : ^3%s ^4&^3 %s ^4&^3 %s", g_ePlayerData[iPlayer][szNamePlayer], g_ePlayerData[iPlayer][szSteamID],g_ePlayerData[iPlayer][szIP])
	colorx(iPlayer, "^3[*]^1 TIME STAMP : ^3%s", szGetTime)
	colorx(iPlayer, "^1----------------------[^3LALEAGANE^1]----------------------")

	client_cmd(iPlayer, "snapshot")

	copy_arg = iPlayer

	iSS++
	set_task(1.0, "special_ss", TASKID, _, _, "b")
	return PLUGIN_HANDLED

}

public special_ss(id)
{
	new green = get_pcvar_num(cvar_green_ss_start)
	if(iSS < iMaxSS)
	{
		if(iSS >= green)
		{
			message_begin(MSG_ONE, FadeMSG, {0,0,0}, copy_arg)
			write_short(14<<7)
			write_short(58<<6)
			write_short(1<<0)
			write_byte(5)
			write_byte(255)
			write_byte(0)
			write_byte(255)
			message_end()
		}

		new szGetTime[32]
		get_time("%d/%m/%Y - %H:%M:%S", szGetTime, charsmax(szGetTime))

		client_print(copy_arg, print_center, "[STAMPILA 2]^r** [POZA : #%d] **", iSS + 1)

		colorx(copy_arg, "^1----------------------[^3LALEAGANE^1]----------------------")
		colorx(copy_arg, "^3[*]^1 YOUR STATS : ^3%s ^4&^3 %s ^4&^3 %s", g_ePlayerData[copy_arg][szNamePlayer], g_ePlayerData[copy_arg][szSteamID],g_ePlayerData[copy_arg][szIP])
		colorx(copy_arg, "^3[*]^1 TIME STAMP : ^3%s", szGetTime)
		colorx(copy_arg, "^1----------------------[^3LALEAGANE^1]----------------------")

		client_cmd(copy_arg, "snapshot")
		iSS++
	}
		
		else
		{
			user_silentkill(copy_arg, 1)
			cs_set_user_team(copy_arg, CS_TEAM_SPECTATOR)
			get_user_name(copy_arg, g_ePlayerData[copy_arg][szNamePlayer], charsmax(g_ePlayerData[][szNamePlayer]))
			
		
			remove_task(TASKID)
			
		}
	return PLUGIN_HANDLED
}
stock colorx( const id, const input[ ], any:... )
{
	new count = 1, players[ 32 ]

	static msg[ 191 ]
	vformat( msg, 190, input, 3 )

	replace_all( msg, 190, "!v", "^4" ) //- verde
	replace_all( msg, 190, "!g", "^1" ) //- galben
	replace_all( msg, 190, "!e", "^3" ) //- echipa
	replace_all( msg, 190, "!n", "^0" ) //- normal

	if( id ) players[ 0 ] = id; else get_players( players, count, "ch" )
	{
		for( new i = 0; i < count; i++ )
		{
			if( is_user_connected( players[ i ] ) )
			{
				message_begin( MSG_ONE_UNRELIABLE, get_user_msgid( "SayText" ), _, players[ i ] )
				write_byte( players[ i ] );
				write_string( msg );
				message_end( );
			}
		}
	}
}

