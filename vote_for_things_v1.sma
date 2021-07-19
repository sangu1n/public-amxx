#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <fakemeta>

#define IsPlayer(%1) (1 <= %1 <= get_maxplayers())
#define RESPAWN_TIME 2.0
#define VOTE_TIME 10.0

new const TAG[] = "^4[Alandala]^1"

new g_iVotes[32]
new g_voting
new ammo_value, speed_value, jump_value, respawn_value, wallbang_value
new jumpnum[33]
new bool: dojump[33]

enum _: Benefit_Type{	main, ammo, speed, jumps, respawn, wallbang	 }

enum _: PluginCvars
{
	Speed_ValueX, Speed2_ValueX, Speed3_ValueX,
	Jumps_ValueX, Jumps2_ValueX
}

new g_data[PluginCvars]

new g_main_menu, g_ammo_menu, g_speed_menu, g_jumps_menu, g_respawn_menu, g_wallbang_menu
new normalTrace[33], lastTrace[33], weapon, dummy
new bool: g_bIsVotingFor[Benefit_Type]
new bool: g_bCanUsePlugin
new g_VotedFor[Benefit_Type]

enum tip_munitie { AMMO_CLIP, AMMO_BACKPACK }

new const g_iWeaponAmmo[][tip_munitie] =
{
    { 0, 0 },
    { 13, 52 },
    { 0, 0 }, // SCUT
    { 10, 90 },
    { 0, 1} ,
    { 7, 32 },
    { 0, 0 }, // C4
    { 30, 100 },
    { 30, 90 },
    { 0, 1 },
    { 30, 120 },
    { 20, 100 },
    { 25, 100 },
    { 30, 90 },
    { 35, 90 },
    { 25, 90 },
    { 12, 100 },
    { 20, 120 },
    { 10, 30 },
    { 30, 120 },
    { 100, 200 },
    { 8, 32 },
    { 30, 90 },
    { 30, 120 },
    { 20, 90 },
    { 0, 2 },
    { 7, 35 },
    { 30, 90 },
    { 30, 90 },
    { 0, 0 }, // CUTIT 
    { 50, 100 }
}


public plugin_init()
{
	register_plugin("[Alandala] Votes", "1v10", "SenorAMXX aka doza")
	register_clcmd("say /vote", "vote_main_menu")
	register_event("TextMsg", "ev_rr", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
	register_event("CurWeapon", "ev_curweapon", "be", "1=1")
	RegisterHam(Ham_Killed, "player", "ev_kill_detect" , 1)
	register_event("DeathMsg", "ev_deathmsg", "a")
	register_event("ResetHUD","event_resethud","b")
	register_clcmd("fullupdate","cmd_fullupdate")
	register_forward(FM_TraceLine,"fw_traceline")

	g_data[Speed_ValueX] = register_cvar("speed1_value", "300")
	g_data[Speed2_ValueX] = register_cvar("speed2_value", "350")
	g_data[Speed3_ValueX] = register_cvar("Speed3_ValueX", "400")
	g_data[Jumps_ValueX] = register_cvar("jump1_value", "1")
	g_data[Jumps2_ValueX] = register_cvar("jump2_value", "2")

	register_forward(FM_PlayerPostThink,"fw_playerpostthink")
}

public ev_rr()
{
	_reset_votes()

	g_voting = 0
	speed_value = 0
	jump_value = 0
	ammo_value = 0
	respawn_value = 0
	wallbang_value = 0
	g_bIsVotingFor[ammo] = false
	g_bIsVotingFor[speed] = false
	g_bIsVotingFor[jumps] = false
	g_bIsVotingFor[respawn] = false
	g_bIsVotingFor[wallbang] = false
	g_VotedFor[ammo] = 0
	g_VotedFor[speed] = 0
	g_VotedFor[jumps] = 0
	g_VotedFor[respawn] = 0
	g_VotedFor[wallbang] = 0
}

public _reset_votes() arrayset(g_iVotes, 0, sizeof(g_iVotes))

public hide(id) show_menu(id, 0, "^n", 1)

public vote_main_menu(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot in desfasurare.", TAG)
		hide(id)
		return PLUGIN_HANDLED
	}
	_reset_votes()

	new msg[190]

	formatex(msg, charsmax(msg), "[Alandala] Voting Menu^nPlugin made by \rdoza.")
	g_main_menu = menu_create(msg, "vote_main_menu_handler")

	switch(ammo_value)
	{
		case 0:
		{
			if(g_VotedFor[ammo] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for infinite ammo \r[OFF]")
				menu_additem(g_main_menu, msg, "0", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for infinite ammo \r[OFF]")
				menu_additem(g_main_menu, msg, "0", 0)
			}
			
		}
		case 1:
		{
			if(g_VotedFor[ammo] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for infinite ammo \r[ON]")
				menu_additem(g_main_menu, msg, "0", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for infinite ammo \r[ON]")
				menu_additem(g_main_menu, msg, "0", 0)
			}
		}
	}

	switch(speed_value)
	{
		case 0:
		{
			if(g_VotedFor[speed] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for speed \r[OFF]")
				menu_additem(g_main_menu, msg, "1", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for speed \r[OFF]")
				menu_additem(g_main_menu, msg, "1", 0)
			}
			
		}
		case 1:
		{
			if(g_VotedFor[speed] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for speed \r[%d Speed]", get_pcvar_num(g_data[Speed_ValueX]))
				menu_additem(g_main_menu, msg, "1", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for speed \r[%d Speed]", get_pcvar_num(g_data[Speed_ValueX]))
				menu_additem(g_main_menu, msg, "1", 0)
			}
			
		}
		case 2:
		{
			if(g_VotedFor[speed] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for speed \r[%d Speed]", get_pcvar_num(g_data[Speed2_ValueX]))
				menu_additem(g_main_menu, msg, "1", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for speed \r[%d Speed]", get_pcvar_num(g_data[Speed2_ValueX]))
				menu_additem(g_main_menu, msg, "1", 0)
			}
		}
		case 3:
		{
			if(g_VotedFor[speed] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for speed \r[%d Speed]", get_pcvar_num(g_data[Speed3_ValueX]))
				menu_additem(g_main_menu, msg, "1", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for speed \r[%d Speed]", get_pcvar_num(g_data[Speed3_ValueX]))
				menu_additem(g_main_menu, msg, "1", 0)
			}
		}
	}

	switch(jump_value)
	{
		case 0:
		{
			if(g_VotedFor[jumps] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for Extra Jumps \r[NOT VOTED]")
				menu_additem(g_main_menu, msg, "1", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for Extra Jumps")
				menu_additem(g_main_menu, msg, "1", 0)
			}
			
		}
		case 1:
		{
			if(g_VotedFor[jumps] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for Extra Jumps \r[+%d Jump]", get_pcvar_num(g_data[Jumps_ValueX]))
				menu_additem(g_main_menu, msg, "1", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for Extra Jumps \r[+%d Jump]", get_pcvar_num(g_data[Jumps_ValueX]))
				menu_additem(g_main_menu, msg, "1", 0)
			}
			
		}
		case 2:
		{
			if(g_VotedFor[jumps] == 2)
			{ 
				formatex(msg, charsmax(msg), "\dVote for Extra Jumps \r[+%d Jumps]", get_pcvar_num(g_data[Jumps2_ValueX]))
				menu_additem(g_main_menu, msg, "1", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for Extra Jumps \r[+%d Jumps]", get_pcvar_num(g_data[Jumps2_ValueX]))
				menu_additem(g_main_menu, msg, "1", 0)
			}
		}
	}

	switch(respawn_value)
	{
		case 0:
		{
			if(g_VotedFor[respawn] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for respawn \r[OFF]")
				menu_additem(g_main_menu, msg, "3", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for respawn \r[OFF]")
				menu_additem(g_main_menu, msg, "3", 0)
			}
			
		}
		case 1:
		{
			if(g_VotedFor[respawn] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for respawn \r[ON]")
				menu_additem(g_main_menu, msg, "3", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for respawn \r[ON]")
				menu_additem(g_main_menu, msg, "3", 0)
			}
		}
	}

	switch(wallbang_value)
	{
		case 0:
		{
			if(g_VotedFor[wallbang] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for wallbang \r[ON]")
				menu_additem(g_main_menu, msg, "4", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for wallbang \r[ON]")
				menu_additem(g_main_menu, msg, "4", 0)
			}
		}
		case 1:
		{
			if(g_VotedFor[wallbang] == 2)
			{
				formatex(msg, charsmax(msg), "\dVote for wallbang \r[OFF]")
				menu_additem(g_main_menu, msg, "4", ADMIN_RCON)
			}
			else
			{
				formatex(msg, charsmax(msg), "Vote for wallbang \r[OFF]")
				menu_additem(g_main_menu, msg, "4", 0)
			}
		}
	}

	menu_display(id, g_main_menu, 0)
	return PLUGIN_HANDLED
}

public vote_main_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT || g_voting)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{
		case 0: vote_for_ammo(id)
		case 1: vote_for_speed(id)
		case 2: vote_for_jumps(id)
		case 3: vote_for_respawn(id)
		case 4: vote_for_wallbang(id)
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public vote_for_ammo(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot in desfasurare.", TAG)
		hide(id)
		return PLUGIN_HANDLED
	}

	_reset_votes()
	
	new msg[190]

	formatex(msg, charsmax(msg), "[Alandala] Vote for Infinite Ammo")
	g_ammo_menu = menu_create(msg, "vote_for_ammo_handler")

	formatex(msg, charsmax(msg), "Yes")
	menu_additem(g_ammo_menu, msg, "", 0)

	formatex(msg, charsmax(msg), "No")
	menu_additem(g_ammo_menu, msg, "", 0)

	menu_setprop(g_ammo_menu, MPROP_EXIT, MEXIT_NEVER)

	new iPlayers[32], iNum
	get_players(iPlayers, iNum)

	for(new j; j < iNum; j++)
	{
		menu_display(iPlayers[j], g_ammo_menu, 0)
		g_voting++
	}
	set_task(VOTE_TIME, "display_votes")

	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////

public vote_for_speed(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot in desfasurare.", TAG)
		hide(id)
		return PLUGIN_HANDLED
	}

	_reset_votes()
	
	new msg[190]

	formatex(msg, charsmax(msg), "[Alandala] Vote for Speed")
	g_speed_menu = menu_create(msg, "vote_for_speed_handler")

	formatex(msg, charsmax(msg), "%d Speed", get_pcvar_num(g_data[Speed_ValueX]))
	menu_additem(g_speed_menu, msg, "", 0)

	formatex(msg, charsmax(msg), "%d Speed", get_pcvar_num(g_data[Speed2_ValueX]))
	menu_additem(g_speed_menu, msg, "", 0)

	formatex(msg, charsmax(msg), "%d Speed", get_pcvar_num(g_data[Speed3_ValueX]))
	menu_additem(g_speed_menu, msg, "", 0)

	formatex(msg, charsmax(msg), "Normal Speed")
	menu_additem(g_speed_menu, msg, "", 0)

	menu_setprop(g_speed_menu, MPROP_EXIT, MEXIT_NEVER)

	new iPlayers[32], iNum
	get_players(iPlayers, iNum)

	for(new j; j < iNum; j++)
	{
		menu_display(iPlayers[j], g_speed_menu, 0)
		g_voting++
	}
	
	set_task(VOTE_TIME, "display_votes")

	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////

public vote_for_jumps(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot in desfasurare.", TAG)
		hide(id)
		return PLUGIN_HANDLED
	}

	_reset_votes()
	
	new msg[190]

	formatex(msg, charsmax(msg), "[Alandala] Vote for Jumps")
	g_jumps_menu = menu_create(msg, "vote_for_jumps_handler")

	formatex(msg, charsmax(msg), "%d Extra Jump", get_pcvar_num(g_data[Jumps_ValueX]))
	menu_additem(g_jumps_menu, msg, "", 0)

	formatex(msg, charsmax(msg), "%d Extra Jumps", get_pcvar_num(g_data[Jumps2_ValueX]))
	menu_additem(g_jumps_menu, msg, "", 0)

	formatex(msg, charsmax(msg), "No extra Jumps")
	menu_additem(g_jumps_menu, msg, "", 0)

	menu_setprop(g_jumps_menu, MPROP_EXIT, MEXIT_NEVER)

	new iPlayers[32], iNum
	get_players(iPlayers, iNum)

	for(new j; j < iNum; j++)
	{
		menu_display(iPlayers[j], g_jumps_menu, 0)
		g_voting++
	}
	set_task(VOTE_TIME, "display_votes")

	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////

public vote_for_respawn(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot in desfasurare.", TAG)
		hide(id)
		return PLUGIN_HANDLED
	}
	
	_reset_votes()

	new msg[190]

	formatex(msg, charsmax(msg), "[Alandala] Vote for Respawn")
	g_respawn_menu = menu_create(msg, "vote_for_respawn_handler")

	formatex(msg, charsmax(msg), "Yes")
	menu_additem(g_respawn_menu, msg, "", 0)

	formatex(msg, charsmax(msg), "No")
	menu_additem(g_respawn_menu, msg, "", 0)

	menu_setprop(g_respawn_menu, MPROP_EXIT, MEXIT_NEVER)

	new iPlayers[32], iNum
	get_players(iPlayers, iNum)

	for(new j; j < iNum; j++)
	{
		menu_display(iPlayers[j], g_respawn_menu, 0)
		g_voting++
	}
	set_task(VOTE_TIME, "display_votes")

	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////

public vote_for_wallbang(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot in desfasurare.", TAG)
		hide(id)
		return PLUGIN_HANDLED
	}

	_reset_votes()
	
	new msg[190]

	formatex(msg, charsmax(msg), "[Alandala] Vote for WallBang")
	g_wallbang_menu = menu_create(msg, "vote_for_wallbang_handler")

	formatex(msg, charsmax(msg), "Yes")
	menu_additem(g_wallbang_menu, msg, "", 0)

	formatex(msg, charsmax(msg), "No")
	menu_additem(g_wallbang_menu, msg, "", 0)

	menu_setprop(g_wallbang_menu, MPROP_EXIT, MEXIT_NEVER)

	new iPlayers[32], iNum
	get_players(iPlayers, iNum)

	for(new j; j < iNum; j++)
	{
		menu_display(iPlayers[j], g_wallbang_menu, 0)
		g_voting++
	}
	set_task(VOTE_TIME, "display_votes")

	return PLUGIN_HANDLED
}

////////////////////////////////////////////////////////////////////////////

public vote_for_ammo_handler(id, menu, item)
{
	g_bIsVotingFor[ammo] = true
	g_bIsVotingFor[speed] = false
	g_bIsVotingFor[jumps] = false
	g_bIsVotingFor[wallbang] = false
	g_bIsVotingFor[respawn] = false

	switch(item)
	{
		case 0:	client_print_color(0, 0, "%s %s a votat ^4PENTRU^1 gloante infinite.", TAG, get_name(id))
		case 1:	client_print_color(0, 0, "%s %s a votat ^4CONTRA^1 gloante infinite.", TAG, get_name(id))
	}
	if(is_user_connected(id)) g_iVotes[item]++
	return PLUGIN_HANDLED
}

public vote_for_speed_handler(id, menu, item)
{
	g_bIsVotingFor[ammo] = false
	g_bIsVotingFor[speed] = true
	g_bIsVotingFor[jumps] = false
	g_bIsVotingFor[wallbang] = false
	g_bIsVotingFor[respawn] = false

	switch(item)
	{
		case 0:	client_print_color(0, 0, "%s %s a votat^4 %d^1 viteza.", TAG, get_name(id), get_pcvar_num(g_data[Speed_ValueX]))
		case 1:	client_print_color(0, 0, "%s %s a votat^4 %d^1 viteza.", TAG, get_name(id), get_pcvar_num(g_data[Speed2_ValueX]))
		case 2:	client_print_color(0, 0, "%s %s a votat^4 %d^1 viteza.", TAG, get_name(id), get_pcvar_num(g_data[Speed3_ValueX]))
		case 3:	client_print_color(0, 0, "%s %s a votat viteza normala.", TAG, get_name(id))
	}
	if(is_user_connected(id)) g_iVotes[item]++
	return PLUGIN_HANDLED
}

public vote_for_jumps_handler(id, menu, item)
{
	g_bIsVotingFor[ammo] = false
	g_bIsVotingFor[speed] = false
	g_bIsVotingFor[jumps] = true
	g_bIsVotingFor[wallbang] = false
	g_bIsVotingFor[respawn] = false

	switch(item)
	{
		case 0:	client_print_color(0, 0, "%s %s a votat^4 %d^1 extra jump.", TAG, get_name(id), get_pcvar_num(g_data[Jumps_ValueX]))
		case 1:	client_print_color(0, 0, "%s %s a votat^4 %d^1 extra jumps.", TAG, get_name(id), get_pcvar_num(g_data[Jumps2_ValueX]))
		case 2:	client_print_color(0, 0, "%s %s a votat fara extra jumps.", TAG, get_name(id))
	}
	if(is_user_connected(id)) g_iVotes[item]++
	return PLUGIN_HANDLED
}

public vote_for_respawn_handler(id, menu, item)
{
	g_bIsVotingFor[ammo] = false
	g_bIsVotingFor[speed] = false
	g_bIsVotingFor[jumps] = false
	g_bIsVotingFor[wallbang] = false
	g_bIsVotingFor[respawn] = true

	switch(item)
	{
		case 0:	client_print_color(0, 0, "%s %s a votat ^4PENTRU^1 respawn.", TAG, get_name(id))
		case 1:	client_print_color(0, 0, "%s %s a votat ^4CONTRA^1 respawn.", TAG, get_name(id))
	}
	if(is_user_connected(id)) g_iVotes[item]++
	return PLUGIN_HANDLED
}

public vote_for_wallbang_handler(id, menu, item)
{
	g_bIsVotingFor[ammo] = false
	g_bIsVotingFor[speed] = false
	g_bIsVotingFor[jumps] = false
	g_bIsVotingFor[wallbang] = true
	g_bIsVotingFor[respawn] = false

	switch(item)
	{
		case 0:	client_print_color(0, 0, "%s %s a votat ^4PENTRU^1 wallbang.", TAG, get_name(id))
		case 1:	client_print_color(0, 0, "%s %s a votat ^4CONTRA^1 wallbang.", TAG, get_name(id))
	}
	if(is_user_connected(id)) g_iVotes[item]++
	return PLUGIN_HANDLED
}

public display_votes(id)
{
	if(g_bIsVotingFor[ammo])
	{
		if(g_iVotes[0] > g_iVotes[1])
		{
			client_print_color(0, 0, "%s Voturi: [PENTRU^4 %d^1][CONTRA^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[0] + g_iVotes[1])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 GLOANTE INFINITE^1.", TAG)
			g_VotedFor[ammo]++
			g_voting = 0
			ammo_value = 1
			return PLUGIN_HANDLED
		}
		else if(g_iVotes[1] > g_iVotes[0])
		{
			client_print_color(0, 0, "%s Voturi: [PENTRU^4 %d^1][CONTRA^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[0] + g_iVotes[1])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 FARA GLOANTE INFINITE^1.", TAG)
			g_VotedFor[ammo]++
			g_voting = 0
			ammo_value = 0
			return PLUGIN_HANDLED
		}
		else
		{
			client_print_color(0, 0, "%s Voturi: [PENTRU^4 %d^1][CONTRA^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[0] + g_iVotes[1])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 REVOTE^1.", TAG)
			g_voting = 0
			ammo_value = 0
			vote_for_ammo(id)
			return PLUGIN_HANDLED
		}
	}

	if(g_bIsVotingFor[speed])
	{
		if(g_iVotes[0] > g_iVotes[1] && g_iVotes[0] > g_iVotes[2] && g_iVotes[0] > g_iVotes[3])
		{
			client_print_color(0, 0, "%s Voturi: [250 SP^4 %d^1][300 SP^4 %d^1][350 SP^4 %d^1][400 SP^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[3], g_iVotes[0], g_iVotes[1], g_iVotes[2], g_iVotes[0] + g_iVotes[1] + g_iVotes[2] + g_iVotes[3])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 300 VITEZA^1.", TAG)
			hide(id)
			g_VotedFor[speed]++
			speed_value = 1
			g_voting = 0
			return PLUGIN_HANDLED
		}
		else if(g_iVotes[1] > g_iVotes[0] && g_iVotes[1] > g_iVotes[2] && g_iVotes[1] > g_iVotes[3])
		{
			client_print_color(0, 0, "%s Voturi: [250 SP^4 %d^1][300 SP^4 %d^1][350 SP^4 %d^1][400 SP^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[3], g_iVotes[0], g_iVotes[1], g_iVotes[2], g_iVotes[0] + g_iVotes[1] + g_iVotes[2] + g_iVotes[3])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 350 VITEZA^1.", TAG)
			hide(id)
			g_VotedFor[speed]++
			speed_value = 2
			g_voting = 0
			return PLUGIN_HANDLED
		}
		else if(g_iVotes[2] > g_iVotes[0] && g_iVotes[2] > g_iVotes[1] && g_iVotes[2] > g_iVotes[3])
		{
			client_print_color(0, 0, "%s Voturi: [250 SP^4 %d^1][300 SP^4 %d^1][350 SP^4 %d^1][400 SP^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[3], g_iVotes[0], g_iVotes[1], g_iVotes[2], g_iVotes[0] + g_iVotes[1] + g_iVotes[2] + g_iVotes[3])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 400 VITEZA^1.", TAG)
			hide(id)
			g_VotedFor[speed]++
			speed_value = 3
			g_voting = 0
			return PLUGIN_HANDLED
		}
		else if(g_iVotes[3] > g_iVotes[0] && g_iVotes[3] > g_iVotes[1] && g_iVotes[3] > g_iVotes[2])
		{
			client_print_color(0, 0, "%s Voturi: [250 SP^4 %d^1][300 SP^4 %d^1][350 SP^4 %d^1][400 SP^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[3], g_iVotes[0], g_iVotes[1], g_iVotes[2], g_iVotes[0] + g_iVotes[1] + g_iVotes[2] + g_iVotes[3])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 VITEZA NORMALA^1.", TAG)
			hide(id)
			g_VotedFor[speed]++
			speed_value = 0
			g_voting = 0
			return PLUGIN_HANDLED
		}
		else 
		{
			client_print_color(0, 0, "%s Voturi: [250 SP^4 %d^1][300 SP^4 %d^1][350 SP^4 %d^1][400 SP^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[2], g_iVotes[3], g_iVotes[0] + g_iVotes[1] + g_iVotes[2] + g_iVotes[3])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 REVOTE^1.", TAG)
			hide(id)
			speed_value = 0
			g_voting = 0
			vote_for_speed(id)
			return PLUGIN_HANDLED
		}
	}

	if(g_bIsVotingFor[jumps])
	{
		if(g_iVotes[0] > g_iVotes[1] && g_iVotes[0] > g_iVotes[2])
		{
			client_print_color(0, 0, "%s Voturi: [1 JUMP^4 %d^1][2 JUMPS^4 %d^1][3 JUMPS^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[2], g_iVotes[0], g_iVotes[1], g_iVotes[0] + g_iVotes[1] + g_iVotes[2])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 +1 JUMP^1.", TAG)
			hide(id)
			g_VotedFor[jumps]++
			jump_value = 1
			g_voting = 0
			return PLUGIN_HANDLED
		}

		else if(g_iVotes[1] > g_iVotes[0] && g_iVotes[1] > g_iVotes[2])
		{
			client_print_color(0, 0, "%s Voturi: [1 JUMP^4 %d^1][2 JUMPS^4 %d^1][3 JUMPS^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[2], g_iVotes[0] + g_iVotes[1] + g_iVotes[2])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 +2 JUMPS^1.", TAG)
			hide(id)
			g_VotedFor[jumps]++
			jump_value = 2
			g_voting = 0
			return PLUGIN_HANDLED
		}

		else if(g_iVotes[2] > g_iVotes[0] && g_iVotes[2] > g_iVotes[1])
		{
			client_print_color(0, 0, "%s Voturi: [1 JUMP^4 %d^1][2 JUMPS^4 %d^1][3 JUMPS^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[2], g_iVotes[0] + g_iVotes[1] + g_iVotes[2])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 NO EXTRA JUMPS^1.", TAG)
			hide(id)
			g_VotedFor[jumps]++
			jump_value = 0
			g_voting = 0
			return PLUGIN_HANDLED
		}
		else
		{
			client_print_color(0, 0, "%s Voturi: [1 JUMP^4 %d^1][2 JUMPS^4 %d^1][3 JUMPS^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[2], g_iVotes[0] + g_iVotes[1] + g_iVotes[2])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 REVOTE^1.", TAG)
			hide(id)
			g_VotedFor[jumps]++
			jump_value = 0
			g_voting = 0
			vote_for_jumps(id)
			return PLUGIN_HANDLED
		}
	}

	if(g_bIsVotingFor[respawn])
	{
		if(g_iVotes[0] > g_iVotes[1])
		{
			client_print_color(0, 0, "%s Voturi: [PENTRU^4 %d^1][CONTRA^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[0] + g_iVotes[1])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 RESPAWN^1.", TAG)
			hide(id)
			g_VotedFor[respawn]++
			respawn_value = 1
			g_voting = 0
			return PLUGIN_HANDLED
		}
		else if(g_iVotes[1] > g_iVotes[0])
		{
			client_print_color(0, 0, "%s Voturi: [PENTRU^4 %d^1][CONTRA^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[0] + g_iVotes[1])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 FARA RESPAWN^1.", TAG)
			hide(id)
			g_VotedFor[respawn]++
			respawn_value = 0
			g_voting = 0
			return PLUGIN_HANDLED
		}
		else
		{
			client_print_color(0, 0, "%s Voturi: [PENTRU^4 %d^1][CONTRA^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[0] + g_iVotes[1])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 REVOTE^1.", TAG)
			hide(id)
			respawn_value = 0
			g_voting = 0
			vote_for_respawn(id)
			return PLUGIN_HANDLED
		}
	}

	if(g_bIsVotingFor[wallbang])
	{
		if(g_iVotes[0] > g_iVotes[1])
		{
			client_print_color(0, 0, "%s Voturi: [PENTRU^4 %d^1][CONTRA^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[0] + g_iVotes[1])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 WALLBANG^1.", TAG)
			hide(id)
			g_VotedFor[wallbang]++
			wallbang_value = 1
			g_voting = 0
			return PLUGIN_HANDLED
		}
		else if(g_iVotes[1] > g_iVotes[0])
		{
			client_print_color(0, 0, "%s Voturi: [PENTRU^4 %d^1][CONTRA^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[0] + g_iVotes[1])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 FARA WALLBANG^1.", TAG)
			hide(id)
			g_VotedFor[wallbang]++
			wallbang_value = 0
			g_voting = 0
			return PLUGIN_HANDLED
		}
		else
		{
			client_print_color(0, 0, "%s Voturi: [PENTRU^4 %d^1][CONTRA^4 %d^1][TOTAL^4 %d^1]", TAG, g_iVotes[0], g_iVotes[1], g_iVotes[0] + g_iVotes[1])
			client_print_color(0, 0, "%s Votul a luat final. Rezultat:^4 REVOTE^1.", TAG)
			hide(id)
			wallbang_value = 0
			g_voting = 0
			vote_for_wallbang(id)
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_HANDLED
}
public client_connect(id)
{
	normalTrace[id] = 0
}

public client_disconnected(id)
{
	normalTrace[id] = 0
}

public event_resethud(id)
{
	lastTrace[id] = 0
}

public cmd_fullupdate(id)
{
	return PLUGIN_HANDLED
}

public fw_traceline(Float:vecStart[3], Float:vecEnd[3], ignoreM, id, ptr)
{
	if(!is_user_connected(id))	return FMRES_IGNORED
	
	if(!normalTrace[id])
	{
		normalTrace[id] = ptr
		return FMRES_IGNORED
	}

	else if(ptr == normalTrace[id])
		return FMRES_IGNORED

	if(wallbang_value != 0)
		return FMRES_IGNORED

	if(!is_user_alive(id))
		return FMRES_IGNORED

	if(!(pev(id,pev_button) & IN_ATTACK))
		return FMRES_IGNORED

	weapon = get_user_weapon(id,dummy,dummy)

	if(weapon == CSW_M3 || weapon == CSW_XM1014)
		return FMRES_IGNORED

	if(ptr == lastTrace[id])
	{
		set_tr(TR_vecEndPos,Float:{4096.0,4096.0,4096.0})
		set_tr(TR_pHit,0)
		set_tr(TR_iHitgroup,0)
		set_tr(TR_flFraction,1.0)

		return FMRES_SUPERCEDE
	}

	lastTrace[id] = ptr

	return FMRES_IGNORED
}

 public fw_playerpostthink(id)
{
	lastTrace[id] = 0
}

public client_PreThink(id)
{
	if(!is_user_alive(id) || jump_value == 0)	return PLUGIN_HANDLED
	
	new nbut = get_user_button(id)
	new obut = get_user_oldbutton(id)
	new value
	
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		switch(jump_value)
		{
			case 0: value = 0
			case 1: value = 1
			case 2: value = 2
		}

		if(jumpnum[id] < value)
		{
			dojump[id] = true
			jumpnum[id]++
			return PLUGIN_CONTINUE
		}
	}
	
	if((nbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumpnum[id] = 0
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(!is_user_alive(id) || jump_value == 0)	return PLUGIN_CONTINUE
	
		if(dojump[id] == true)
		{
			new Float:velocity[3]
			entity_get_vector(id,EV_VEC_velocity, velocity)
			velocity[2] = random_float(265.0,285.0)
			entity_set_vector(id,EV_VEC_velocity, velocity)
			dojump[id] = false
			return PLUGIN_CONTINUE
		}
	return PLUGIN_CONTINUE
}

public ev_curweapon(id)
{
	switch(speed_value)
	{
		case 0: set_user_maxspeed(id, 250.0)
		case 1: set_user_maxspeed(id, get_pcvar_float(g_data[Speed_ValueX]))
		case 2: set_user_maxspeed(id, get_pcvar_float(g_data[Speed2_ValueX]))
		case 3: set_user_maxspeed(id, get_pcvar_float(g_data[Speed3_ValueX]))
	}

}

public ev_kill_detect(id)
{
	if(is_user_connected(id) && respawn_value == 1)
	{
		set_task(RESPAWN_TIME, "Task_Respawn", id, _, _, "a", 1)
	}
	return PLUGIN_HANDLED
}

public Task_Respawn(id)
{
	if(is_user_connected(id) && !is_user_alive(id))	ExecuteHamB(Ham_CS_RoundRespawn, id)
	return
}

public ev_deathmsg()
{
    new iKiller = read_data(1)
    if(!(1 <= iKiller <= get_maxplayers()) || !is_user_alive(iKiller)) return
    
    new iVictim = read_data(2)
    if(iVictim == iKiller || cs_get_user_team( iVictim ) == cs_get_user_team(iKiller)) return
    
    if(ammo_value != 1) return

    static szWeaponName[32]
    read_data(4, szWeaponName, 31)
    
    if(equal(szWeaponName, "grenade"))	return
    
    new iWeaponId = get_user_weapon(iKiller)
    if(!(1 <= iWeaponId < sizeof(g_iWeaponAmmo)) || (1 << iWeaponId) & ((1 << 2) | (1 << CSW_C4) | (1<< CSW_KNIFE))) return
    
    get_weaponname(iWeaponId, szWeaponName, 31)
    
    new iWeaponEntity = find_ent_by_owner(-1, szWeaponName, iKiller)

    if(is_valid_ent(iWeaponEntity))
    {
        cs_set_weapon_ammo(iWeaponEntity, g_iWeaponAmmo[iWeaponId][AMMO_CLIP])
    }
    
    cs_set_user_bpammo(iKiller, iWeaponId, g_iWeaponAmmo[iWeaponId][AMMO_BACKPACK])
} 

stock get_name(id)
{
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	return szName
}
