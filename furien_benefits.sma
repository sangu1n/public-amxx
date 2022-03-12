#include <amxmodx>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <amxmisc>
#include <fun>
#include <csx>

enum Benefits
{
	NUME_GRAD[15] = 0,
	FLAGS[25],
	HEALTH,
	ARMOR,
	MONEY,
	JUMPS,
	DAMAGE,
	SHP,
	SAP
}

new jumpnum[33] = 0
new bool:dojump[33] = false
new flags = -1

new const Comenzi[] =
{
	"say /beneficii"
}


new const DataType[][Benefits] = 
{
	/*
	 -> la dmg daca vrei sa fie normal lasi doar 1
	 -> poti adauga cate grade vrei tu dar trb sa respecti ordinea 
	*/
	//flaguri, hp,  ap,   bani, jumps, dmg, shp, sap
	{"Founder", "abcde", 50, 50, 111, 2, 3, 100, 100}, // founder
	{"Diamonds", "abcd", 50, 50, 1111, 2, 1, 100, 100}, // diamond
	{"Platinum", "ab", 50, 50, 1111, 2, 1, 100, 100}, // platinum
	{"Gold", "a", 50, 50, 1111, 2, 1, 100, 100} // gold

}

public plugin_init()
{
	register_plugin("furien benefits", "1.0", "kidd0x aka n3v3rm1nd")

	register_event("DeathMsg", "event_deathmsg", "a")
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
	RegisterHam(Ham_Spawn, "player", "event_spawn", true)

	for(new i = 0; i < sizeof Comenzi; i++)
	{
		register_clcmd(Comenzi[i], "beneficii_hndl")
	}
}

public event_deathmsg()
{
	new iKiller = read_data(1)
	new iVictim = read_data(2)
	if(have_access(iKiller, flags))
	{
		if(iKiller == iVictim || !is_user_alive(iKiller))
		{
			return
		}

		if(flags != -1)
		{
			set_user_health(iKiller, min(get_user_health(iKiller) + DataType[flags][HEALTH], 100))
			set_user_armor(iKiller, min(get_user_armor(iKiller) + DataType[flags][ARMOR], 100))
			cs_set_user_money(iKiller, min(cs_get_user_money(iKiller) + DataType[flags][MONEY], 16000))
		}
	}
}

public client_PreThink(id)
{
	if(!is_user_alive(id))
	{
		return PLUGIN_HANDLED
	}
	
	new nbut = get_user_button(id)
	new obut = get_user_oldbutton(id)
	
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(have_access(id, flags))
		{
			if(jumpnum[id] < 3)
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
	if(!is_user_alive(id))
	{
		return PLUGIN_CONTINUE
	}
	
	if(have_access(id, flags))
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
	
	return PLUGIN_CONTINUE
}

public fw_takedamage(iVictim, iInflictor, iAttacker, Float:iDamage, iDamageBits)
{
	if(have_access(iAttacker, flags))
	{
		if(iVictim != iAttacker && is_user_alive(iAttacker))
		{
			SetHamParamFloat(4, iDamage * DataType[iAttacker][DAMAGE])
		}
	}
}

public beneficii_hndl(id)
{
	new menu = menu_create("Beneficii", "arata_meniu")
	static buff[200]

	for(new i = 0; i < sizeof DataType; i++)
	{
		formatex(buff, charsmax(buff), "%s (HP: %d | AP: %d | $%d/kill | DMG: x%d | JUMPS: %d)", DataType[i][NUME_GRAD], DataType[i][HEALTH], DataType[i][ARMOR], DataType[i][MONEY], DataType[i][DAMAGE], DataType[i][JUMPS])
		menu_additem(menu, buff)
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	return PLUGIN_CONTINUE
}

public arata_meniu(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public event_spawn(id)
{
	if(have_access(id, flags))
	{
		set_user_health(id, DataType[id][SHP])
		set_user_armor(id, DataType[id][SAP])
	}
}

stock have_access(id, &flags)
{
	new bool: bFound = false
	for(new i = 0; i < sizeof DataType; i++)
	{
		if(get_user_flags(id) == read_flags(DataType[i][FLAGS]))
		{
			bFound = true
			flags = 1
			break
		}
	}
	return bFound
}
