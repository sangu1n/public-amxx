#include <amxmodx>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <csx>

enum VipBenefits
{
	VIP_NAME[30],
	VIP_FLAGS[26],
	VIP_PRICE[20],
	VIP_START_HP,
	VIP_START_AP,
	VIP_KILL_HP,
	VIP_KILL_AP,
	VIP_EXTRA_JUMPS,
	VIP_BULLET_DAMAGE,
	VIP_WEAPON_MENU
}

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

new const VIP_DATA[][VipBenefits] =
{	/*
	{"Nume Grad Vip", 	"flaguri", 	pret, 			start hp, 	start ap, 	kill hp, 	ill ap, 	extra jumps, 	bulletdamage,	weaponmenu}*/
	{"VIP SILVER"	, 	"w", 		"5 EURO",		100, 		100, 		5, 			3,	 		0, 				0,				0},
	{"VIP GOLD"		, 	"x", 		"10 EURO",		110, 		110, 		10, 		10,			1, 				1,				1},
	{"VIP DIAMOND"	, 	"y", 		"15 EURO",		120, 		120, 		15, 		15,			2, 				1,				1},
	{"VIP EMERALD"	, 	"v", 		"20 EURO",		150, 		150, 		20, 		20,			2, 				1,				1}
}

stock is_vip(const id, &accessId) 
{
	new bool: found = false
	for(new i; i < sizeof VIP_DATA; i++) 
	{
		if(get_user_flags(id) & read_flags(VIP_DATA[i][VIP_FLAGS])) 
		{
			found = true
			accessId = i
			break
		}
	}
	return found
}

new jumpnum[33] = 0
new bool:dojump[33] = false
new g_iPosition[33]
new g_iSize
new iRound

new const Float: g_flCoords[][] =
{
	{ 0.50, 0.40 },
	{ 0.56, 0.44 },
	{ 0.60, 0.50 },
	{ 0.56, 0.56 },
	{ 0.50, 0.60 },
	{ 0.44, 0.56 },
	{ 0.40, 0.50 },
	{ 0.44, 0.44 }
}

enum _: WeaponsData
{
	WeaponName[32],
	WeaponEnt[32],
	weapon_csw_id,
	weapon_bp_ammo
}

new const WEAPONS_DATA[][WeaponsData] = 
{
	{"AK47", "weapon_ak47", CSW_AK47, 90},
	{"M4A1", "weapon_m4a1", CSW_M4A1, 90},
	{"AWP", "weapon_awp", CSW_AWP, 30}
}

new const PISTOLS_DATA[][WeaponsData] =
{
	{"DEAGLE", "weapon_deagle", CSW_DEAGLE, 35},
	{"USP", "weapon_usp", CSW_USP, 100},
	{"GLOCK", "weapon_glock", CSW_GLOCK, 120}
}

public plugin_init()
{
	register_plugin("VIP SYSTEM", "1.0", "kidd0x")

	RegisterHam(Ham_Spawn, "player", "event_spawn", 1)

	register_event("DeathMsg", "ev_deathmsg", "a")
	register_event("TextMsg","event_rr","a","2&#Game_w")
	register_event("TextMsg","event_rr","a","2&#Game_C")

	register_logevent("event_round_start", 2, "1=Round_Start" )
	
	register_clcmd("say /vips", "func_display_vips")

	g_iSize = sizeof(g_flCoords)
}

public event_rr()
{
	iRound = 0
}

public event_round_start()
{
	iRound++
}

public event_spawn(id)
{
	new accessId = -1

	if(is_vip(id, accessId))
	{
		if(accessId != -1)
		{
			if(!is_user_alive(id))
			{
				return
			}

			set_user_health(id, VIP_DATA[accessId][VIP_START_HP])
			cs_set_user_armor(id, VIP_DATA[accessId][VIP_START_AP], CS_ARMOR_VESTHELM)

			if(VIP_DATA[accessId][VIP_WEAPON_MENU])
			{
				if(is_user_alive(id))
				{
					if(cs_get_user_team(id) != CS_TEAM_SPECTATOR)
					{
						OpenGunsMenu(id)
					}
					
				}
			}
		}
	}
}

public client_damage(iAttacker, iVictim, iDamage)
{
	new accessId = -1

	if(is_vip(iAttacker, accessId))
	{
		if(accessId != -1)
		{
			if(++g_iPosition[iAttacker] == g_iSize)
			{
				g_iPosition[iAttacker] = 0
			}
			
			if(VIP_DATA[accessId][VIP_BULLET_DAMAGE])
			{
				set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), Float: g_flCoords[g_iPosition[iAttacker]][0], Float: g_flCoords[g_iPosition[iAttacker]][1], 0, 0.1, 2.5, 0.02, 0.02, -1 )
				show_hudmessage(iAttacker, "%i", iDamage)
			}
		}
	}
}

public ev_deathmsg()
{
	new id = read_data(1)
	new accessId = -1

	if(!is_user_alive(id))
	{
		return PLUGIN_HANDLED
	}

	if(is_vip(id, accessId))
	{
		if(accessId != -1)
		{
			new iHP = get_user_health(id)
			new iAP = get_user_armor(id)

			if(iHP < VIP_DATA[accessId][VIP_START_HP] && (iHP + VIP_DATA[accessId][VIP_KILL_HP]) <= VIP_DATA[accessId][VIP_START_HP])
			{
				set_user_health(id, iHP + VIP_DATA[accessId][VIP_KILL_HP])
			}
			else
			{
				set_user_health(id, VIP_DATA[accessId][VIP_START_HP])
			}

			if(iAP < VIP_DATA[accessId][VIP_START_AP] && (iAP + VIP_DATA[accessId][VIP_KILL_AP]) <= VIP_DATA[accessId][VIP_START_AP])
			{
				set_user_armor(id, iAP + VIP_DATA[accessId][VIP_KILL_AP])
			}
			else
			{
				set_user_armor(id, VIP_DATA[accessId][VIP_START_AP])
			}

			client_print(id, print_center, "+%i HP | +%i AP", VIP_DATA[accessId][VIP_KILL_HP], VIP_DATA[accessId][VIP_KILL_AP])
		}
	}
	return PLUGIN_CONTINUE
}


public client_PreThink(id)
{
	new accessId = -1

	if(!is_user_alive(id))
	{
		return PLUGIN_HANDLED
	}

	if(is_vip(id, accessId))
	{
		new nbut = get_user_button(id)
		new obut = get_user_oldbutton(id)

		if(accessId != -1)
		{
			if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
			{
				if(jumpnum[id] < VIP_DATA[accessId][VIP_EXTRA_JUMPS])
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
	}

	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	new accessId = -1

	if(!is_user_alive(id))
	{
		return PLUGIN_CONTINUE
	}
	
	if(is_vip(id, accessId))
	{
		if(accessId != -1)
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
	}
	return PLUGIN_CONTINUE
}

public func_display_vips(id)
{
	new menu = menu_create("\r[CS] \wCHOOSE A VIP TYPE AND SEE WHO'S ONLINE", "menu_handler")
	new buff[248]

	for(new i; i < sizeof VIP_DATA; i++)
	{
		formatex(buff, charsmax(buff), "%s \r(%s)", VIP_DATA[i][VIP_NAME], VIP_DATA[i][VIP_PRICE])
		menu_additem(menu, buff)
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	return PLUGIN_CONTINUE
}

public menu_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	FormatVips(id, item)
	return PLUGIN_CONTINUE
}

public FormatVips(const id, const item)
{
	new menu = menu_create(fmt("[CS] \r%s \wONLINE:", VIP_DATA[item][VIP_NAME]), "menu_handler_doi")
	static name[32]
	new iPlayers[32], idx, iNum, bool: found = false
	get_players(iPlayers, iNum, "ch")

	for(new i; i < iNum; i++)
	{
		idx = iPlayers[i]

		if(get_user_flags(idx) & read_flags(VIP_DATA[item][VIP_FLAGS]))
		{
			found = true
			get_user_name(idx, name, charsmax(name))
			menu_additem(menu, name)
		}
	}

	if(!found)
	{
		menu_additem(menu, "No one with this VIP RANK online..")
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	return PLUGIN_CONTINUE
}

public menu_handler_doi(id, menu, item)
{
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public OpenGunsMenu(id)
{
	if(!is_user_alive(id))
	{
		return PLUGIN_HANDLED
	}

	new buff[70]
	new menu = menu_create("Choose a \yGun\w:", "guns_handler")

	if(iRound < 3)
	{
		for(new i; i < sizeof PISTOLS_DATA; i++)
		{
			formatex(buff, charsmax(buff), "%s", PISTOLS_DATA[i][WeaponName])
			menu_additem(menu, buff)
		}	
	}
	else if(iRound >= 3)
	{
		for(new i; i < sizeof WEAPONS_DATA; i++)
		{
			formatex(buff, charsmax(buff), "%s", WEAPONS_DATA[i][WeaponName])
			menu_additem(menu, buff)
		}
	}
	

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	return PLUGIN_CONTINUE
}

public guns_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	if(get_user_team(id) == 2)
	{
		give_item(id, "item_thighpack")
	}
	give_item(id, "weapon_hegrenade")
	give_item(id, "weapon_flashbang")
	give_item(id, "weapon_flashbang")

	if(iRound < 3)
	{
		drop_weapons(id, 2)
		give_item(id, PISTOLS_DATA[item][WeaponEnt])
		cs_set_user_bpammo(id, PISTOLS_DATA[item][weapon_csw_id], PISTOLS_DATA[item][weapon_bp_ammo])
	}
	else if(iRound >= 3)
	{
		drop_weapons(id, 1)
		give_item(id, WEAPONS_DATA[item][WeaponEnt])
		cs_set_user_bpammo(id, WEAPONS_DATA[item][weapon_csw_id], WEAPONS_DATA[item][weapon_bp_ammo])
		give_item(id, "weapon_deagle")
		cs_set_user_bpammo(id, CSW_DEAGLE, 35)
	}
	return PLUGIN_CONTINUE
}

stock drop_weapons(id, dropwhat)
{
    new weapons[32], num_weapons, index, weaponid
    get_user_weapons(id, weapons, num_weapons)
    
    for (index = 0; index < num_weapons; index++)
    {
        weaponid = weapons[index]
        
        if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) 
        || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
        || (dropwhat == 3) && (((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM) || ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
        {
            new wname[32];
            get_weaponname(weaponid, wname, charsmax(wname))
            

            engclient_cmd(id, "drop", wname)
        }
    }
} 
