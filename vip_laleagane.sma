#include <amxmodx>
#include <cstrike>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <fun>

#define VIP_FLAG ADMIN_LEVEL_H

#define CSDM  // daca vrei ca pluginul sa fie ptr csdm lasi asa ; daca nu pune " // " in fata : //#define CSDM

#define DEAD (1<<0)
#define VIP (1<<2)

enum _: CVARS
{	
	EXTRA_JUMPS,
	MAXHP,
	MAXAP,
	KILLHP,
	KILLAP,
	KILLHP_HS,
	KILLAP_HS,
	SPAWNHP,
	SPAWNAP,
	RUNDA_ACCES,
	VIP_FREE_TURN,
	VIP_FREE_START,
	VIP_FREE_END
}

enum
{
	Primary = 1,
	Secondary,
	Knife,
	Grenades,
	C4
}

new VAR[CVARS]
new iRound
new jumpnum[33] = 0
new bool:dojump[33] = false
new bool:bool_vip
new harti_blocate[128]




public plugin_init()
{
	register_plugin("VIP LLG", "1.0", "SenorAMXX")

	new pcvar

	pcvar = create_cvar("vip_extra_jumps", "2")
	bind_pcvar_num(pcvar, VAR[EXTRA_JUMPS])

	pcvar = create_cvar("vip_maxhp", "110")
	bind_pcvar_num(pcvar, VAR[MAXHP])

	pcvar = create_cvar("vip_maxap", "110")
	bind_pcvar_num(pcvar, VAR[MAXAP])

	pcvar = create_cvar("vip_killhp", "5")
	bind_pcvar_num(pcvar, VAR[KILLHP])

	pcvar = create_cvar("vip_killap", "8")
	bind_pcvar_num(pcvar, VAR[KILLAP])

	pcvar = create_cvar("vip_killhp_hs", "8")
	bind_pcvar_num(pcvar, VAR[KILLHP_HS])

	pcvar = create_cvar("vip_killap_hs", "10")
	bind_pcvar_num(pcvar, VAR[KILLAP_HS])

	pcvar = create_cvar("vip_spawn_hp", "105")
	bind_pcvar_num(pcvar, VAR[SPAWNHP])

	pcvar = create_cvar("vip_spawn_ap", "105")
	bind_pcvar_num(pcvar, VAR[SPAWNAP])

	pcvar = create_cvar("vip_menu_menu_shop", "2")
	bind_pcvar_num(pcvar, VAR[RUNDA_ACCES])

	pcvar = create_cvar("vip_free", "1")
	bind_pcvar_num(pcvar, VAR[VIP_FREE_TURN])

	pcvar = create_cvar("vip_free_start", "20")
	bind_pcvar_num(pcvar, VAR[VIP_FREE_START])

	pcvar = create_cvar("vip_free_end", "23")
	bind_pcvar_num(pcvar, VAR[VIP_FREE_END])


	register_clcmd("say /vips", "display_vip")


	RegisterHam(Ham_Killed, "player", "ham_PlayerKilled", 1)
	RegisterHam(Ham_Spawn, "player", "SpawnCheck", 1)
	register_logevent("logev_Restart", 2, "1&Restart_Round", "1&Game_Commencing")
	register_event("HLTV", "ev_NewRound", "a", "1=0", "2=0")

	register_message(get_user_msgid("ScoreAttrib"), "VIP_IN_TAB")

	AutoExecConfig()




}

public plugin_cfg()
{
	new File[64]
	get_configsdir(File, charsmax(File))
	formatex(harti_blocate, charsmax(harti_blocate), "%s/VIP_LLG/%s,", File, harti_blocate)

	new file = fopen(harti_blocate, "r+")
	
	if(!file_exists(harti_blocate))
	{
		write_file(harti_blocate, "; PLUGINUL VIP-UL ESTE DEZACTIVAT PE URMATOARELE HARTI: ")
		write_file(harti_blocate, "; Exemplu :^n; ^"harta^"^n^nfy_snow^nawp_bycastor")
	}
	
	new mapname[32];
	get_mapname(mapname, charsmax(mapname))
	
	new cht[121], maptext[32]
	while(!feof(file))
	{
		fgets(file, cht, charsmax(cht))
		trim(cht);
		
		if(cht[0] == ';' || !strlen(cht)) 
		{
			continue; 
		}
		
		parse(cht, maptext, charsmax(maptext))
		
		if(equal(maptext, mapname))
		{
			pause("a")
			break;
		}
	}
	fclose(file)
}


public SpawnCheck(id)
{
	#if defined CSDM
		set_task(1.0, "attribute_spawn_benefits")
	#endif

	attribute_spawn_benefits(id)
	
	if(iRound >= VAR[RUNDA_ACCES])
	{
		meniu_vip(id)
	}
	
}
public logev_Restart()	iRound = 0

public attribute_spawn_benefits(id)
{
	if(!is_user_alive(id) || is_user_bot(id) || is_user_hltv(id)) return PLUGIN_HANDLED

	if(is_user_gold_member(id))
	{
		set_user_health(id, VAR[SPAWNHP])
		cs_set_user_armor(id, VAR[SPAWNAP], CS_ARMOR_VESTHELM)
	}
	return PLUGIN_HANDLED
}


public ev_NewRound()
{
	iRound++
	if(get_cvar_num(VAR[VIP_FREE_TURN]) == 0)	return PLUGIN_CONTINUE

	if(is_vip_free(VAR[VIP_FREE_START], VAR[VIP_FREE_END]))	bool_vip = true
	else
    bool_vip = false	
	return PLUGIN_CONTINUE

}



public client_PreThink(id)
{
	if(!is_user_alive(id))	return PLUGIN_HANDLED
	
	new nbut = get_user_button(id)
	new obut = get_user_oldbutton(id)
	
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(is_user_gold_member(id))
		{
			if(jumpnum[id] < VAR[EXTRA_JUMPS])
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
	if(bool_vip)
    {
        set_user_flags(id, VIP_FLAG)
        set_hudmessage(255, 0, 0, 0.27, 0.0, 0, 6.0, 12.0)
        show_hudmessage(id, "FREE VIP ON!")
    }

	if(!is_user_alive(id))
	{
		return PLUGIN_CONTINUE
	}
	
	if(is_user_gold_member(id))
	{
		if(dojump[id] == true)
		{
			new Float:velocity[3]
			entity_get_vector(id,EV_VEC_velocity, velocity)
			velocity[2] = random_float(265.0,285.0)
			entity_set_vector(id,EV_VEC_velocity, velocity)
			dojump[id] = false
			return PLUGIN_CONTINUE
		}
	}
	
	return PLUGIN_CONTINUE;
}

public VIP_IN_TAB() 
{
	new id = get_msg_arg_int(1);
	if(is_user_gold_member(id))
	{
		if(is_user_connected(id))
			set_msg_arg_int(2, ARG_BYTE, is_user_alive(id) ? VIP : DEAD)
	}
}

public ham_PlayerKilled(iVictim, iAttacker)
{
	if(!iVictim || !iAttacker || !is_user_alive(iAttacker))
		return HAM_IGNORED;
		
	if(is_user_gold_member(iAttacker))
	{
		new g_iIsHeadshot	= read_data (3)
		new g_iHealth		= get_user_health(iAttacker)
		new g_iArmor 		= get_user_armor(iAttacker)
		new g_iHealthAdd	= VAR[KILLHP]
		new g_iHealthHSAdd	= VAR[KILLHP_HS]
		new g_iArmorAdd		= VAR[KILLAP]
		new g_iArmorHSAdd	= VAR[KILLAP_HS]
		new g_iMaxHP		= VAR[MAXHP]
		new g_iMaxAP		= VAR[MAXAP]
		
		if( g_iIsHeadshot )
		{
			if( g_iHealth >= g_iMaxHP || g_iArmor >= g_iMaxAP )
			{
				set_user_health(iAttacker, g_iMaxHP)
				set_user_armor(iAttacker, g_iMaxAP)
			}
			else
			{
				set_user_health(iAttacker, g_iHealth + g_iHealthHSAdd)
				set_user_armor(iAttacker, g_iHealth + g_iArmorHSAdd)
			}
		}
		else
		{
			if(g_iHealth >= g_iMaxHP || g_iArmor >= g_iMaxAP)
			{
				set_user_health(iAttacker, g_iMaxHP)
				set_user_armor(iAttacker, g_iMaxAP)
			}
			else
			{
				set_user_health(iAttacker, g_iHealth + g_iHealthAdd)
				set_user_armor(iAttacker, g_iHealth + g_iArmorAdd)
			}
		}
	}
	return PLUGIN_HANDLED
}

public meniu_vip(id)
{
	if(!is_user_gold_member(id)) return
	new menu = menu_create("VIP MENU","VMH")

	menu_additem(menu, "AK47 + DEAGLE", "", 0)
	menu_additem(menu, "M4A1 + DEAGLE", "", 0)
	menu_additem(menu, "AWP + DEAGLE" , "", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public VMH(id,menu,item)
{
	if(item==MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	switch(item)
	{
		case 0: 
		{
			give_item(id, "weapon_ak47")
			give_item(id, "weapon_deagle")
			cs_set_user_bpammo(id, CSW_AK47, 90)
			cs_set_user_bpammo(id, CSW_DEAGLE, 35)
			client_print(id, print_center, "**Ai primit AK47 + DEAGLE**")
		}
		case 1: 
		{
			give_item(id, "weapon_m4a1")
			give_item(id, "weapon_deagle")
			cs_set_user_bpammo(id, CSW_M4A1, 90)
			cs_set_user_bpammo(id, CSW_DEAGLE, 35)
			client_print(id, print_center, "**Ai primit M4A1 + DEAGLE**")
		}
		case 2: 
		{
			give_item(id, "weapon_awp")
			give_item(id, "weapon_deagle")
			cs_set_user_bpammo(id, CSW_AWP, 30)
			cs_set_user_bpammo(id, CSW_DEAGLE, 35)
			client_print(id, print_center, "**Ai primit AWP + DEAGLE**")
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED

}

public display_vip(id)
{
	if(is_user_connected(id))
		return PLUGIN_HANDLED;
		
	new vname[33], arg[190], data, len
	if(is_user_gold_member(id))
	{
		get_user_name(id, vname[data++], charsmax(vname));
	}
	len = format(arg, charsmax(arg), "!g%s !yVIP's Online!team: ")
	if( data > 0 ) 
	{
		for( new i = 0 ; i < data ; i++)
		{
			len += format(arg[len], charsmax(arg) - len, "!y%s%s ", vname[i], i < (data - 1) ? ", " : "")
			if(len > 96)
			{
				llg_color(id, arg)
				len = format(arg, charsmax(arg), "%s ")
			}
		}
		llg_color(id, arg)
	}
	else 
	{
		len += format(arg[len], charsmax(arg) - len, "No VIP online.")
		llg_color(id, arg)
	}
	return PLUGIN_CONTINUE
}

stock bool:is_user_gold_member(id)
{
	if(get_user_flags(id) & VIP_FLAG) return true;
	return false;
}
bool:is_vip_free(start, end)
{
    new iHour; time( iHour )
    return bool:( start < end ? ( start <= iHour < end ) : ( start <= iHour || iHour < end ) )
} 

stock llg_color(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
    
	replace_all(msg, 190, "!g", "^4"); // Green Color
	replace_all(msg, 190, "!y", "^1"); // Default Color
	replace_all(msg, 190, "!team", "^3"); // Team Color
	replace_all(msg, 190, "!team2", "^0"); // Team2 Color
        
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i])
				write_string(msg)
				message_end();
			}
		}
	}
}
