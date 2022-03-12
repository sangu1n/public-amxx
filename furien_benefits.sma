#include <amxmodx>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <amxmisc>
#include <fun>

enum Benefits
{
	FLAGS[25] = 0,
	HEALTH,
	ARMOR,
	MONEY,
	JUMPS,
	DAMAGE
}

new jumpnum[33] = 0
new bool:dojump[33] = false
new flags = -1


new const DataType[][Benefits] = 
{
	/*
	 -> la dmg daca vrei sa fie normal lasi doar 1
	 -> poti adauga cate grade vrei tu dar trb sa respecti ordinea 
	*/
	//flaguri, hp,  ap,   bani, jumps, dmg
	{"abcde", 50, 50, 111, 2, 3}, // founder
	{"abcd", 50, 50, 1111, 2, 1}, // diamond
	{"ab", 50, 50, 1111, 2, 1}, // platinum
	{"a", 50, 50, 1111, 2, 1} // gold

}

public plugin_init()
{
	register_plugin("furien benefits", "1.0", "kidd0x aka n3v3rm1nd")

	register_event("DeathMsg", "event_deathmsg", "a")
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
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
