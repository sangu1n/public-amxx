#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <fakemeta>

#define m_iId                43
#define m_iPrimaryAmmoType    49
#define m_fInReload            54

#define m_flNextAttack    83
#define m_pActiveItem    373
#define m_rgAmmo_Player_Slot0    376


#define IsPlayer(%1) (1 <= %1 <= get_maxplayers())

new const TAG[] = "^4[Alandala]^1"
new g_voting
new g_guns_menu, g_speed_menu, g_jumps_menu, g_respawn_menu, g_wallbang_menu
new g_votes[2] /*Ptr voturile doar cu DA / Nu*/
new g_votesx[4]
new jumpnum[33] = 0

new bool: guns, speed, speed2, speed3, jump, jump2, jump3, respawn, wb
new bool: gv, sv, jv, rv, wv
new bool: dojump[33] = false

new normalTrace[33], lastTrace[33], weapon, dummy

const NOCLIP_WPN_BS    = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

public plugin_init()
{
	register_plugin("[Alandala] Votes", "1.0 beta", "SenorAMXX aka doza")

	register_clcmd("say /vote", "main_menu_vote")
	register_clcmd("say /guns", "guns_start_vote")
	register_clcmd("say /speed", "speed_start_vote")
	register_clcmd("say /jumps", "jumps_start_vote")
	register_clcmd("say /respawn", "respawn_start_vote")
	register_clcmd("say /wallbang", "wallbang_start_vote")

	RegisterHamPlayer(Ham_Killed, "ev_killdetect", 1)
	RegisterHam(Ham_Killed, "player", "ev_reloadammo", 1)
	register_event("TextMsg", "ev_rr", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
	register_event("CurWeapon", "ev_curweapon", "be", "1=1")
	register_event("ResetHUD","event_resethud", "b")
	register_clcmd("fullupdate", "cmd_fullupdate")
	register_forward(FM_TraceLine,"fw_traceline")
	register_forward(FM_PlayerPostThink,"fw_playerpostthink")
	
}


public main_menu_vote(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot activ.", TAG)
		return PLUGIN_HANDLED
	}

	new ilen[190], menu
	menu = menu_create("[Alandala] Choose what to vote:", "vote_main_handler")
	if(!gv)
	{
		formatex(ilen, charsmax(ilen), "Infinite Ammo \r[Voted: \yNothing]")
		menu_additem(menu, ilen, "0", 0)
	}
	else
	{
		formatex(ilen, charsmax(ilen), "Infinite Ammo \r[Voted: \y%s]", guns ? "On" : "Off")
		menu_additem(menu, ilen, "0", 0)
	}
	if(!sv)
	{
		formatex(ilen, charsmax(ilen), "Speed \r[Voted: \yNothing]")
		menu_additem(menu, ilen, "1", 0)
	}
	else if(speed && sv)
	{
		formatex(ilen, charsmax(ilen), "Speed \r[Voted: \y300 Speed]")
		menu_additem(menu, ilen, "1", 0)
	}
	else if(speed2 && sv)
	{
		formatex(ilen, charsmax(ilen), "Speed \r[Voted: \y350 Speed]")
		menu_additem(menu, ilen, "1", 0)
	}
	else if(speed3 && sv)
	{
		formatex(ilen, charsmax(ilen), "Speed \r[Voted: \y400 Speed]")
		menu_additem(menu, ilen, "1", 0)
	}
	
	if(!jv)
	{
		formatex(ilen, charsmax(ilen), "Jumps \r[Voted: \yNothing]")
		menu_additem(menu, ilen, "2", 0)
	}
	else if(jump && jv)
	{
		formatex(ilen, charsmax(ilen), "Jumps \r[Voted: \y1 extra jump]")
		menu_additem(menu, ilen, "2", 0)
	}
	else if(jump2 && jv)
	{
		formatex(ilen, charsmax(ilen), "Jumps \r[Voted: \y2 extra jump]")
		menu_additem(menu, ilen, "2", 0)
	}
	else if(jump3 && jv)
	{
		formatex(ilen, charsmax(ilen), "Jumps \r[Voted: \yNo extra jumps]")
		menu_additem(menu, ilen, "2", 0)
	}
	if(!rv)
	{
		formatex(ilen, charsmax(ilen), "Respawn \r[Voted: \yNothing]")
		menu_additem(menu, ilen, "3", 0)
	}
	else
	{
		formatex(ilen, charsmax(ilen), "Respawn \r[Voted: \y%s]", respawn ? "ON" : "OFF")
		menu_additem(menu, ilen, "3", 0)
	}
	
	if(!wv)
	{
		formatex(ilen, charsmax(ilen), "WallBang \r[Voted: \yNothing]")
		menu_additem(menu, ilen, "4", 0)
	}
	else
	{
		formatex(ilen, charsmax(ilen), "WallBang \r[Voted: \y%s]", wb ? "Permis" : "Interzis")
		menu_additem(menu, ilen, "4", 0)
	}

	menu_display(id,menu,0)
	return PLUGIN_HANDLED
}
public vote_main_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	switch(item)
	{
		case 0:	guns_start_vote(id)
		case 1:	speed_start_vote(id)
		case 2:	jumps_start_vote(id)
		case 3:	respawn_start_vote(id)
		case 4:	wallbang_start_vote(id)
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public guns_start_vote(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot activ.", TAG)
		return PLUGIN_HANDLED
	}

	g_votes[0] = g_votes[1] = 0

	g_guns_menu = menu_create("[Alandala] \yVote for Infinite Ammo", "guns_start_vote_handler")

	menu_additem(g_guns_menu, "Da", "", 0)
	menu_additem(g_guns_menu, "Nu", "", 0)

	menu_setprop(g_guns_menu, MPROP_EXIT, MEXIT_NEVER)

	new iPlayers[32], iNum, id2
	get_players(iPlayers, iNum)

	for(new i; i < iNum; i++)
	{
		id2 = iPlayers[i]
		menu_display(id2, g_guns_menu, 0)
		g_voting++
	}
	set_task(10.0, "guns_endvote")
	return PLUGIN_HANDLED
}

public guns_start_vote_handler(id, menu, item)
{
	if(item == MENU_EXIT || !g_voting)
	{
		return PLUGIN_HANDLED
	}
	switch(item)
	{
		case 0: client_print_color(0, 0, "%s %s a votat ^4PENTRU^1 gloante infinite.", TAG, get_name(id))
		case 1: client_print_color(0, 0, "%s %s a votat ^4CONTRA^1 gloantelor infinite.", TAG, get_name(id))
	}
	g_votes[item]++
	return PLUGIN_HANDLED
}

public guns_endvote()
{
	if(g_votes[0] > g_votes[1])
	{
		client_print_color(0, 0, "%s Votul a luat final, glonatele infinite au fost activate.", TAG)
		g_voting = 0
		guns = true
		gv = true
	}
	else if(g_votes[0] < g_votes[1])
	{
		client_print_color(0, 0, "%s Votul a luat final, glonatele infinite au fost dezactivate.", TAG)
		g_voting = 0
		guns = false
		gv = true
	}
	else // Daca iese egal
	{
		client_print_color(0, 0, "%s Votul a luat final cu scor egal. Incepe revotarea..", TAG)

		menu_destroy(g_guns_menu)
		g_voting = 0

		new iPlayers[32], iNum
		get_players(iPlayers, iNum)

		for(new i; i < iNum; i++)
		{
			guns_start_vote(iPlayers[i])
		}

	}
	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////////////////////////////////////

public speed_start_vote(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot activ.", TAG)
		return PLUGIN_HANDLED
	}

	arrayset(g_votesx, 0, sizeof g_votesx)

	g_speed_menu = menu_create("[Alandala] \yVote for Speed", "speed_start_vote_handler")

	menu_additem(g_speed_menu, "300", "", 0)
	menu_additem(g_speed_menu, "350", "", 0)
	menu_additem(g_speed_menu, "400", "", 0)
	menu_additem(g_speed_menu, "Speed Normal", "", 0)

	menu_setprop(g_speed_menu, MPROP_EXIT, MEXIT_NEVER)

	new iPlayers[32], iNum, id2
	get_players(iPlayers, iNum)

	for(new i; i < iNum; i++)
	{
		id2 = iPlayers[i]
		menu_display(id2, g_jumps_menu, 0)
		g_voting++
	}
	set_task(10.0, "speed_endvote")
	return PLUGIN_HANDLED
}

public speed_start_vote_handler(id, menu, item)
{
	if(item == MENU_EXIT || !g_voting)
	{
		return PLUGIN_HANDLED
	}
	switch(item)
	{
		case 0: client_print_color(0, 0, "%s %s a votat pentru^4 300^1 viteza.", TAG, get_name(id))
		case 1: client_print_color(0, 0, "%s %s a votat pentru^4 350^1 viteza.", TAG, get_name(id))
		case 2: client_print_color(0, 0, "%s %s a votat pentru^4 400^1 viteza.", TAG, get_name(id))
		case 3: client_print_color(0, 0, "%s %s a votat pentru viteza ^4normala.", TAG, get_name(id))
	}
	g_votesx[item]++
	return PLUGIN_HANDLED
}

public speed_endvote()
{
	if(g_votesx[0] > g_votesx[1] && g_votesx[0] > g_votesx[2] && g_votesx[0] > g_votesx[3])
	{
		client_print_color(0, 0, "%s Viteza 300 next round.", TAG)
		g_voting = 0
		speed = true
		sv = true
	}
	else if(g_votesx[1] > g_votesx[0] && g_votesx[1] > g_votesx[2] && g_votesx[1] > g_votesx[3])
	{
		client_print_color(0, 0, "%s Viteza 350 next round.", TAG)
		g_voting = 0
		speed2 = true
		sv = true
	}
	else if(g_votesx[2] > g_votesx[0] && g_votesx[2] > g_votesx[1] && g_votesx[2] > g_votesx[3])
	{
		client_print_color(0, 0, "%s Viteza 400 next round.", TAG)
		g_voting = 0
		speed3 = true
		sv = true
	}
	else if(g_votesx[3] > g_votesx[0] && g_votesx[3] > g_votesx[1] && g_votesx[3] > g_votesx[2])
	{
		client_print_color(0, 0, "%s Viteza normala next round.", TAG)
		g_voting = 0
		sv = true
	}
	else // Daca iese egal
	{
		client_print_color(0, 0, "%s Votul a luat final cu scor egal. Incepe revotarea..", TAG)

		menu_destroy(g_speed_menu)
		g_voting = 0

		new iPlayers[32], iNum
		get_players(iPlayers, iNum)

		for(new i; i < iNum; i++)
		{
			speed_start_vote(iPlayers[i])
		}

	}
	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////////////////////////////////////

public jumps_start_vote(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot activ.", TAG)
		return PLUGIN_HANDLED
	}

	arrayset(g_votesx, 0, sizeof g_votesx)

	g_jumps_menu = menu_create("[Alandala] \yVote for Extra Jumps", "jumps_start_vote_handler")

	menu_additem(g_jumps_menu, "1 Extra Jump", "", 0)
	menu_additem(g_jumps_menu, "2 Extra Jumps", "", 0)
	menu_additem(g_jumps_menu, "No Extra Jump", "", 0)

	menu_setprop(g_jumps_menu, MPROP_EXIT, MEXIT_NEVER)

	new iPlayers[32], iNum, id2
	get_players(iPlayers, iNum)

	for(new i; i < iNum; i++)
	{
		id2 = iPlayers[i]
		menu_display(id2, g_jumps_menu, 0)

		g_voting++
	}
	set_task(10.0, "jumps_endvote")
	return PLUGIN_HANDLED
}

public jumps_start_vote_handler(id, menu, item)
{
	if(item == MENU_EXIT || !g_voting)
	{
		return PLUGIN_HANDLED
	}
	switch(item)
	{
		case 0: client_print_color(0, 0, "%s %s a votat pentru^4 1^1 extra jump.", TAG, get_name(id))
		case 1: client_print_color(0, 0, "%s %s a votat pentru^4 2^1 extra jump.", TAG, get_name(id))
		case 3: client_print_color(0, 0, "%s %s a votat pentru^4 0^1 extra jump.", TAG, get_name(id))
	}
	g_votesx[item]++
	return PLUGIN_HANDLED
}

public jumps_endvote()
{
	if(g_votesx[0] > g_votesx[1] && g_votesx[0] > g_votesx[2])
	{
		client_print_color(0, 0, "%s +1 extra jump next round.", TAG)
		g_voting = 0
		jump = true
		jv = true
	}
	else if(g_votesx[1] > g_votesx[0] && g_votesx[1] > g_votesx[2])
	{
		client_print_color(0, 0, "%s +2 extra jumps next round.", TAG)
		g_voting = 0
		jump2 = true
		jv = true
	}
	else if(g_votesx[2] > g_votesx[0] && g_votesx[2] > g_votesx[1])
	{
		client_print_color(0, 0, "%s No extra jumps.", TAG)
		g_voting = 0
		jump3 = true
		jv = true
	}
	else
	{
		client_print_color(0, 0, "%s Votul a luat final cu scor egal. Incepe revotarea..", TAG)

		menu_destroy(g_jumps_menu)
		g_voting = 0

		new iPlayers[32], iNum
		get_players(iPlayers, iNum)

		for(new i; i < iNum; i++)
		{
			jumps_start_vote(iPlayers[i])
		}

	}
	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////////////////////////////////////

public respawn_start_vote(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot activ.", TAG)
		return PLUGIN_HANDLED
	}

	g_votes[0] = g_votes[1] = 0

	g_respawn_menu = menu_create("[Alandala] \yVote for Respawn", "respawn_start_vote_handler")

	menu_additem(g_respawn_menu, "Da", "", 0)
	menu_additem(g_respawn_menu, "Nu", "", 0)

	menu_setprop(g_respawn_menu, MPROP_EXIT, MEXIT_NEVER)

	new iPlayers[32], iNum, id2
	get_players(iPlayers, iNum)

	for(new i; i < iNum; i++)
	{
		id2 = iPlayers[i]
		menu_display(id2, g_respawn_menu, 0)
		g_voting++
	}
	set_task(10.0, "respawn_endvote")
	return PLUGIN_HANDLED
}

public respawn_start_vote_handler(id, menu, item)
{
	if(item == MENU_EXIT || !g_voting)
	{
		return PLUGIN_HANDLED
	}
	switch(item)
	{
		case 0: client_print_color(0, 0, "%s %s a votat ^4PENTRU^1 respawn.", TAG, get_name(id))
		case 1: client_print_color(0, 0, "%s %s a votat ^4CONTRA^1 respawn.", TAG, get_name(id))
	}
	g_votes[item]++
	return PLUGIN_HANDLED
}

public respawn_endvote()
{
	if(g_votes[0] > g_votes[1])
	{
		client_print_color(0, 0, "%s Respawn activat.", TAG)
		g_voting = 0
		respawn = true
		rv = true
	}
	else if(g_votes[1] > g_votes[0])
	{
		client_print_color(0, 0, "%s Fara respawn.", TAG)
		respawn = false
		g_voting = 0
		rv = true
	}
	else
	{
		client_print_color(0, 0, "%s Votul a luat final cu scor egal. Incepe revotarea..", TAG)

		menu_destroy(g_respawn_menu)
		g_voting = 0

		new iPlayers[32], iNum
		get_players(iPlayers, iNum)


		for(new i; i < iNum; i++)
		{
			respawn_start_vote(iPlayers[i])
		}

	}
	return PLUGIN_HANDLED
}

///////////////////////////////////////////////////////////////////////////////////////////////

public wallbang_start_vote(id)
{
	if(g_voting)
	{
		client_print_color(id, id, "%s Exista deja un vot activ.", TAG)
		return PLUGIN_HANDLED
	}
 
	g_votes[0] = g_votes[1] = 0

	g_wallbang_menu = menu_create("[Alandala] \yVote for WallBang", "wallbang_start_vote_handler")

	menu_additem(g_wallbang_menu, "Da", "", 0)
	menu_additem(g_wallbang_menu, "Nu", "", 0)

	menu_setprop(g_wallbang_menu, MPROP_EXIT, MEXIT_NEVER)

	new iPlayers[32], iNum, id2
	get_players(iPlayers, iNum)

	for(new i; i < iNum; i++)
	{
		id2 = iPlayers[i]
		menu_display(id2, g_wallbang_menu, 0)

		g_voting++
	}
	set_task(10.0, "wallbang_endvote")
	return PLUGIN_HANDLED
}

public wallbang_start_vote_handler(id, menu, item)
{
	if(item == MENU_EXIT || !g_voting)
	{
		return PLUGIN_HANDLED
	}
	switch(item)
	{
		case 0: client_print_color(0, 0, "%s %s a votat ^4PENTRU^1 WallBang.", TAG, get_name(id))
		case 1: client_print_color(0, 0, "%s %s a votat ^4CONTRA^1 WallBang.", TAG, get_name(id))
	}
	g_votes[item]++
	return PLUGIN_HANDLED
}

public wallbang_endvote()
{
	if(g_votes[0] > g_votes[1])
	{
		client_print_color(0, 0, "%s Wallbang activat.", TAG)
		g_voting = 0
		wb = true
		wv = true
	}
	else if(g_votes[1] > g_votes[0])
	{
		client_print_color(0, 0, "%s Wallbang dezactivat.", TAG)
		g_voting = 0
		wb = false
		wv = true
	}
	else
	{
		client_print_color(0, 0, "%s Votul a luat final cu scor egal. Incepe revotarea..", TAG)

		menu_destroy(g_wallbang_menu)
		g_voting = 0

		new iPlayers[32], iNum
		get_players(iPlayers, iNum)

		for(new i; i < iNum; i++)
		{
			wallbang_start_vote(iPlayers[i])
		}

	}
	return PLUGIN_HANDLED
}

/////////////////////////////////////////////////////////////////////////////////

public fw_traceline(Float:vecStart[3], Float:vecEnd[3], ignoreM, id, ptr)
{
	if(!is_user_connected(id) || !is_user_alive(id))	return FMRES_IGNORED

	if(!normalTrace[id])
	{
		normalTrace[id] = ptr
		return FMRES_IGNORED
	}
	else if(ptr == normalTrace[id])	return FMRES_IGNORED

	if(!(pev(id,pev_button) & IN_ATTACK))	return FMRES_IGNORED

	weapon = get_user_weapon(id,dummy,dummy)

	if(weapon == CSW_M3 || weapon == CSW_XM1014)	return FMRES_IGNORED

	if(ptr == lastTrace[id] && !wb)
	{
		set_tr(TR_vecEndPos, Float:{4096.0,4096.0,4096.0})
		//set_tr2(TR_AllSolid, 1)
		set_tr(TR_pHit, 0)
		set_tr(TR_iHitgroup, 0)
		set_tr(TR_flFraction, 1.0)
		return FMRES_SUPERCEDE
	}

	lastTrace[id] = ptr

	return FMRES_IGNORED
 }

public fw_playerpostthink(id)	
{
	lastTrace[id] = 0
}


public ev_rr()
{
	gv = false
	sv = false
	jv = false
	rv = false
	wv = false
	g_voting = 0
	guns = false
	speed = false
	speed2 = false
	speed3 = false
	jump = false
	jump2 = false
	jump3 = false
	respawn = false
	wb = false
}

public ev_reloadammo(iVictim, iKiller, iGib)
{
	if(guns)
	{
		if(IsPlayer(iKiller) && is_user_alive(iKiller))
    	{
        	new iWeapon = get_pdata_cbase(iKiller, m_pActiveItem)
        	if(iWeapon > 0 && !(NOCLIP_WPN_BS & (1<<get_pdata_int(iWeapon, m_iId, 4))))
        	{
            	new Float:flNextAttack = get_pdata_float(iKiller, m_flNextAttack, 5)
            	set_pdata_float(iKiller, m_flNextAttack, -0.001, 5)

            	new iButton = pev(iKiller, pev_button)
            	set_pev(iKiller, pev_button, iButton & ~(IN_ATTACK|IN_ATTACK2|IN_RELOAD))
            	set_pdata_int(iWeapon, m_fInReload, 1, 4)
            	ExecuteHamB(Ham_Item_PostFrame, iWeapon)

            	set_pdata_int(iKiller, m_rgAmmo_Player_Slot0 + get_pdata_int(iWeapon, m_iPrimaryAmmoType, 4), 200)
            	set_pdata_float(iKiller, m_flNextAttack, flNextAttack, 5)
            	set_pev(iKiller, pev_button, iButton)
        	}
    	}
	}
	return PLUGIN_HANDLED
    
}

public ev_curweapon(id)
{
	if(speed)	set_user_maxspeed(id, 300.0)
	if(speed2)	set_user_maxspeed(id, 350.0)
	if(speed3)	set_user_maxspeed(id, 400.0)
}

public ev_killdetect(id)
{
	if(is_user_connected(id) && respawn)
	{	
		set_task(2.0, "Task_Respawn", id, _, _, "a", 1)
	}
}

public Task_Respawn(id)
{
	if(is_user_connected(id) && !is_user_alive(id))	ExecuteHamB(Ham_CS_RoundRespawn, id)
	return
}

public client_PreThink(id)
{
	if(!IsPlayer(id)) return PLUGIN_HANDLED
	
	new nbut = get_user_button(id)
	new obut = get_user_oldbutton(id)
	
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(jump)
		{
			if(jumpnum[id] < 1)
			{
				dojump[id] = true
				jumpnum[id]++
				return PLUGIN_CONTINUE
			}
		}

		if(jump2)
		{
			if(jumpnum[id] < 2)
			{
				dojump[id] = true
				jumpnum[id]++
				return PLUGIN_CONTINUE
			}
		}

		if(jump3)
		{
			if(jumpnum[id] < 0)
			{
				dojump[id] = true
				jumpnum[id]++
				return PLUGIN_CONTINUE
			}
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
	if(!IsPlayer(id)) return PLUGIN_HANDLED

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

public client_connect(id) normalTrace[id] = 0

public client_disconnected(id)	normalTrace[id] = 0
public event_resethud(id)		lastTrace[id] = 0
public cmd_fullupdate(id)		return PLUGIN_HANDLED

stock get_name(id)
{
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	return szName
}
